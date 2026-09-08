import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/batch.dart';
import '../../models/product.dart';
import '../../services/batch_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';
import '../purchases/purchase_entry/product_selection_dialog.dart';

class BatchMasterScreen extends StatefulWidget {
  final BatchListItem? batchToEdit;

  const BatchMasterScreen({super.key, this.batchToEdit});

  @override
  State<BatchMasterScreen> createState() => _BatchMasterScreenState();
}

class _BatchMasterScreenState extends State<BatchMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final BatchService _batchService = batchService;
  final SessionService _sessionService = sessionService;

  // Form Controllers
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _batchBarcodeController = TextEditingController();
  final TextEditingController _batchEANCodeController = TextEditingController();
  final TextEditingController _batchStockController = TextEditingController(
    text: '0',
  );
  final TextEditingController _batchAvailableStockController =
      TextEditingController(text: '0');
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
  final FocusNode _productFocusNode = FocusNode();
  final FocusNode _batchBarcodeFocusNode = FocusNode();
  final FocusNode _batchEANCodeFocusNode = FocusNode();
  final FocusNode _batchStockFocusNode = FocusNode();
  final FocusNode _batchAvailableStockFocusNode = FocusNode();
  final FocusNode _batchLandingPriceFocusNode = FocusNode();
  final FocusNode _batchPurchasePriceFocusNode = FocusNode();
  final FocusNode _batchMRPFocusNode = FocusNode();
  final FocusNode _batchSellingPriceFocusNode = FocusNode();
  final FocusNode _saveButtonFocusNode = FocusNode();

  int _selectedProductId = 0;
  bool _isActive = true;
  bool _isLoading = false;
  int _currentEmpId = 0;
  int _batchId = 0;

  bool get isEditing => _batchId > 0 || widget.batchToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _productFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _productController.dispose();
    _batchBarcodeController.dispose();
    _batchEANCodeController.dispose();
    _batchStockController.dispose();
    _batchAvailableStockController.dispose();
    _batchLandingPriceController.dispose();
    _batchPurchasePriceController.dispose();
    _batchMRPController.dispose();
    _batchSellingPriceController.dispose();

    _productFocusNode.dispose();
    _batchBarcodeFocusNode.dispose();
    _batchEANCodeFocusNode.dispose();
    _batchStockFocusNode.dispose();
    _batchAvailableStockFocusNode.dispose();
    _batchLandingPriceFocusNode.dispose();
    _batchPurchasePriceFocusNode.dispose();
    _batchMRPFocusNode.dispose();
    _batchSellingPriceFocusNode.dispose();
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
    if (widget.batchToEdit != null) {
      _populateBatchFields(widget.batchToEdit!);
    } else {
      _isActive = true;
    }
  }

  void _populateBatchFields(BatchListItem batch) {
    _batchId = batch.batchId;
    _selectedProductId = batch.batchProductId;
    _productController.text = batch.prodName;

    _batchBarcodeController.text = batch.batchBarcode;
    _batchEANCodeController.text = batch.batchEANCode;
    _batchStockController.text = batch.batchStock.toString();
    _batchAvailableStockController.text = batch.batchAvailableStock.toString();
    _batchLandingPriceController.text = batch.batchLandingPrice.toString();
    _batchPurchasePriceController.text = batch.batchPurchasePrice.toString();
    _batchMRPController.text = batch.batchMRP.toString();
    _batchSellingPriceController.text = batch.batchSellingPrice.toString();
    _isActive = batch.batchIsActive;
  }

  Future<void> _selectProduct() async {
    final selected = await showDialog<ProductListItem>(
      context: context,
      builder: (_) => const ProductSelectionDialog(),
    );
    if (selected != null) {
      setState(() {
        _selectedProductId = selected.prodId;
        _productController.text = selected.prodName;
      });
      _batchBarcodeFocusNode.requestFocus();
    }
  }

  Future<void> _saveBatch({bool saveAndNew = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProductId <= 0) {
      showErrorDialog(context, 'Please select a product.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = BatchUpsertRequest(
        batchId: isEditing ? _batchId : 0,
        batchProductId: _selectedProductId,
        batchBarcode: _batchBarcodeController.text.trim(),
        batchEANCode: _batchEANCodeController.text.trim(),
        batchStock: double.tryParse(_batchStockController.text.trim()) ?? 0.0,
        batchAvailableStock:
            double.tryParse(_batchAvailableStockController.text.trim()) ?? 0.0,
        batchLandingPrice:
            double.tryParse(_batchLandingPriceController.text.trim()) ?? 0.0,
        batchPurchasePrice:
            double.tryParse(_batchPurchasePriceController.text.trim()) ?? 0.0,
        batchMRP: double.tryParse(_batchMRPController.text.trim()) ?? 0.0,
        batchSellingPrice:
            double.tryParse(_batchSellingPriceController.text.trim()) ?? 0.0,
        batchIsActive: _isActive,
        batchBranchId:
            (isEditing &&
                widget.batchToEdit != null &&
                widget.batchToEdit!.batchBranchId > 0)
            ? widget.batchToEdit!.batchBranchId
            : ((sessionService.selectedBranchId != null &&
                      sessionService.selectedBranchId! > 0)
                  ? sessionService.selectedBranchId!
                  : 1),
        batchCompId:
            (isEditing &&
                widget.batchToEdit != null &&
                widget.batchToEdit!.batchCompId > 0)
            ? widget.batchToEdit!.batchCompId
            : ((sessionService.selectedCompId != null &&
                      sessionService.selectedCompId! > 0)
                  ? sessionService.selectedCompId!
                  : 1),
        batchCreatedBy: widget.batchToEdit == null ? _currentEmpId : 0,
        batchModifiedBy: widget.batchToEdit != null ? _currentEmpId : 0,
      );

      final response = await _batchService.insertOrUpdateBatch(request);

      if (!mounted) return;

      if (!response.status) {
        await showErrorDialog(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to save batch.',
        );
        return;
      }

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing
                ? 'Batch updated successfully!'
                : 'Batch created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _clearForm();
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

  void _clearForm() {
    _formKey.currentState?.reset();
    _productController.clear();
    _batchBarcodeController.clear();
    _batchEANCodeController.clear();
    _batchStockController.text = '0';
    _batchAvailableStockController.text = '0';
    _batchLandingPriceController.text = '0';
    _batchPurchasePriceController.text = '0';
    _batchMRPController.text = '0';
    _batchSellingPriceController.text = '0';
    setState(() {
      _selectedProductId = 0;
      _isActive = true;
      _isLoading = false;
    });
    _productFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveBatch(saveAndNew: false);
      },
      onClear: () {
        if (!isEditing) {
          _clearForm();
        }
      },
      child: DirectBackScope(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;
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
                            isEditing ? 'Batch Master - Edit' : 'Batch Master',
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to Batch List',
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

            return Scaffold(
              appBar: AppBar(
                title: Text(isEditing ? 'Batch Master - Edit' : 'Batch Master'),
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
                      Expanded(flex: 2, child: _buildProductField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBarcodeField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEANCodeField()),
                    ],
                  ),
                ] else ...[
                  _buildProductField(),
                  const SizedBox(height: 14),
                  _buildBarcodeField(),
                  const SizedBox(height: 14),
                  _buildEANCodeField(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (!isEditing) ...[
            _buildCardSection(
              context,
              title: 'Stock Details',
              icon: Icons.warehouse_outlined,
              color: Colors.teal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStockField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAvailableStockField()),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          _buildCardSection(
            context,
            title: 'Pricing Details',
            icon: Icons.price_change_outlined,
            color: Colors.orange,
            child: Column(
              children: [
                if (isDesktop) ...[
                  Row(
                    children: [
                      Expanded(child: _buildLandingPriceField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPurchasePriceField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMRPField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSellingPriceField()),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _buildLandingPriceField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPurchasePriceField()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildMRPField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSellingPriceField()),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

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
                          'Batch Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isActive ? 'Active' : 'Inactive',
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
                        : (val) => setState(() => _isActive = val),
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

  Widget _buildCardSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isDark ? color.withOpacity(0.9) : color,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildProductField() {
    return TextFormField(
      controller: _productController,
      focusNode: _productFocusNode,
      readOnly: true,
      onTap: isEditing ? null : _selectProduct,
      decoration: InputDecoration(
        labelText: 'Product *',
        hintText: 'Select Product',
        border: const OutlineInputBorder(),
        suffixIcon: isEditing ? null : const Icon(Icons.arrow_drop_down),
        prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
        filled: isEditing,
        fillColor: isEditing
            ? Theme.of(context).disabledColor.withOpacity(0.1)
            : null,
      ),
      validator: (value) =>
          _selectedProductId <= 0 ? 'Please select a product' : null,
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: _batchBarcodeController,
      focusNode: _batchBarcodeFocusNode,
      decoration: const InputDecoration(
        labelText: 'Barcode',
        hintText: 'Enter Barcode',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.qr_code, size: 18),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_batchEANCodeFocusNode),
    );
  }

  Widget _buildEANCodeField() {
    return TextFormField(
      controller: _batchEANCodeController,
      focusNode: _batchEANCodeFocusNode,
      decoration: const InputDecoration(
        labelText: 'EAN Code',
        hintText: 'Enter EAN Code',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.qr_code_2, size: 18),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        if (!isEditing) {
          FocusScope.of(context).requestFocus(_batchStockFocusNode);
        } else {
          FocusScope.of(context).requestFocus(_batchLandingPriceFocusNode);
        }
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _batchStockController,
      focusNode: _batchStockFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Stock *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory, size: 18),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Enter stock';
        return null;
      },
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_batchAvailableStockFocusNode),
    );
  }

  Widget _buildAvailableStockField() {
    return TextFormField(
      controller: _batchAvailableStockController,
      focusNode: _batchAvailableStockFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Available Stock',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory_outlined, size: 18),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_batchLandingPriceFocusNode),
    );
  }

  Widget _buildLandingPriceField() {
    return TextFormField(
      controller: _batchLandingPriceController,
      focusNode: _batchLandingPriceFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Landing Price',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.currency_rupee, size: 18),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_batchPurchasePriceFocusNode),
    );
  }

  Widget _buildPurchasePriceField() {
    return TextFormField(
      controller: _batchPurchasePriceController,
      focusNode: _batchPurchasePriceFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Purchase Price',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.currency_rupee, size: 18),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_batchMRPFocusNode),
    );
  }

  Widget _buildMRPField() {
    return TextFormField(
      controller: _batchMRPController,
      focusNode: _batchMRPFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'MRP',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.currency_rupee, size: 18),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_batchSellingPriceFocusNode),
    );
  }

  Widget _buildSellingPriceField() {
    return TextFormField(
      controller: _batchSellingPriceController,
      focusNode: _batchSellingPriceFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Selling Price',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.currency_rupee, size: 18),
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        if (!_isLoading) _saveBatch(saveAndNew: false);
      },
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
        child: Row(
          children: [
            if (!isEditing) ...[
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _clearForm,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            const Spacer(),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            if (!isEditing) ...[
              FilledButton.tonalIcon(
                onPressed: _isLoading
                    ? null
                    : () => _saveBatch(saveAndNew: true),
                icon: const Icon(Icons.save_as_rounded, size: 18),
                label: const Text('Save & New'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            FilledButton.icon(
              focusNode: _saveButtonFocusNode,
              onPressed: _isLoading
                  ? null
                  : () => _saveBatch(saveAndNew: false),
              icon: _isLoading
                  ? Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(right: 8),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(isEditing ? 'Update Batch' : 'Save Batch'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
