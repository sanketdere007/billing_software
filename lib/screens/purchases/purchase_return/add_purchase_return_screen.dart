import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase_return.dart';
import '../../../services/purchase_return_service.dart';
import '../../../services/supplier_service.dart';
import '../../../services/product_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_message_dialog.dart';
import 'purchase_return_list_screen.dart';

class AddPurchaseReturnScreen extends StatefulWidget {
  const AddPurchaseReturnScreen({super.key});

  @override
  State<AddPurchaseReturnScreen> createState() => _AddPurchaseReturnScreenState();
}

class _AddPurchaseReturnScreenState extends State<AddPurchaseReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _returnNoController = TextEditingController(text: 'PRET-AUTO-001');
  final _invoiceNoController = TextEditingController(text: 'PINV-2023-001');
  DateTime _selectedDate = DateTime.now();
  int? _selectedSupplier;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<Map<String, dynamic>> _products = [];
  double _returnAmount = 0.0;
  double _taxAdjustment = 0.0;
  double _grandRefund = 0.0;
  String _selectedRefundMode = 'Bank';

  final SupplierService _supplierService = SupplierService();
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _supplierService.getAllSuppliers();
    _productService.getAllProducts();
  }

  @override
  void dispose() {
    _returnNoController.dispose();
    _invoiceNoController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double amt = 0;
    for (var p in _products) {
      amt += (p['quantity'] as double) * (p['price'] as double);
    }
    setState(() {
      _returnAmount = amt;
      _grandRefund = _returnAmount + _taxAdjustment;
    });
  }

  Future<void> _addProductRow() async {
    final availableProducts = _productService.products;
    if (availableProducts.isEmpty) {
      await showWarningDialog(context, 'No products available');
      return;
    }
    final first = availableProducts.first;
    setState(() {
      _products.add({
        'productId': first.id,
        'productName': first.name,
        'quantity': 1.0,
        'unit': 'PCS',
        'price': 100.0,
        'reason': 'Damaged / Excess stock',
      });
      _calculateTotals();
    });
  }

  void _removeProductRow(int index) {
    setState(() {
      _products.removeAt(index);
      _calculateTotals();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _navigateToReturnList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PurchaseReturnListScreen()),
    );
  }

  Future<void> _saveReturn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      await showWarningDialog(context, 'Please select a supplier');
      return;
    }
    if (_products.isEmpty) {
      await showWarningDialog(context, 'Please add at least one item to return');
      return;
    }

    final supplier = _supplierService.suppliers.firstWhere(
      (s) => s.suppId == _selectedSupplier,
      orElse: () => _supplierService.suppliers.first,
    );

    double totalQty = 0;
    for (var p in _products) {
      totalQty += p['quantity'] as double;
    }

    final returnObj = PurchaseReturn(
      id: 'PR-${DateTime.now().millisecondsSinceEpoch}',
      returnNo: _returnNoController.text.trim(),
      returnDate: _selectedDate,
      invoiceNo: _invoiceNoController.text.trim(),
      supplierId: supplier.suppId.toString(),
      supplierName: supplier.suppName,
      products: _products.map((p) {
        final qty = p['quantity'] as double;
        final price = p['price'] as double;
        return PurchaseReturnProduct(
          id: 'PRP-${DateTime.now().millisecondsSinceEpoch}',
          productId: p['productId'] as String,
          productName: p['productName'] as String,
          returnQuantity: qty,
          unit: p['unit'] as String,
          price: price,
          refundAmount: qty * price,
          returnReason: p['reason'] as String?,
        );
      }).toList(),
      totalReturnQuantity: totalQty,
      returnAmount: _returnAmount,
      taxAdjustment: _taxAdjustment,
      grandRefund: _grandRefund,
      refundMode: _selectedRefundMode,
    );

    await PurchaseReturnService().addReturn(returnObj);
    if (mounted) {
      await showSuccessDialog(context, 'Purchase Return recorded successfully!');
      if (!mounted) return;
      Navigator.of(context).pop();
    }
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
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 180,
                      child: TextFormField(
                        controller: _returnNoController,
                        decoration: const InputDecoration(
                          labelText: 'Return No',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 180,
                      child: TextFormField(
                        controller: _invoiceNoController,
                        decoration: const InputDecoration(
                          labelText: 'Original Inv No',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_dateFormat.format(_selectedDate)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 260,
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSupplier,
                        hint: const Text('Select Supplier'),
                        items: _supplierService.suppliers.map((s) {
                          return DropdownMenuItem(value: s.suppId, child: Text(s.suppName));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSupplier = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Returned Items (${_products.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addProductRow,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Return Item'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _products.isEmpty
                            ? const Center(child: Text('No items added for return.'))
                            : ListView.builder(
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  final p = _products[index];
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          p['productName'],
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Qty: ${p['quantity']} ${p['unit']}',
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '₹${(p['price'] as double).toStringAsFixed(2)}',
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '₹${((p['quantity'] as double) * (p['price'] as double)).toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeProductRow(index),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Refund: ₹${_grandRefund.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveReturn,
                      icon: const Icon(Icons.assignment_return),
                      label: const Text('Save Purchase Return'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  title: const Text('Purchase Return (Ctrl + F7)'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.list),
                      tooltip: 'View All Returns',
                      onPressed: _navigateToReturnList,
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
          title: const Text('Purchase Return'),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: _navigateToReturnList,
            ),
          ],
        ),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }
}
