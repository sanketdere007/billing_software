import 'package:flutter/material.dart';
import '../../models/gst.dart';
import '../../services/gst_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_gst_screen.dart';

class GstListScreen extends StatefulWidget {
  const GstListScreen({super.key});

  @override
  State<GstListScreen> createState() => _GstListScreenState();
}

class _GstListScreenState extends State<GstListScreen> {
  final GstService _gstService = GstService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _gstService.initializeDummyData();
    _gstService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _gstService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  List<Gst> get _filteredGsts {
    if (_searchQuery.isEmpty) return _gstService.gsts;
    return _gstService.gsts.where((g) {
      return (g.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
             g.percentage.toString().contains(_searchQuery);
    }).toList();
  }

  void _navigateToAddGst() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddGstScreen()));
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
                  hintText: 'Search GST...',
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
                  final gsts = _filteredGsts;
                  if (gsts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.percent_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No GST records found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  if (innerConstraints.maxWidth >= 600) return _buildDataTable(gsts);
                  return _buildListView(gsts);
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
                      title: const Text('GST Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(onPressed: _navigateToAddGst, icon: const Icon(Icons.add), label: const Text('Add GST')),
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
              title: const Text('GST Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(onPressed: _navigateToAddGst, icon: const Icon(Icons.add), label: const Text('Add GST')),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600 ? FloatingActionButton(onPressed: _navigateToAddGst, child: const Icon(Icons.add)) : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<Gst> gsts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: gsts.length,
      itemBuilder: (context, index) {
        final gst = gsts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${gst.percentage.toInt()}%', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            title: Text(gst.name ?? 'GST ${gst.percentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CGST: ${gst.cgst}% | SGST: ${gst.sgst}% | IGST: ${gst.igst}%'),
                if (gst.description != null) Text(gst.description!),
              ],
            ),
            trailing: Chip(
              label: Text(
                gst.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: gst.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
              ),
              backgroundColor: gst.isActive ? Colors.green.shade100 : Colors.red.shade100,
              side: BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<Gst> gsts) {
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
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('CGST %', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('SGST %', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: gsts.map((gst) {
                return DataRow(
                  cells: [
                    DataCell(Text(gst.name ?? '-')),
                    DataCell(Text('${gst.percentage}%')),
                    DataCell(Text('${gst.cgst}%')),
                    DataCell(Text('${gst.sgst}%')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: gst.isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          gst.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(color: gst.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
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
