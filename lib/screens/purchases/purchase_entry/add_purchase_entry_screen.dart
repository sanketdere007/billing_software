import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase_entry.dart';
import '../../../services/purchase_entry_service.dart';
import '../../../services/supplier_service.dart';
import '../../../services/product_service.dart';
import '../../../widgets/app_drawer.dart';
import 'purchase_entry_list_screen.dart';

class AddPurchaseEntryScreen extends StatefulWidget {
  const AddPurchaseEntryScreen({super.key});

  @override
  State<AddPurchaseEntryScreen> createState() => _AddPurchaseEntryScreenState();
}

class _AddPurchaseEntryScreenState extends State<AddPurchaseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController(text: 'PINV-AUTO-001');
  DateTime _selectedDate = DateTime.now();
  int? _selectedSupplier;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<Map<String, dynamic>> _products = [];
  double _grossAmount = 0.0;
  double _discount = 0.0;
  double _gst = 0.0;
  double _grandTotal = 0.0;
  double _amountPaid = 0.0;

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
    _invoiceNoController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double gross = 0;
    for (var p in _products) {
      gross += (p['quantity'] as double) * (p['price'] as double);
    }
    setState(() {
      _grossAmount = gross;
      _grandTotal = _grossAmount - _discount + _gst;
      _amountPaid = _grandTotal;
    });
  }

  void _addProductRow() {
    final availableProducts = _productService.products;
    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available to add')),
      );
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

  void _navigateToEntryList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PurchaseEntryListScreen()),
    );
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
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

    final entry = PurchaseEntry(
      id: 'PE-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: _invoiceNoController.text.trim(),
      invoiceDate: _selectedDate,
      supplierId: supplier.suppId.toString(),
      supplierName: supplier.suppName,
      products: _products.map((p) {
        final qty = p['quantity'] as double;
        final price = p['price'] as double;
        return PurchaseEntryProduct(
          id: 'PEP-${DateTime.now().millisecondsSinceEpoch}',
          productId: p['productId'] as String,
          productName: p['productName'] as String,
          quantity: qty,
          unit: p['unit'] as String,
          price: price,
          total: qty * price,
        );
      }).toList(),
      totalQuantity: totalQty,
      grossAmount: _grossAmount,
      discount: _discount,
      gst: _gst,
      grandTotal: _grandTotal,
      payments: {'Cash': _amountPaid},
      amountPaid: _amountPaid,
      balance: _grandTotal - _amountPaid,
    );

    await PurchaseEntryService().addEntry(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase Entry saved successfully!')),
      );
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
                      width: isMobile ? double.infinity : 200,
                      child: TextFormField(
                        controller: _invoiceNoController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice / Bill Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 220,
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
                      width: isMobile ? double.infinity : 280,
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
                            'Items (${_products.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addProductRow,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _products.isEmpty
                            ? const Center(child: Text('No items added. Click "Add Item".'))
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
                      'Grand Total: ₹${_grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveEntry,
                      icon: const Icon(Icons.check),
                      label: const Text('Save Purchase Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
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
                  title: const Text('Purchase Entry / Invoice (F7)'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.list),
                      tooltip: 'View All Invoices',
                      onPressed: _navigateToEntryList,
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
              onPressed: _navigateToEntryList,
            ),
          ],
        ),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }
}
