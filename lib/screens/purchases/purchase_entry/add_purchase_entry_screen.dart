import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/product.dart';
import '../../../models/purchase_entry.dart';
import '../../../services/purchase_entry_service.dart';
import '../../../services/supplier_service.dart';
import '../../../services/product_service.dart';
import '../../../services/session_service.dart';
import '../../../widgets/app_drawer.dart';
import 'purchase_entry_list_screen.dart';
import 'product_selection_dialog.dart';

class AddPurchaseEntryScreen extends StatefulWidget {
  const AddPurchaseEntryScreen({super.key});

  @override
  State<AddPurchaseEntryScreen> createState() => _AddPurchaseEntryScreenState();
}

class _AddPurchaseEntryScreenState extends State<AddPurchaseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();
  final _billDiscountController = TextEditingController(text: '0');
  DateTime _selectedDate = DateTime.now();
  int? _selectedSupplier;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final List<Map<String, dynamic>> _products = [];

  double _totalQuantity = 0.0;
  double _grossTotal = 0.0;
  double _totalProductDiscount = 0.0;
  double _totalGST = 0.0;
  double _billDiscount = 0.0;
  double _finalPayable = 0.0;

  bool _isLoading = false;

  final SupplierService _supplierService = SupplierService();
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _supplierService.getAllSuppliers();
    _productService.getAllProducts();
    _billDiscountController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _billDiscountController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double totalQty = 0;
    double grossTotal = 0;
    double totalProdDisc = 0;
    double totalGST = 0;
    double subTotal = 0;

    for (var p in _products) {
      double qty = p['qty'] ?? 0.0;
      double rate = p['rate'] ?? 0.0;
      double disc = p['discAmt'] ?? 0.0;
      double gstPct = p['gstPct'] ?? 0.0;

      double gross = qty * rate;
      double discounted = gross - disc;
      if (discounted < 0) discounted = 0;

      double gstAmt = discounted * (gstPct / 100);
      double net = discounted + gstAmt;

      p['gross'] = gross;
      p['discounted'] = discounted;
      p['gstAmt'] = gstAmt;
      p['net'] = net;

      totalQty += qty;
      grossTotal += gross;
      totalProdDisc += disc;
      totalGST += gstAmt;
      subTotal += net;
    }

    double bDisc = double.tryParse(_billDiscountController.text) ?? 0.0;
    double finalPay = subTotal - bDisc;
    if (finalPay < 0) finalPay = 0;

    setState(() {
      _totalQuantity = totalQty;
      _grossTotal = grossTotal;
      _totalProductDiscount = totalProdDisc;
      _totalGST = totalGST;
      _billDiscount = bDisc;
      _finalPayable = finalPay;
    });
  }

  Future<void> _addProduct() async {
    final selectedProduct = await showDialog<ProductListItem>(
      context: context,
      builder: (context) => const ProductSelectionDialog(),
    );

    if (selectedProduct != null) {
      final exists = _products.any(
        (p) => p['product'].prodId == selectedProduct.prodId,
      );
      if (exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product already added!')));
        return;
      }

      setState(() {
        _products.insert(0, {
          'product': selectedProduct,
          'qty': 1.0,
          'rate': 0.0,
          'discAmt': 0.0,
          'gstPct': selectedProduct.prodGSTPercent,
          'gross': 0.0,
          'discounted': 0.0,
          'gstAmt': 0.0,
          'net': 0.0,
        });
      });
      _calculateTotals();
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
    _calculateTotals();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await sessionService.getUserData();
      int compId = sessionService.selectedCompId ?? 1;
      int branchId = sessionService.selectedBranchId ?? 1;
      int empId = user?.empId ?? 1;

      final masterData = PurchaseEntryMasterData(
        compId: compId,
        branchId: branchId,
        supplierId: _selectedSupplier!,
        invoiceNo: _invoiceNoController.text.trim(),
        invoiceDate: _selectedDate.toIso8601String(),
        subTotal: _grossTotal,
        discountAmount: _totalProductDiscount + _billDiscount,
        gstAmount: _totalGST,
        otherCharges: 0,
        netAmount: _finalPayable,
        paidAmount: 0,
        balanceAmount: _finalPayable,
        status: 'Completed',
        remark: '',
        createdBy: empId,
        modifiedBy: empId,
      );

      final detailData = _products.map((p) {
        final ProductListItem prod = p['product'];
        return PurchaseEntryDetailData(
          compId: compId,
          branchId: branchId,
          productId: prod.prodId,
          barcode: '',
          eanCode: '',
          qty: p['qty'],
          landingPrice: p['rate'],
          purchasePrice: p['rate'],
          mrp: p['rate'],
          sellingPrice: p['rate'],
          discountPercent: 0,
          discountAmount: p['discAmt'],
          gstPercent: p['gstPct'],
          gstAmount: p['gstAmt'],
          totalAmount: p['net'],
        );
      }).toList();

      final request = PurchaseEntryUpsertRequest(
        masterData: masterData,
        detailData: detailData,
      );

      final response = await PurchaseEntryService().insertOrUpdatePurchaseEntry(
        request,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _invoiceNoController.clear();
      _billDiscountController.text = '0';
      _selectedSupplier = null;
      _products.clear();
      _selectedDate = DateTime.now();
      _calculateTotals();
    });
  }

  Widget _buildProductTable() {
    final theme = Theme.of(context);

    // Fixed widths for columns to ensure perfect alignment
    const double colProductName = 220;
    const double colQty = 100;
    const double colRate = 120;
    const double colGross = 100;
    const double colDiscount = 100;
    const double colGstPct = 100;
    const double colGstAmt = 100;
    const double colNet = 120;
    const double colAction = 70;
    const double totalWidth =
        colProductName +
        colQty +
        colRate +
        colGross +
        colDiscount +
        colGstPct +
        colGstAmt +
        colNet +
        colAction;

    Widget buildHeaderCell(
      String text,
      double width, {
      bool isNumeric = false,
      bool isLast = false,
    }) {
      return Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
        ),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Widget buildDataCell(
      Widget child,
      double width, {
      bool isNumeric = false,
      EdgeInsets? padding,
      bool isLast = false,
    }) {
      return Container(
        width: width,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
        ),
        child: child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tableWidth = constraints.maxWidth > totalWidth
            ? constraints.maxWidth
            : totalWidth;
        final double extraWidth = constraints.maxWidth > totalWidth
            ? constraints.maxWidth - totalWidth
            : 0.0;
        final double effectiveProductNameWidth = colProductName + extraWidth;

        return Container(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildHeaderCell(
                            'Product Name',
                            effectiveProductNameWidth,
                          ),
                          buildHeaderCell('Qty', colQty, isNumeric: true),
                          buildHeaderCell('Rate', colRate, isNumeric: true),
                          buildHeaderCell(
                            'Gross Amt',
                            colGross,
                            isNumeric: true,
                          ),
                          buildHeaderCell(
                            'Discount',
                            colDiscount,
                            isNumeric: true,
                          ),
                          buildHeaderCell('GST %', colGstPct, isNumeric: true),
                          buildHeaderCell(
                            'GST Amt',
                            colGstAmt,
                            isNumeric: true,
                          ),
                          buildHeaderCell('Net Amt', colNet, isNumeric: true),
                          buildHeaderCell(
                            'Action',
                            colAction,
                            isNumeric: true,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Scrollable Data Rows
                  Expanded(
                    child: _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart_checkout,
                                  size: 48,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No products added yet.',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Click "Add Product" to start building your invoice.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _products.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.5),
                            ),
                            itemBuilder: (context, index) {
                              final p = _products[index];
                              final ProductListItem prod = p['product'];
                              final isEven = index.isEven;

                              return Container(
                                color: isEven
                                    ? theme.colorScheme.surfaceVariant
                                          .withOpacity(0.1)
                                    : null,
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      buildDataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              prod.prodName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              prod.prodCode,
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        effectiveProductNameWidth,
                                      ),
                                      buildDataCell(
                                        TextFormField(
                                          initialValue: p['qty'].toString(),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.right,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d*'),
                                            ),
                                          ],
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor:
                                                theme.colorScheme.surface,
                                          ),
                                          onChanged: (val) {
                                            setState(
                                              () => p['qty'] =
                                                  double.tryParse(val) ?? 0.0,
                                            );
                                            _calculateTotals();
                                          },
                                        ),
                                        colQty,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      buildDataCell(
                                        TextFormField(
                                          initialValue: p['rate'].toString(),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.right,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d*'),
                                            ),
                                          ],
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor:
                                                theme.colorScheme.surface,
                                          ),
                                          onChanged: (val) {
                                            setState(
                                              () => p['rate'] =
                                                  double.tryParse(val) ?? 0.0,
                                            );
                                            _calculateTotals();
                                          },
                                        ),
                                        colRate,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      buildDataCell(
                                        Text(
                                          (p['gross'] as double)
                                              .toStringAsFixed(2),
                                        ),
                                        colGross,
                                        isNumeric: true,
                                      ),
                                      buildDataCell(
                                        TextFormField(
                                          initialValue: p['discAmt'].toString(),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.right,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d*'),
                                            ),
                                          ],
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor:
                                                theme.colorScheme.surface,
                                          ),
                                          onChanged: (val) {
                                            setState(
                                              () => p['discAmt'] =
                                                  double.tryParse(val) ?? 0.0,
                                            );
                                            _calculateTotals();
                                          },
                                        ),
                                        colDiscount,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      buildDataCell(
                                        Text(
                                          (p['gstPct'] as double)
                                              .toStringAsFixed(2),
                                        ),
                                        colGstPct,
                                        isNumeric: true,
                                      ),
                                      buildDataCell(
                                        Text(
                                          (p['gstAmt'] as double)
                                              .toStringAsFixed(2),
                                        ),
                                        colGstAmt,
                                        isNumeric: true,
                                      ),
                                      buildDataCell(
                                        Text(
                                          (p['net'] as double).toStringAsFixed(
                                            2,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        colNet,
                                        isNumeric: true,
                                      ),
                                      buildDataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 22,
                                          ),
                                          tooltip: 'Remove',
                                          splashRadius: 24,
                                          onPressed: () =>
                                              _removeProduct(index),
                                        ),
                                        colAction,
                                        isNumeric: true,
                                        isLast: true,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;
    final bool isMobile = screenWidth < 600;

    Widget content = Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: TextFormField(
                        controller: _invoiceNoController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice / Bill Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 220,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Invoice Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_dateFormat.format(_selectedDate)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 280,
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSupplier,
                        hint: const Text('Select Supplier'),
                        items: _supplierService.suppliers.map((s) {
                          return DropdownMenuItem(
                            value: s.suppId,
                            child: Text(s.suppName),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSupplier = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items (${_products.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildProductTable()),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Quantity:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(_totalQuantity.toStringAsFixed(2)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gross Total:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('₹${_grossTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total GST:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('₹${_totalGST.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bill Discount:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _billDiscountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Final Payable Amount:',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${_finalPayable.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveEntry,
                        icon: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isLoading ? 'Saving...' : 'Save Purchase Entry',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Purchase Entry / Invoice (F7)'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.list),
                      tooltip: 'View All Invoices',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const PurchaseEntryListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                body: content,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Purchase Entry'),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PurchaseEntryListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }
}
