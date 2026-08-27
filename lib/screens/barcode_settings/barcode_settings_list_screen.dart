import 'package:flutter/material.dart';
import '../../models/barcode_settings.dart';
import '../../services/barcode_settings_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_barcode_settings_screen.dart';

class BarcodeSettingsListScreen extends StatefulWidget {
  const BarcodeSettingsListScreen({super.key});

  @override
  State<BarcodeSettingsListScreen> createState() => _BarcodeSettingsListScreenState();
}

class _BarcodeSettingsListScreenState extends State<BarcodeSettingsListScreen> {
  final BarcodeSettingsService _service = BarcodeSettingsService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.initializeDummyData();
    _service.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<BarcodeSettings> get _filteredSettings {
    if (_searchQuery.isEmpty) {
      return _service.settingsList;
    }
    return _service.settingsList.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.format.toLowerCase().contains(query) ||
             (s.prefix?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddBarcodeSettingsScreen()),
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
                  hintText: 'Search barcode settings...',
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
                  final settings = _filteredSettings;
                  
                  if (settings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No barcode settings found',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (innerConstraints.maxWidth >= 600) {
                    return _buildDataTable(settings);
                  } else {
                    return _buildListView(settings);
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
                      title: const Text('Barcode Settings'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: _navigateToAdd,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Configuration'),
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
              title: const Text('Barcode Settings'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: _navigateToAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Configuration'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600
                ? FloatingActionButton(
                    onPressed: _navigateToAdd,
                    child: const Icon(Icons.add),
                  )
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<BarcodeSettings> settingsList) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: settingsList.length,
      itemBuilder: (context, index) {
        final settings = settingsList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.qr_code, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            title: Text(
              settings.format,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Prefix: ${settings.prefix ?? '-'}'),
                Text('Length: ${settings.length}'),
              ],
            ),
            trailing: Chip(
              label: Text(
                settings.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: settings.isActive ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: settings.isActive ? Colors.green.shade100 : Colors.red.shade100,
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

  Widget _buildDataTable(List<BarcodeSettings> settingsList) {
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
                DataColumn(label: Text('Format', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Prefix', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Length', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Auto Gen', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Label Size', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: settingsList.map((settings) {
                return DataRow(
                  cells: [
                    DataCell(Text(settings.format)),
                    DataCell(Text(settings.prefix ?? '-')),
                    DataCell(Text(settings.length.toString())),
                    DataCell(
                      settings.autoGenerate 
                          ? const Icon(Icons.check_circle, color: Colors.blue, size: 20)
                          : const SizedBox(),
                    ),
                    DataCell(Text(settings.labelSize ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: settings.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          settings.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: settings.isActive ? Colors.green.shade700 : Colors.red.shade700,
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
