import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_drawer.dart';
import 'sales_entry_list_screen.dart';

class AddSalesEntryScreen extends StatefulWidget {
  const AddSalesEntryScreen({super.key});

  @override
  State<AddSalesEntryScreen> createState() => _AddSalesEntryScreenState();
}

class _AddSalesEntryScreenState extends State<AddSalesEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController(text: 'INV-AUTO-001');
  DateTime _selectedDate = DateTime.now();
  String? _selectedCustomer;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<Map<String, dynamic>> _products = [];
  double _grossAmount = 0.0;
  double _discount = 0.0;
  double _gst = 0.0;
  double _grandTotal = 0.0;
  double _amountReceived = 0.0;
  double _balance = 0.0;

  final Map<String, double> _payments = {'Cash': 0.0, 'UPI': 0.0, 'Card': 0.0};

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

    double totalReceived = 0;
    _payments.forEach((key, value) {
      totalReceived += value;
    });

    setState(() {
      _grossAmount = gross;
      _grandTotal = _grossAmount - _discount + _gst;
      _amountReceived = totalReceived;
      _balance = _grandTotal - _amountReceived;
      if (_balance < 0) _balance = 0;
    });
  }

  void _addProductRow() {
    setState(() {
      _products.add({
        'product': null,
        'quantity': 1.0,
        'price': 0.0,
        'total': 0.0,
      });
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

  void _navigateToSalesList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SalesEntryListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1000;
    final bool isMobile = screenWidth < 600;

    Widget stickyBottomBar = Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: isDesktop || isTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildPaymentCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildTotalsCard()),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPaymentCard(),
                const SizedBox(height: 8),
                _buildTotalsCard(),
              ],
            ),
    );

    Widget content = Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: _buildBasicDetailsCard(isDesktop, isTablet, isMobile),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildProductsCard(isDesktop, isTablet, isMobile),
            ),
          ),
          const SizedBox(height: 16),
          stickyBottomBar,
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
                  title: const Text('Sales Entry'),
                  actions: _buildAppBarActions(),
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
          title: const Text('Sales Entry'),
          actions: _buildAppBarActions(isMobile: true),
        ),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }

  List<Widget> _buildAppBarActions({bool isMobile = false}) {
    if (isMobile) {
      return [
        IconButton(
          onPressed: _navigateToSalesList,
          icon: const Icon(Icons.list),
          tooltip: 'View Sales',
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice placed on hold')),
            );
          },
          icon: const Icon(Icons.pause, color: Colors.orange),
          tooltip: 'Hold',
        ),
        IconButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice Saved successfully')),
              );
            }
          },
          icon: const Icon(Icons.save),
          tooltip: 'Save',
        ),
      ];
    }
    return [
      TextButton.icon(
        onPressed: _navigateToSalesList,
        icon: const Icon(Icons.list),
        label: const Text('View Sales'),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice placed on hold')),
          );
        },
        icon: const Icon(Icons.pause, color: Colors.orange),
        label: const Text('Hold', style: TextStyle(color: Colors.orange)),
      ),
      FilledButton.icon(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice Saved successfully')),
            );
          }
        },
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildBasicDetailsCard(bool isDesktop, bool isTablet, bool isMobile) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                children: [
                  _buildInvoiceNoField(),
                  const SizedBox(height: 8),
                  _buildDateField(),
                  const SizedBox(height: 8),
                  _buildCustomerDropdown(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildInvoiceNoField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCustomerDropdown()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceNoField() {
    return TextFormField(
      controller: _invoiceNoController,
      decoration: InputDecoration(
        labelText: 'Invoice No',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      readOnly: true,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Invoice Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_dateFormat.format(_selectedDate)),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Customer (Optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedCustomer,
      items: [
        'Acme Corp',
        'Global Industries',
        'Tech Solutions',
      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) {
        setState(() {
          _selectedCustomer = val;
        });
      },
    );
  }

  Widget _buildProductsCard(bool isDesktop, bool isTablet, bool isMobile) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // crossAxisAlignment: WrapCrossAlignment.center,
              // spacing: 8,
              // runSpacing: 8,
              children: [
                const Text(
                  'Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _addProductRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products added. Scan or Add Product to start.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: _products.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 32),
                    itemBuilder: (context, index) {
                      return isMobile
                          ? _buildMobileProductRow(index)
                          : _buildDesktopProductRow(index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProductRow(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Product',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            items: [
              'Laptop Dell XPS',
              'Wireless Mouse',
              'Keyboard',
            ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              setState(() {
                _products[index]['product'] = val;
                _products[index]['price'] = 1500.0;
                _calculateTotals();
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Qty',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            initialValue: _products[index]['quantity'].toString(),
            onChanged: (val) {
              _products[index]['quantity'] = double.tryParse(val) ?? 0.0;
              _calculateTotals();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Price (₹)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            initialValue: _products[index]['price'].toString(),
            onChanged: (val) {
              _products[index]['price'] = double.tryParse(val) ?? 0.0;
              _calculateTotals();
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeProductRow(index),
          tooltip: 'Remove',
        ),
      ],
    );
  }

  Widget _buildMobileProductRow(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Item ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeProductRow(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Product',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          items: [
            'Laptop Dell XPS',
            'Wireless Mouse',
            'Keyboard',
          ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (val) {
            setState(() {
              _products[index]['product'] = val;
              _products[index]['price'] = 1500.0;
              _calculateTotals();
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Qty',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                initialValue: _products[index]['quantity'].toString(),
                onChanged: (val) {
                  _products[index]['quantity'] = double.tryParse(val) ?? 0.0;
                  _calculateTotals();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                initialValue: _products[index]['price'].toString(),
                onChanged: (val) {
                  _products[index]['price'] = double.tryParse(val) ?? 0.0;
                  _calculateTotals();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._payments.keys.map((mode) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        mode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          _payments[mode] = double.tryParse(val) ?? 0.0;
                          _calculateTotals();
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildTotalRow('Gross Amount', _grossAmount),
            const Divider(height: 12),
            _buildTotalRow('Discount', _discount),
            _buildTotalRow('GST', _gst),
            const Divider(height: 12),
            _buildTotalRow(
              'Grand Total',
              _grandTotal,
              isBold: true,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            const SizedBox(height: 4),
            _buildTotalRow(
              'Amount Received',
              _amountReceived,
              isBold: true,
              color: Colors.green,
            ),
            _buildTotalRow(
              'Balance',
              _balance,
              isBold: true,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    double size = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? size : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? size : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
