import 'package:flutter/material.dart';
import '../../models/hsn_sac.dart';
import '../../services/hsn_sac_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_hsn_sac_screen.dart';

class HsnSacListScreen extends StatefulWidget {
  const HsnSacListScreen({super.key});

  @override
  State<HsnSacListScreen> createState() => _HsnSacListScreenState();
}

class _HsnSacListScreenState extends State<HsnSacListScreen> {
  final HsnSacService _hsnSacService = HsnSacService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _hsnSacService.initializeDummyData();
    _hsnSacService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _hsnSacService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  List<HsnSac> get _filteredHsnSacs {
    if (_searchQuery.isEmpty) return _hsnSacService.hsnSacs;
    return _hsnSacService.hsnSacs.where((h) {
      return h.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (h.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _navigateToAddHsnSac() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddHsnSacScreen()));
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
                  hintText: 'Search HSN/SAC...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final hsnSacs = _filteredHsnSacs;
                  if (hsnSacs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No HSN/SAC found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  if (innerConstraints.maxWidth >= 600) return _buildDataTable(hsnSacs);
                  return _buildListView(hsnSacs);
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
                      title: const Text('HSN/SAC Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(onPressed: _navigateToAddHsnSac, icon: const Icon(Icons.add), label: const Text('Add HSN/SAC')),
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
              title: const Text('HSN/SAC Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(onPressed: _navigateToAddHsnSac, icon: const Icon(Icons.add), label: const Text('Add HSN/SAC')),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600 ? FloatingActionButton(onPressed: _navigateToAddHsnSac, child: const Icon(Icons.add)) : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<HsnSac> hsnSacs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: hsnSacs.length,
      itemBuilder: (context, index) {
        final hsnSac = hsnSacs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(hsnSac.code.substring(0, 1).toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ),
            title: Text(hsnSac.code, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hsnSac.description != null) Text(hsnSac.description!),
                if (hsnSac.gstPercentage != null) Text('GST: ${hsnSac.gstPercentage}'),
              ],
            ),
            trailing: Chip(
              label: Text(
                hsnSac.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: hsnSac.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
              ),
              backgroundColor: hsnSac.isActive ? Colors.green.shade100 : Colors.red.shade100,
              side: BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<HsnSac> hsnSacs) {
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
              headingRowColor: WidgetStateProperty.resolveWith((states) => Theme.of(context).colorScheme.surfaceContainerHighest),
              columns: const [
                DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: hsnSacs.map((hsnSac) {
                return DataRow(
                  cells: [
                    DataCell(Text(hsnSac.code)),
                    DataCell(Text(hsnSac.description ?? '-')),
                    DataCell(Text(hsnSac.gstPercentage ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: hsnSac.isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          hsnSac.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(color: hsnSac.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
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
