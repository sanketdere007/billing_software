import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase_order.dart';
import '../../../services/purchase_order_service.dart';
import '../../../services/shortcut_service.dart';
import '../../../widgets/app_drawer.dart';
import 'add_purchase_order_screen.dart';

enum ViewMode { table, grid, list }

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  final PurchaseOrderService _purchaseOrderService = PurchaseOrderService();
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  ViewMode? _selectedViewMode;

  @override
  void initState() {
    super.initState();
    _purchaseOrderService.initializeDummyData();
    _purchaseOrderService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _purchaseOrderService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<PurchaseOrder> get _filteredOrders {
    if (_searchQuery.isEmpty) {
      return _purchaseOrderService.orders;
    }
    return _purchaseOrderService.orders.where((o) {
      final query = _searchQuery.toLowerCase();
      return o.orderNo.toLowerCase().contains(query) ||
          o.supplierName.toLowerCase().contains(query) ||
          o.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;
    final bool isMobile = screenWidth < 600;

    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Purchase Orders',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  shortcutService.navigateToNamedScreen(
                    AppRoutes.purchaseOrderAdd,
                    () => const AddPurchaseOrderScreen(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Order (F6)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredOrders.isEmpty
              ? const Center(child: Text('No Purchase Orders Found'))
              : ListView.builder(
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: const Icon(Icons.shopping_bag, color: Colors.indigo),
                        ),
                        title: Text(
                          order.orderNo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Supplier: ${order.supplierName} • ${_dateFormat.format(order.orderDate)}',
                        ),
                        trailing: Text(
                          '₹${order.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(title: const Text('Purchase Orders')),
                body: content,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Orders')),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }
}
