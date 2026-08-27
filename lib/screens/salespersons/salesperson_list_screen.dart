import 'package:flutter/material.dart';
import '../../models/salesperson.dart';
import '../../services/salesperson_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_salesperson_screen.dart';

class SalespersonListScreen extends StatefulWidget {
  const SalespersonListScreen({super.key});

  @override
  State<SalespersonListScreen> createState() => _SalespersonListScreenState();
}

class _SalespersonListScreenState extends State<SalespersonListScreen> {
  final SalespersonService _salespersonService = SalespersonService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _salespersonService.initializeDummyData();
    _salespersonService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _salespersonService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<Salesperson> get _filteredSalespersons {
    if (_searchQuery.isEmpty) {
      return _salespersonService.salespersons;
    }
    return _salespersonService.salespersons.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(query) ||
             (s.employeeCode?.toLowerCase().contains(query) ?? false) ||
             (s.mobileNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _navigateToAddSalesperson() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddSalespersonScreen()),
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
                  hintText: 'Search salespersons...',
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
                  final salespersons = _filteredSalespersons;
                  
                  if (salespersons.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_pin, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No salespersons found',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (innerConstraints.maxWidth >= 600) {
                    return _buildDataTable(salespersons);
                  } else {
                    return _buildListView(salespersons);
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
                      title: const Text('Salesperson Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: _navigateToAddSalesperson,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Salesperson'),
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
              title: const Text('Salesperson Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: _navigateToAddSalesperson,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Salesperson'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600
                ? FloatingActionButton(
                    onPressed: _navigateToAddSalesperson,
                    child: const Icon(Icons.add),
                  )
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<Salesperson> salespersons) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: salespersons.length,
      itemBuilder: (context, index) {
        final salesperson = salespersons[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                salesperson.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(
              salesperson.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (salesperson.employeeCode != null) ...[
                  const SizedBox(height: 4),
                  Text('EMP: ${salesperson.employeeCode}'),
                ],
                if (salesperson.mobileNumber != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(salesperson.mobileNumber!),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Chip(
              label: Text(
                salesperson.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: salesperson.isActive ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: salesperson.isActive ? Colors.green.shade100 : Colors.red.shade100,
              side: BorderSide.none,
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<Salesperson> salespersons) {
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
                DataColumn(label: Text('Emp Code', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Commission', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: salespersons.map((salesperson) {
                return DataRow(
                  cells: [
                    DataCell(Text(salesperson.name)),
                    DataCell(Text(salesperson.employeeCode ?? '-')),
                    DataCell(Text(salesperson.mobileNumber ?? '-')),
                    DataCell(Text(salesperson.commissionPercentage != null ? '${salesperson.commissionPercentage}%' : '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: salesperson.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          salesperson.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: salesperson.isActive ? Colors.green.shade700 : Colors.red.shade700,
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
