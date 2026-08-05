import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase_return.dart';
import '../../../services/purchase_return_service.dart';
import '../../../services/shortcut_service.dart';
import '../../../widgets/app_drawer.dart';
import 'add_purchase_return_screen.dart';

class PurchaseReturnListScreen extends StatefulWidget {
  const PurchaseReturnListScreen({super.key});

  @override
  State<PurchaseReturnListScreen> createState() => _PurchaseReturnListScreenState();
}

class _PurchaseReturnListScreenState extends State<PurchaseReturnListScreen> {
  final PurchaseReturnService _purchaseReturnService = PurchaseReturnService();
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _purchaseReturnService.initializeDummyData();
    _purchaseReturnService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _purchaseReturnService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<PurchaseReturn> get _filteredReturns {
    if (_searchQuery.isEmpty) {
      return _purchaseReturnService.returns;
    }
    return _purchaseReturnService.returns.where((r) {
      final query = _searchQuery.toLowerCase();
      return r.returnNo.toLowerCase().contains(query) ||
          r.supplierName.toLowerCase().contains(query) ||
          r.invoiceNo.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;

    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Purchase Returns',
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
                    AppRoutes.purchaseReturnAdd,
                    () => const AddPurchaseReturnScreen(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Return (Ctrl+F7)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredReturns.isEmpty
              ? const Center(child: Text('No Purchase Returns Found'))
              : ListView.builder(
                  itemCount: _filteredReturns.length,
                  itemBuilder: (context, index) {
                    final ret = _filteredReturns[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.assignment_return, color: Colors.orange),
                        ),
                        title: Text(
                          ret.returnNo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Supplier: ${ret.supplierName} • Against Inv: ${ret.invoiceNo}',
                        ),
                        trailing: Text(
                          '₹${ret.grandRefund.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.red,
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
                appBar: AppBar(title: const Text('Purchase Returns')),
                body: content,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Returns')),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }
}
