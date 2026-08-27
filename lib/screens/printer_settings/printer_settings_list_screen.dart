import 'package:flutter/material.dart';
import '../../models/printer_settings.dart';
import '../../services/printer_settings_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_printer_settings_screen.dart';

class PrinterSettingsListScreen extends StatefulWidget {
  const PrinterSettingsListScreen({super.key});

  @override
  State<PrinterSettingsListScreen> createState() => _PrinterSettingsListScreenState();
}

class _PrinterSettingsListScreenState extends State<PrinterSettingsListScreen> {
  final PrinterSettingsService _service = PrinterSettingsService();
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

  List<PrinterSettings> get _filteredSettings {
    if (_searchQuery.isEmpty) {
      return _service.settingsList;
    }
    return _service.settingsList.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(query) ||
             s.type.toLowerCase().contains(query);
    }).toList();
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddPrinterSettingsScreen()),
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
                  hintText: 'Search printer settings...',
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
                          Icon(Icons.print, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No printer settings found',
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
                      title: const Text('Printer Settings'),
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
                            label: const Text('Add Printer'),
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
              title: const Text('Printer Settings'),
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
                      label: const Text('Add Printer'),
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

  Widget _buildListView(List<PrinterSettings> settingsList) {
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
              child: Icon(Icons.print, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    settings.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (settings.isDefault)
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
                Text('Type: ${settings.type}'),
                if (settings.type == 'Thermal') Text('Width: ${settings.printWidth ?? '-'}')
                else Text('Paper: ${settings.paperSize ?? '-'}'),
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

  Widget _buildDataTable(List<PrinterSettings> settingsList) {
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
                DataColumn(label: Text('Printer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Paper Size/Width', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Copies', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Auto Print', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Default', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: settingsList.map((settings) {
                return DataRow(
                  cells: [
                    DataCell(Text(settings.name)),
                    DataCell(Text(settings.type)),
                    DataCell(Text(settings.type == 'Thermal' ? (settings.printWidth ?? '-') : (settings.paperSize ?? '-'))),
                    DataCell(Text(settings.numberOfCopies.toString())),
                    DataCell(
                      settings.autoPrint 
                          ? const Icon(Icons.check_circle, color: Colors.blue, size: 20)
                          : const SizedBox(),
                    ),
                    DataCell(
                      settings.isDefault 
                          ? const Icon(Icons.check_circle, color: Colors.blue, size: 20)
                          : const SizedBox(),
                    ),
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
