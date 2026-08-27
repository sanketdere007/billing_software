import 'package:flutter/material.dart';
import '../../models/payment_mode.dart';
import '../../services/payment_mode_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_payment_mode_screen.dart';

class PaymentModeListScreen extends StatefulWidget {
  const PaymentModeListScreen({super.key});

  @override
  State<PaymentModeListScreen> createState() => _PaymentModeListScreenState();
}

class _PaymentModeListScreenState extends State<PaymentModeListScreen> {
  final PaymentModeService _paymentModeService = PaymentModeService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _paymentModeService.initializeDummyData();
    _paymentModeService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _paymentModeService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<PaymentMode> get _filteredPaymentModes {
    if (_searchQuery.isEmpty) {
      return _paymentModeService.paymentModes;
    }
    return _paymentModeService.paymentModes.where((m) {
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) ||
             m.type.toLowerCase().contains(query);
    }).toList();
  }

  void _navigateToAddPaymentMode() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddPaymentModeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search payment modes...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final paymentModes = _filteredPaymentModes;
                  
                  if (paymentModes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No payment modes found',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (innerConstraints.maxWidth >= 600) {
                    return _buildDataTable(paymentModes);
                  } else {
                    return _buildListView(paymentModes);
                  }
                },
              ),
            ),
          ],
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
                      title: const Text('Payment Mode Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: _navigateToAddPaymentMode,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Payment Mode'),
                          ),
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
              title: const Text('Payment Mode Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: _navigateToAddPaymentMode,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Payment Mode'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600
                ? FloatingActionButton(
                    onPressed: _navigateToAddPaymentMode,
                    child: const Icon(Icons.add),
                  )
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<PaymentMode> paymentModes) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: paymentModes.length,
      itemBuilder: (context, index) {
        final mode = paymentModes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                mode.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(
              mode.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Type: ${mode.type}'),
                if (mode.description != null && mode.description!.isNotEmpty)
                  Text(mode.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: Chip(
              label: Text(
                mode.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: mode.isActive ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: mode.isActive ? Colors.green.shade100 : Colors.red.shade100,
              side: BorderSide.none,
            ),
            onTap: () {
              // Navigate to details/edit
            },
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<PaymentMode> paymentModes) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => Theme.of(context).colorScheme.surfaceContainerHighest),
              columns: const [
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Order', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: paymentModes.map((mode) {
                return DataRow(
                  cells: [
                    DataCell(Text(mode.name)),
                    DataCell(Text(mode.type)),
                    DataCell(Text(mode.description ?? '-')),
                    DataCell(Text(mode.displayOrder.toString())),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: mode.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mode.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: mode.isActive ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
