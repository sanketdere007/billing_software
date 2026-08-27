import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_message_dialog.dart';
import 'sales_order_list_screen.dart';

class AddSalesOrderScreen extends StatefulWidget {
  const AddSalesOrderScreen({super.key});

  @override
  State<AddSalesOrderScreen> createState() => _AddSalesOrderScreenState();
}

class _AddSalesOrderScreenState extends State<AddSalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderNoController = TextEditingController(text: 'ORD-AUTO-001');
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String? _selectedCustomer;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<Map<String, dynamic>> _products = [];
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _gst = 0.0;
  double _grandTotal = 0.0;

  @override
  void dispose() {
    _orderNoController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double sub = 0;
    for (var p in _products) {
      sub += (p['quantity'] as double) * (p['price'] as double);
    }
    setState(() {
      _subtotal = sub;
      _grandTotal = _subtotal - _discount + _gst;
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

  void _navigateToOrderList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SalesOrderListScreen()),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(flex: 1, child: _buildTotalsCard()),
              ],
            )
          : _buildTotalsCard(),
    );

    Widget content = Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildBasicDetailsCard(isMobile),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildProductsCard(isMobile),
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
            const SizedBox(
              width: 250,
              child: AppDrawer(isPermanent: true),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Sales Order'),
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
          title: const Text('Sales Order'),
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
          onPressed: _navigateToOrderList,
          icon: const Icon(Icons.list),
          tooltip: 'View Orders',
        ),
        IconButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await showSuccessDialog(context, 'Order Saved successfully');
            }
          },
          icon: const Icon(Icons.save),
          tooltip: 'Save',
        ),
      ];
    }
    return [
      TextButton.icon(
        onPressed: _navigateToOrderList,
        icon: const Icon(Icons.list),
        label: const Text('View Orders'),
      ),
      const SizedBox(width: 8),
      FilledButton.icon(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            await showSuccessDialog(context, 'Order Saved successfully');
          }
        },
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildBasicDetailsCard(bool isMobile) {
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
                  _buildOrderNoField(),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildCustomerDropdown(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildOrderNoField()),
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

  Widget _buildOrderNoField() {
    return TextFormField(
      controller: _orderNoController,
      decoration: InputDecoration(
        labelText: 'Order No',
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
          labelText: 'Order Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_dateFormat.format(_selectedDate)),
            Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
      items: ['Acme Corp', 'Global Industries', 'Tech Solutions']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedCustomer = val;
        });
      },
    );
  }

  Widget _buildProductsCard(bool isMobile) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addProductRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
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
                        Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No products added. Click Add Product to start.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: _products.length,
                    separatorBuilder: (context, index) => const Divider(height: 32),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: ['Laptop Dell XPS', 'Wireless Mouse', 'Keyboard']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            Text('Item ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
          items: ['Laptop Dell XPS', 'Wireless Mouse', 'Keyboard']
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            _buildTotalRow('Subtotal', _subtotal),
            const Divider(height: 12),
            _buildTotalRow('Discount', _discount),
            _buildTotalRow('GST', _gst),
            const Divider(height: 12),
            _buildTotalRow('Grand Total', _grandTotal, isBold: true, color: Theme.of(context).colorScheme.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, Color? color, double size = 14}) {
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
