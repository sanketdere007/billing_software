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
import '../../widgets/save_clear_shortcuts.dart';
import '../../services/unit_service.dart';
import '../../services/gst_service.dart';
import '../../models/unit.dart';
import '../../models/gst.dart';

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
  final TextEditingController _unitValueController = TextEditingController(
    text: '0',
  );

  final TextEditingController _batchBarcodeController = TextEditingController();
  final TextEditingController _batchEANCodeController = TextEditingController();
  final TextEditingController _batchStockController = TextEditingController(
    text: '0',
  );
  final TextEditingController _batchLandingPriceController =
      TextEditingController(text: '0');
  final TextEditingController _batchPurchasePriceController =
      TextEditingController(text: '0');
  final TextEditingController _batchMRPController = TextEditingController(
    text: '0',
  );
  final TextEditingController _batchSellingPriceController =
      TextEditingController(text: '0');

  // Focus Nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _subcategoryFocusNode = FocusNode();
  final FocusNode _brandFocusNode = FocusNode();
  final FocusNode _unitFocusNode = FocusNode();
  final FocusNode _unitValueFocusNode = FocusNode();
  final FocusNode _hsnFocusNode = FocusNode();
  final FocusNode _gstFocusNode = FocusNode();
  final FocusNode _saveButtonFocusNode = FocusNode();

  final FocusNode _batchBarcodeFocusNode = FocusNode();
  final FocusNode _batchEANCodeFocusNode = FocusNode();
  final FocusNode _batchStockFocusNode = FocusNode();
  final FocusNode _batchLandingPriceFocusNode = FocusNode();
  final FocusNode _batchPurchasePriceFocusNode = FocusNode();
  final FocusNode _batchMRPFocusNode = FocusNode();
  final FocusNode _batchSellingPriceFocusNode = FocusNode();

  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedBrandId;
  int? _selectedUnitId;
  String _selectedUnitName = '';
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
    _unitValueController.dispose();

    _nameFocusNode.dispose();
    _codeFocusNode.dispose();
    _categoryFocusNode.dispose();
    _subcategoryFocusNode.dispose();
    _brandFocusNode.dispose();
    _unitFocusNode.dispose();
    _unitValueFocusNode.dispose();
    _hsnFocusNode.dispose();
    _gstFocusNode.dispose();
    _saveButtonFocusNode.dispose();

    _batchBarcodeController.dispose();
    _batchEANCodeController.dispose();
    _batchStockController.dispose();
    _batchLandingPriceController.dispose();
    _batchPurchasePriceController.dispose();
    _batchMRPController.dispose();
    _batchSellingPriceController.dispose();

    _batchBarcodeFocusNode.dispose();
    _batchEANCodeFocusNode.dispose();
    _batchStockFocusNode.dispose();
    _batchLandingPriceFocusNode.dispose();
    _batchPurchasePriceFocusNode.dispose();
    _batchMRPFocusNode.dispose();
    _batchSellingPriceFocusNode.dispose();

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
      _resolveUnitAndGstSelections();
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
        await _resolveUnitAndGstSelections();
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
    _unitValueController.text = _formatDecimal(product.prodUnitValue);

    _batchBarcodeController.text = product.batchBarcode;
    _batchEANCodeController.text = product.batchEANCode;
    _batchStockController.text = product.batchStock.toString();
    _batchLandingPriceController.text = product.batchLandingPrice.toString();
    _batchPurchasePriceController.text = product.batchPurchasePrice.toString();
    _batchMRPController.text = product.batchMRP.toString();
    _batchSellingPriceController.text = product.batchSellingPrice.toString();

    _selectedGstPercent = product.prodGSTPercent;
    _selectedGstId = null;
    _selectedCategoryId = product.prodCategoryId > 0
        ? product.prodCategoryId
        : null;
    _selectedSubcategoryId = product.prodSubCategoryId > 0
        ? product.prodSubCategoryId
        : null;
    _selectedBrandId = product.prodBrandId > 0 ? product.prodBrandId : null;
    _selectedUnitId = product.prodUnitId > 0 ? product.prodUnitId : null;
    _selectedUnitName = product.prodUnitName;
    _isActive = product.prodIsActive;
  }

  String _formatDecimal(double value) {
    if (value.truncateToDouble() == value) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  UnitListItem? _matchUnit(List<UnitListItem> units, String name) {
    final query = name.trim().toLowerCase();
    if (query.isEmpty) return null;
    for (final unit in units) {
      if (unit.unitName.trim().toLowerCase() == query ||
          unit.unitShortName.trim().toLowerCase() == query) {
        return unit;
      }
    }
    return null;
  }

  GstTaxListItem? _matchGst(List<GstTaxListItem> gsts, double percent) {
    for (final gst in gsts) {
      if ((gst.gstTaxPercentage - percent).abs() < 0.0001) return gst;
    }
    return null;
  }

  Future<void> _resolveUnitAndGstSelections() async {
    try {
      final unitsFuture = UnitService().getAllUnits(isActive: true);
      final gstsFuture = GstService().getAllGsts(isActive: true);
      final units = await unitsFuture;
      final gsts = await gstsFuture;
      if (!mounted) return;

      int? unitId = _selectedUnitId;
      if (unitId != null && unitId > 0) {
        final exists = units.any((u) => u.unitId == unitId);
        if (!exists) {
          final byName = _matchUnit(units, _selectedUnitName);
          if (byName != null) unitId = byName.unitId;
        }
      } else {
        final byName = _matchUnit(units, _selectedUnitName);
        if (byName != null) unitId = byName.unitId;
      }

      GstTaxListItem? gstMatch;
      if (_selectedGstId != null && _selectedGstId! > 0) {
        for (final gst in gsts) {
          if (gst.gstTaxId == _selectedGstId) {
            gstMatch = gst;
            break;
          }
        }
      }
      gstMatch ??= _matchGst(gsts, _selectedGstPercent);

      setState(() {
        _selectedUnitId = (unitId != null && unitId > 0) ? unitId : _selectedUnitId;
        if (gstMatch != null) {
          _selectedGstId = gstMatch.gstTaxId;
          _selectedGstPercent = gstMatch.gstTaxPercentage;
        }
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
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
        prodUnitValue: double.tryParse(_unitValueController.text.trim()) ?? 0.0,
        prodIsActive: _isActive,
        prodBranchId:
            (isEditing &&
                widget.productToEdit != null &&
                widget.productToEdit!.prodBranchId > 0)
            ? widget.productToEdit!.prodBranchId
            : ((sessionService.selectedBranchId != null &&
                      sessionService.selectedBranchId! > 0)
                  ? sessionService.selectedBranchId!
                  : 1),
        prodCompId:
            (isEditing &&
                widget.productToEdit != null &&
                widget.productToEdit!.prodCompId > 0)
            ? widget.productToEdit!.prodCompId
            : ((sessionService.selectedCompId != null &&
                      sessionService.selectedCompId! > 0)
                  ? sessionService.selectedCompId!
                  : 1),
        prodCreatedBy: widget.productToEdit == null
            ? _currentEmpId
            : (widget.productToEdit?.prodCreatedBy ?? _currentEmpId),
        prodModifiedBy: widget.productToEdit != null ? _currentEmpId : 0,
        batchBarcode: _batchBarcodeController.text.trim(),
        batchEANCode: _batchEANCodeController.text.trim(),
        batchStock: double.tryParse(_batchStockController.text.trim()) ?? 0.0,
        batchLandingPrice:
            double.tryParse(_batchLandingPriceController.text.trim()) ?? 0.0,
        batchPurchasePrice:
            double.tryParse(_batchPurchasePriceController.text.trim()) ?? 0.0,
        batchMRP: double.tryParse(_batchMRPController.text.trim()) ?? 0.0,
        batchSellingPrice:
            double.tryParse(_batchSellingPriceController.text.trim()) ?? 0.0,
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
          : (isEditing
                ? 'Product updated successfully!'
                : 'Product created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _codeController.clear();
        _hsnController.clear();
        _unitValueController.clear();
        _unitValueController.text = '0';
        _batchBarcodeController.clear();
        _batchEANCodeController.clear();
        _batchStockController.text = '0';
        _batchLandingPriceController.text = '0';
        _batchPurchasePriceController.text = '0';
        _batchMRPController.text = '0';
        _batchSellingPriceController.text = '0';

        setState(() {
          _selectedCategoryId = null;
          _selectedSubcategoryId = null;
          _selectedBrandId = null;
          _selectedUnitId = null;
          _selectedUnitName = '';
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
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveProduct(saveAndNew: false);
      },
      onClear: () {
        if (!isEditing) {
          _formKey.currentState?.reset();
          _nameController.clear();
          _codeController.clear();
          _hsnController.clear();
          _unitValueController.clear();
          _unitValueController.text = '0';
          _batchBarcodeController.clear();
          _batchEANCodeController.clear();
          _batchStockController.text = '0';
          _batchLandingPriceController.text = '0';
          _batchPurchasePriceController.text = '0';
          _batchMRPController.text = '0';
          _batchSellingPriceController.text = '0';
          setState(() {
            _selectedCategoryId = null;
            _selectedSubcategoryId = null;
            _selectedBrandId = null;
            _selectedUnitId = null;
            _selectedUnitName = '';
            _selectedGstId = null;
            _selectedGstPercent = 0.0;
            _isActive = true;
          });
          _nameFocusNode.requestFocus();
        }
      },
      child: DirectBackScope(
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
                          title: Text(
                            isEditing ? 'Edit Product' : 'Add New Product',
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to Product List',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        body: Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.12),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 24,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 860,
                                      ),
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
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildUnitValueField()),
                      const SizedBox(width: 16),
                      const Spacer(),
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
                  const SizedBox(height: 14),
                  _buildUnitValueField(),
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

          // Section 4: Batch & Pricing Details
          _buildCardSection(
            context,
            title: 'Batch & Pricing Details',
            icon: Icons.price_change_outlined,
            color: Colors.orange,
            child: Column(
              children: [
                if (isDesktop) ...[
                  Row(
                    children: [
                      Expanded(child: _buildBatchBarcodeField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBatchEANCodeField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBatchStockField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildBatchLandingPriceField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBatchPurchasePriceField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBatchMRPField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBatchSellingPriceField()),
                    ],
                  ),
                ] else ...[
                  _buildBatchBarcodeField(),
                  const SizedBox(height: 14),
                  _buildBatchEANCodeField(),
                  const SizedBox(height: 14),
                  _buildBatchStockField(),
                  const SizedBox(height: 14),
                  _buildBatchLandingPriceField(),
                  const SizedBox(height: 14),
                  _buildBatchPurchasePriceField(),
                  const SizedBox(height: 14),
                  _buildBatchMRPField(),
                  const SizedBox(height: 14),
                  _buildBatchSellingPriceField(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 5: Status Switch
          Card(
            elevation: isDesktop ? 2 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isActive ? Colors.green : Colors.grey)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isActive
                          ? Icons.check_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: _isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isActive
                              ? 'Active - Available for transactions'
                              : 'Inactive - Hidden from billing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
      inputFormatters: const [CapitalizeWordsInputFormatter()],
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
      selectedUnitName: _selectedUnitName.isNotEmpty ? _selectedUnitName : null,
      focusNode: _unitFocusNode,
      nextFocusNode: _unitValueFocusNode,
      labelText: 'Unit',
      hintText: 'Select Unit',
      onChanged: (val) {
        setState(() {
          _selectedUnitId = val?.unitId;
          _selectedUnitName = val?.unitName ?? '';
        });
      },
    );
  }

  Widget _buildUnitValueField() {
    return TextFormField(
      controller: _unitValueController,
      focusNode: _unitValueFocusNode,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
      ],
      onFieldSubmitted: (_) => _hsnFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Unit Value',
        hintText: 'Enter Unit Value',
        prefixIcon: const Icon(Icons.straighten_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter unit value';
        }
        if (double.tryParse(val) == null) {
          return 'Please enter valid number';
        }
        return null;
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
      selectedGstPercent: isEditing ? _selectedGstPercent : null,
      focusNode: _gstFocusNode,
      onSelectionComplete: () => _batchBarcodeFocusNode.requestFocus(),
      onChanged: (val) {
        setState(() {
          _selectedGstId = val?.gstTaxId;
          _selectedGstPercent = val?.gstTaxPercentage ?? 0.0;
        });
      },
    );
  }

  Widget _buildBatchBarcodeField() {
    return TextFormField(
      controller: _batchBarcodeController,
      focusNode: _batchBarcodeFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _batchEANCodeFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Barcode',
        hintText: 'Enter barcode',
        prefixIcon: const Icon(Icons.qr_code, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBatchEANCodeField() {
    return TextFormField(
      controller: _batchEANCodeController,
      focusNode: _batchEANCodeFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _batchStockFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'EAN Code',
        hintText: 'Enter EAN code',
        prefixIcon: const Icon(Icons.qr_code_scanner, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBatchStockField() {
    return TextFormField(
      controller: _batchStockController,
      focusNode: _batchStockFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _batchLandingPriceFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Stock *',
        hintText: '0',
        prefixIcon: const Icon(Icons.inventory_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (isEditing) return null;
        if (val == null || val.trim().isEmpty) {
          return 'Please enter stock';
        }
        final numVal = double.tryParse(val);
        if (numVal == null) {
          return 'Please enter valid number';
        }
        if (numVal <= 0) {
          return 'Must be > 0';
        }
        return null;
      },
    );
  }

  Widget _buildBatchLandingPriceField() {
    return TextFormField(
      controller: _batchLandingPriceController,
      focusNode: _batchLandingPriceFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _batchPurchasePriceFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Landing Price *',
        hintText: '0',
        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (isEditing) return null;
        if (val == null || val.trim().isEmpty) {
          return 'Please enter landing price';
        }
        final numVal = double.tryParse(val);
        if (numVal == null) {
          return 'Please enter valid number';
        }
        if (numVal <= 0) {
          return 'Must be > 0';
        }
        return null;
      },
    );
  }

  Widget _buildBatchPurchasePriceField() {
    return TextFormField(
      controller: _batchPurchasePriceController,
      focusNode: _batchPurchasePriceFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _batchMRPFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Purchase Price *',
        hintText: '0',
        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (isEditing) return null;
        if (val == null || val.trim().isEmpty) {
          return 'Please enter purchase price';
        }
        final numVal = double.tryParse(val);
        if (numVal == null) {
          return 'Please enter valid number';
        }
        if (numVal <= 0) {
          return 'Must be > 0';
        }
        return null;
      },
    );
  }

  Widget _buildBatchMRPField() {
    return TextFormField(
      controller: _batchMRPController,
      focusNode: _batchMRPFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _batchSellingPriceFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'MRP *',
        hintText: '0',
        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (isEditing) return null;
        if (val == null || val.trim().isEmpty) {
          return 'Please enter MRP';
        }
        final numVal = double.tryParse(val);
        if (numVal == null) {
          return 'Please enter valid number';
        }
        if (numVal <= 0) {
          return 'Must be > 0';
        }
        return null;
      },
    );
  }

  Widget _buildBatchSellingPriceField() {
    return TextFormField(
      controller: _batchSellingPriceController,
      focusNode: _batchSellingPriceFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveButtonFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Selling Price *',
        hintText: '0',
        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (isEditing) return null;
        if (val == null || val.trim().isEmpty) {
          return 'Please enter selling price';
        }
        final numVal = double.tryParse(val);
        if (numVal == null) {
          return 'Please enter valid number';
        }
        if (numVal <= 0) {
          return 'Must be > 0';
        }
        return null;
      },
    );
  }
}
