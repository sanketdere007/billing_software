import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_message_dialog.dart';
import '../../../widgets/save_clear_shortcuts.dart';
import 'sales_return_list_screen.dart';

class AddSalesReturnScreen extends StatefulWidget {
  const AddSalesReturnScreen({super.key});

  @override
  State<AddSalesReturnScreen> createState() => _AddSalesReturnScreenState();
}

class _AddSalesReturnScreenState extends State<AddSalesReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _returnNoController = TextEditingController(text: 'RET-AUTO-001');
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String? _selectedInvoice;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<Map<String, dynamic>> _products = [];
  double _returnAmount = 0.0;
  double _taxAdjustment = 0.0;
  double _grandRefund = 0.0;
  
  String? _selectedRefundMode;

  @override
  void dispose() {
    _returnNoController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double total = 0;
    for (var p in _products) {
      total += (p['returnQuantity'] as double) * (p['price'] as double);
    }
    setState(() {
      _returnAmount = total;
      _grandRefund = _returnAmount + _taxAdjustment;
    });
  }

  void _loadInvoiceProducts(String invoiceNo) {
    // Mock loading products from an invoice
    setState(() {
      _products.clear();
      _products.add({
        'productName': 'Laptop Dell XPS',
        'returnQuantity': 1.0,
        'maxQuantity': 1.0,
        'price': 85000.0,
        'returnReason': 'Defective',
        'isDamaged': true,
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
      MaterialPageRoute(builder: (context) => const SalesReturnListScreen()),
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
                Expanded(flex: 2, child: _buildRefundModeCard()),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _buildRefundSummary()),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefundModeCard(),
                const SizedBox(height: 8),
                _buildRefundSummary(),
              ],
            ),
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
          if (_selectedInvoice != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildProductsCard(isMobile),
              ),
            ),
          if (_selectedInvoice != null) const SizedBox(height: 16),
          if (_selectedInvoice != null) stickyBottomBar,
        ],
      ),
    );

    Widget scaffoldWidget;
    if (isDesktop) {
      scaffoldWidget = Scaffold(
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
                  title: const Text('Sales Return'),
                  actions: _buildAppBarActions(),
                ),
                body: content,
              ),
            ),
          ],
        ),
      );
    } else {
      scaffoldWidget = Scaffold(
        appBar: AppBar(
          title: const Text('Sales Return'),
          actions: _buildAppBarActions(isMobile: true),
        ),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }

    return SaveClearShortcuts(
      onSave: () async {
        if (_formKey.currentState!.validate()) {
          await showSuccessDialog(context, 'Sales Return Saved successfully');
        }
      },
      onClear: () {
        _formKey.currentState?.reset();
        _returnNoController.clear();
        setState(() {
          _selectedInvoice = null;
          _selectedRefundMode = null;
          _products.clear();
          _returnAmount = 0.0;
          _taxAdjustment = 0.0;
          _grandRefund = 0.0;
        });
      },
      child: scaffoldWidget,
    );
  }

  List<Widget> _buildAppBarActions({bool isMobile = false}) {
    if (isMobile) {
      return [
        IconButton(
          onPressed: _navigateToReturnList,
          icon: const Icon(Icons.list),
          tooltip: 'View Returns',
        ),
        IconButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await showSuccessDialog(context, 'Sales Return Saved successfully');
            }
          },
          icon: const Icon(Icons.save),
          tooltip: 'Save',
        ),
      ];
    }
    return [
      TextButton.icon(
        onPressed: _navigateToReturnList,
        icon: const Icon(Icons.list),
        label: const Text('View Returns'),
      ),
      const SizedBox(width: 8),
      FilledButton.icon(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            await showSuccessDialog(context, 'Sales Return Saved successfully');
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
                  _buildReturnNoField(),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildInvoiceDropdown(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildReturnNoField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInvoiceDropdown()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnNoField() {
    return TextFormField(
      controller: _returnNoController,
      decoration: InputDecoration(
        labelText: 'Return No',
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
          labelText: 'Return Date',
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

  Widget _buildInvoiceDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select Invoice *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedInvoice,
      items: ['INV-2023-001', 'INV-2023-002', 'INV-2023-003']
          .map((inv) => DropdownMenuItem(value: inv, child: Text(inv)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedInvoice = val;
          if (val != null) {
            _loadInvoiceProducts(val);
          }
        });
      },
      validator: (value) => value == null ? 'Please select an invoice' : null,
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
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Select Products to Return',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        Text('No products found for this invoice.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
            initialValue: _products[index]['productName'],
            readOnly: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Qty (Max: ${_products[index]['maxQuantity']})',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            initialValue: _products[index]['returnQuantity'].toString(),
            onChanged: (val) {
              double qty = double.tryParse(val) ?? 0.0;
              if (qty > _products[index]['maxQuantity']) {
                qty = _products[index]['maxQuantity'];
              }
              _products[index]['returnQuantity'] = qty;
              _calculateTotals();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            value: _products[index]['returnReason'],
            items: ['Defective', 'Wrong Item', 'Not Required']
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _products[index]['returnReason'] = val;
              });
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
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Product Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          initialValue: _products[index]['productName'],
          readOnly: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Qty (Max: ${_products[index]['maxQuantity']})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                initialValue: _products[index]['returnQuantity'].toString(),
                onChanged: (val) {
                  double qty = double.tryParse(val) ?? 0.0;
                  if (qty > _products[index]['maxQuantity']) {
                    qty = _products[index]['maxQuantity'];
                  }
                  _products[index]['returnQuantity'] = qty;
                  _calculateTotals();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                value: _products[index]['returnReason'],
                items: ['Defective', 'Wrong Item', 'Not Required']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _products[index]['returnReason'] = val;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefundModeCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Refund Mode',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildRefundModeDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundModeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Refund Mode *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedRefundMode,
      items: ['Cash', 'UPI', 'Bank', 'Wallet', 'Credit Note']
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedRefundMode = val;
        });
      },
      validator: (value) => value == null ? 'Please select a refund mode' : null,
    );
  }

  Widget _buildRefundSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primaryContainer),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Return Amount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text('₹${_returnAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax Adjustment:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text('₹${_taxAdjustment.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Refund:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '₹${_grandRefund.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
