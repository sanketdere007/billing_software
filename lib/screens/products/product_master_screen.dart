import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/session_service.dart';
import '../../utils/text_formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/subcategory_dropdown.dart';
import '../../widgets/brand_dropdown.dart';
import '../../widgets/unit_dropdown.dart';
import '../../widgets/gst_dropdown.dart';

class ProductMasterScreen extends StatefulWidget {
  final ProductListItem? productToEdit;
  final int? productId;

  const ProductMasterScreen({super.key, this.productToEdit, this.productId});

  @override
  State<ProductMasterScreen> createState() => _ProductMasterScreenState();
}

class _ProductMasterScreenState extends State<ProductMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = productService;
  final SessionService _sessionService = sessionService;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();

  // Focus Nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _subcategoryFocusNode = FocusNode();
  final FocusNode _brandFocusNode = FocusNode();
  final FocusNode _unitFocusNode = FocusNode();
  final FocusNode _hsnFocusNode = FocusNode();
  final FocusNode _gstFocusNode = FocusNode();
  final FocusNode _saveButtonFocusNode = FocusNode();

  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedBrandId;
  int? _selectedUnitId;
  int? _selectedGstId;
  double _selectedGstPercent = 0.0;

  bool _isActive = true;
  bool _isLoading = false;
  bool _isFetchingDetails = false;
  int _currentEmpId = 0;
  int _prodId = 0;

  bool get isEditing => _prodId > 0 || widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _hsnController.dispose();

    _nameFocusNode.dispose();
    _codeFocusNode.dispose();
    _categoryFocusNode.dispose();
    _subcategoryFocusNode.dispose();
    _brandFocusNode.dispose();
    _unitFocusNode.dispose();
    _hsnFocusNode.dispose();
    _gstFocusNode.dispose();
    _saveButtonFocusNode.dispose();

    super.dispose();
  }

  Future<void> _initUserData() async {
    try {
      final user = await _sessionService.getUserData();
      if (user?.empId != null) {
        _currentEmpId = user!.empId!;
      }
    } catch (_) {}
  }

  void _initFormData() {
    if (widget.productToEdit != null) {
      _populateProductFields(widget.productToEdit!);
    } else if (widget.productId != null && widget.productId! > 0) {
      _fetchProductDetails(widget.productId!);
    } else {
      _isActive = true;
    }
  }

  Future<void> _fetchProductDetails(int prodId) async {
    setState(() {
      _isFetchingDetails = true;
    });

    try {
      final prod = _productService.getProductByIdFromCache(prodId);
      if (prod != null && mounted) {
        _populateProductFields(prod);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Failed to load product details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingDetails = false;
        });
      }
    }
  }

  void _populateProductFields(ProductListItem product) {
    _prodId = product.prodId;
    _nameController.text = product.prodName;
    _codeController.text = product.prodCode;
    _hsnController.text = product.prodHSNCode;

    _selectedGstPercent = product.prodGSTPercent;
    _selectedCategoryId = product.prodCategoryId > 0 ? product.prodCategoryId : null;
    _selectedSubcategoryId = product.prodSubCategoryId > 0 ? product.prodSubCategoryId : null;
    _selectedBrandId = product.prodBrandId > 0 ? product.prodBrandId : null;
    _selectedUnitId = product.prodUnitId > 0 ? product.prodUnitId : null;
    _isActive = product.prodIsActive;
  }

  Future<void> _saveProduct({bool saveAndNew = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = ProductUpsertRequest(
        prodId: isEditing ? _prodId : 0,
        prodName: _nameController.text.trim(),
        prodCode: _codeController.text.trim(),
        prodCategoryId: _selectedCategoryId ?? 0,
        prodSubCategoryId: _selectedSubcategoryId ?? 0,
        prodBrandId: _selectedBrandId ?? 0,
        prodUnitId: _selectedUnitId ?? 0,
        prodHSNCode: _hsnController.text.trim(),
        prodGSTPercent: _selectedGstPercent,
        prodIsActive: _isActive,
        prodBranchId: (isEditing && widget.productToEdit != null && widget.productToEdit!.prodBranchId > 0)
            ? widget.productToEdit!.prodBranchId
            : ((sessionService.selectedBranchId != null && sessionService.selectedBranchId! > 0) ? sessionService.selectedBranchId! : 1),
        prodCompId: (isEditing && widget.productToEdit != null && widget.productToEdit!.prodCompId > 0)
            ? widget.productToEdit!.prodCompId
            : ((sessionService.selectedCompId != null && sessionService.selectedCompId! > 0) ? sessionService.selectedCompId! : 1),
        prodCreatedBy: widget.productToEdit == null ? _currentEmpId : (widget.productToEdit?.prodCreatedBy ?? _currentEmpId),
        prodModifiedBy: widget.productToEdit != null ? _currentEmpId : 0,
      );

      final response = await _productService.insertOrUpdateProduct(request);

      if (!mounted) return;

      if (!response.status) {
        if (!mounted) return;
        await showErrorDialog(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to save product.',
        );
        return;
      }

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing ? 'Product updated successfully!' : 'Product created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _codeController.clear();
        _hsnController.clear();

        setState(() {
          _selectedCategoryId = null;
          _selectedSubcategoryId = null;
          _selectedBrandId = null;
          _selectedUnitId = null;
          _selectedGstId = null;
          _selectedGstPercent = 0.0;
          _isActive = true;
          _isLoading = false;
        });
        _nameFocusNode.requestFocus();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        e.toString().replaceAll('ApiException: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (_isFetchingDetails) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading product details...'),
                  ],
                ),
              ),
            );
          }

          final formContent = _buildFormCard(context, isDesktop);

          if (isDesktop) {
            return Scaffold(
              body: Row(
                children: [
                  const SizedBox(
                    width: 250,
                    child: AppDrawer(isPermanent: true),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Scaffold(
                      appBar: AppBar(
                        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Product List',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.12),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 860),
                                    child: formContent,
                                  ),
                                ),
                              ),
                            ),
                            _buildStickyActionBar(context, isDesktop),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Mobile / Tablet View
          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: formContent,
                  ),
                ),
                _buildStickyActionBar(context, isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Basic Information
          _buildCardSection(
            context,
            title: 'Basic Information',
            icon: Icons.inventory_2_outlined,
            color: Colors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildNameField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCodeField()),
                    ],
                  ),
                ] else ...[
                  _buildNameField(),
                  const SizedBox(height: 14),
                  _buildCodeField(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 2: Classification Details
          _buildCardSection(
            context,
            title: 'Classification Details',
            icon: Icons.category_outlined,
            color: Colors.teal,
            child: Column(
              children: [
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCategoryDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSubcategoryDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildBrandDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildUnitDropdown()),
                    ],
                  ),
                ] else ...[
                  _buildCategoryDropdown(),
                  const SizedBox(height: 14),
                  _buildSubcategoryDropdown(),
                  const SizedBox(height: 14),
                  _buildBrandDropdown(),
                  const SizedBox(height: 14),
                  _buildUnitDropdown(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 3: Tax Details
          _buildCardSection(
            context,
            title: 'Tax Details',
            icon: Icons.receipt_long_outlined,
            color: Colors.indigo,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildHsnField()),
                const SizedBox(width: 16),
                Expanded(child: _buildGstField()),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 4: Status Switch
          Card(
            elevation: isDesktop ? 2 : 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isActive ? Colors.green : Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isActive ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                      color: _isActive ? Colors.green.shade700 : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Status',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _isActive ? 'Active - Available for transactions' : 'Inactive - Hidden from billing',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: Colors.green,
                    onChanged: _isLoading
                        ? null
                        : (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStickyActionBar(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withOpacity(0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 12,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 860 : double.infinity,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _saveProduct(saveAndNew: true),
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text('Save & Add Another'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      focusNode: _saveButtonFocusNode,
                      onPressed: _isLoading
                          ? null
                          : () => _saveProduct(saveAndNew: false),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isEditing
                                  ? Icons.save_rounded
                                  : Icons.check_circle_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isLoading
                            ? 'Saving...'
                            : (isEditing ? 'Update Product' : 'Save Product'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required MaterialColor color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (isDark ? color.shade900 : color.shade50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isDark ? color.shade700 : color.shade200),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? color.shade200 : color.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      inputFormatters: const [
        CapitalizeWordsInputFormatter(),
      ],
      onFieldSubmitted: (_) => _codeFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Product Name *',
        hintText: 'Enter product name',
        prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter product name';
        }
        if (val.trim().length < 2) {
          return 'Product name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      focusNode: _codeFocusNode,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      onFieldSubmitted: (_) => _categoryFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Product Code/SKU',
        hintText: 'Enter internal code',
        prefixIcon: const Icon(Icons.qr_code_2_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return CategoryDropdown(
      selectedCategoryId: _selectedCategoryId,
      focusNode: _categoryFocusNode,
      nextFocusNode: _subcategoryFocusNode,
      labelText: 'Category',
      hintText: 'Select Category',
      onChanged: (val) {
        setState(() {
          _selectedCategoryId = val?.catId;
        });
      },
    );
  }

  Widget _buildSubcategoryDropdown() {
    return SubcategoryDropdown(
      selectedSubcategoryId: _selectedSubcategoryId,
      focusNode: _subcategoryFocusNode,
      nextFocusNode: _brandFocusNode,
      labelText: 'Subcategory',
      hintText: 'Select Subcategory',
      onChanged: (val) {
        setState(() {
          _selectedSubcategoryId = val?.subCatId;
        });
      },
    );
  }

  Widget _buildBrandDropdown() {
    return BrandDropdown(
      selectedBrandId: _selectedBrandId,
      focusNode: _brandFocusNode,
      nextFocusNode: _unitFocusNode,
      labelText: 'Brand',
      hintText: 'Select Brand',
      onChanged: (val) {
        setState(() {
          _selectedBrandId = val?.brandId;
        });
      },
    );
  }

  Widget _buildUnitDropdown() {
    return UnitDropdown(
      selectedUnitId: _selectedUnitId,
      focusNode: _unitFocusNode,
      nextFocusNode: _hsnFocusNode,
      labelText: 'Unit',
      hintText: 'Select Unit',
      onChanged: (val) {
        setState(() {
          _selectedUnitId = val?.unitId;
        });
      },
    );
  }

  Widget _buildHsnField() {
    return TextFormField(
      controller: _hsnController,
      focusNode: _hsnFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _gstFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'HSN/SAC Code',
        hintText: 'Enter HSN Code',
        prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildGstField() {
    return GstDropdown(
      selectedGstId: _selectedGstId,
      focusNode: _gstFocusNode,
      onSelectionComplete: () => _saveButtonFocusNode.requestFocus(),
      onChanged: (val) {
        setState(() {
          _selectedGstId = val?.gstTaxId;
          _selectedGstPercent = val?.gstTaxPercentage ?? 0.0;
        });
      },
    );
  }
}
