import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/price_list.dart';
import '../../services/price_list_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_price_list_screen.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final PriceListService _priceListService = PriceListService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _priceListService.initializeDummyData();
    _priceListService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _priceListService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<PriceList> get _filteredPriceLists {
    if (_searchQuery.isEmpty) {
      return _priceListService.priceLists;
    }
    return _priceListService.priceLists.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
             (p.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _navigateToAddPriceList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddPriceListScreen()),
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
                  hintText: 'Search price lists...',
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
                  final priceLists = _filteredPriceLists;
                  
                  if (priceLists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No price lists found',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (innerConstraints.maxWidth >= 600) {
                    return _buildDataTable(priceLists);
                  } else {
                    return _buildListView(priceLists);
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
                      title: const Text('Price List Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Refreshing list...')),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: _navigateToAddPriceList,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Price List'),
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
              title: const Text('Price List Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refreshing list...')),
                    );
                  },
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: _navigateToAddPriceList,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Price List'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600
                ? FloatingActionButton(
                    onPressed: _navigateToAddPriceList,
                    child: const Icon(Icons.add),
                  )
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<PriceList> priceLists) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: priceLists.length,
      itemBuilder: (context, index) {
        final priceList = priceLists[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    priceList.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (priceList.isDefault)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (priceList.description != null && priceList.description!.isNotEmpty)
                  Text(priceList.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (priceList.effectiveFrom != null) ...[
                  const SizedBox(height: 4),
                  Text('From: ${DateFormat('dd-MMM-yyyy').format(priceList.effectiveFrom!)}'),
                ],
              ],
            ),
            trailing: Chip(
              label: Text(
                priceList.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: priceList.isActive ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: priceList.isActive ? Colors.green.shade100 : Colors.red.shade100,
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

  Widget _buildDataTable(List<PriceList> priceLists) {
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
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Effective From', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Effective To', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Default', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: priceLists.map((priceList) {
                return DataRow(
                  cells: [
                    DataCell(Text(priceList.name)),
                    DataCell(Text(priceList.description ?? '-')),
                    DataCell(Text(priceList.effectiveFrom != null 
                        ? DateFormat('dd-MMM-yyyy').format(priceList.effectiveFrom!) 
                        : '-')),
                    DataCell(Text(priceList.effectiveTo != null 
                        ? DateFormat('dd-MMM-yyyy').format(priceList.effectiveTo!) 
                        : '-')),
                    DataCell(
                      priceList.isDefault 
                          ? const Icon(Icons.check_circle, color: Colors.blue, size: 20)
                          : const SizedBox(),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priceList.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          priceList.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: priceList.isActive ? Colors.green.shade700 : Colors.red.shade700,
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
