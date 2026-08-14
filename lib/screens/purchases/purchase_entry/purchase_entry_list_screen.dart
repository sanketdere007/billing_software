import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase_entry.dart';
import '../../../services/purchase_entry_service.dart';
import '../../../services/shortcut_service.dart';
import '../../../widgets/app_drawer.dart';
import 'add_purchase_entry_screen.dart';

class PurchaseEntryListScreen extends StatefulWidget {
  const PurchaseEntryListScreen({super.key});

  @override
  State<PurchaseEntryListScreen> createState() =>
      _PurchaseEntryListScreenState();
}

class _PurchaseEntryListScreenState extends State<PurchaseEntryListScreen> {
  final PurchaseEntryService _purchaseEntryService = PurchaseEntryService();
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _purchaseEntryService.initializeDummyData();
    _purchaseEntryService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _purchaseEntryService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<PurchaseEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) {
      return _purchaseEntryService.entries;
    }
    return _purchaseEntryService.entries.where((e) {
      final query = _searchQuery.toLowerCase();
      return e.invoiceNo.toLowerCase().contains(query) ||
          e.supplierName.toLowerCase().contains(query) ||
          e.status.toLowerCase().contains(query);
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
                    labelText: 'Search Purchase Invoices',
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
                    AppRoutes.purchaseEntryAdd,
                    () => const AddPurchaseEntryScreen(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Entry (F7)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredEntries.isEmpty
              ? const Center(child: Text('No Purchase Entries Found'))
              : ListView.builder(
                  itemCount: _filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredEntries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.teal,
                          ),
                        ),
                        title: Text(
                          entry.invoiceNo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Supplier: ${entry.supplierName} • ${_dateFormat.format(entry.invoiceDate)}',
                        ),
                        trailing: Text(
                          '₹${entry.grandTotal.toStringAsFixed(2)}',
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
                appBar: AppBar(
                  title: const Text('Purchase Entries / Invoices'),
                ),
                body: content,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Entries / Invoices')),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }
}
