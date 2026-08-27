import 'package:flutter/material.dart';
import '../../models/role.dart';
import '../../services/role_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_role_screen.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
  final RoleService _roleService = RoleService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _roleService.initializeDummyData();
    _roleService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _roleService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<Role> get _filteredRoles {
    if (_searchQuery.isEmpty) {
      return _roleService.roles;
    }
    return _roleService.roles.where((r) {
      final query = _searchQuery.toLowerCase();
      return r.name.toLowerCase().contains(query) ||
             (r.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _navigateToAddRole() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddRoleScreen()),
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
                  hintText: 'Search roles...',
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
                  final roles = _filteredRoles;
                  
                  if (roles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No roles found',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (innerConstraints.maxWidth >= 600) {
                    return _buildDataTable(roles);
                  } else {
                    return _buildListView(roles);
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
                      title: const Text('Role & Permission Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: _navigateToAddRole,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Role'),
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
              title: const Text('Role & Permission Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: _navigateToAddRole,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Role'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600
                ? FloatingActionButton(
                    onPressed: _navigateToAddRole,
                    child: const Icon(Icons.add),
                  )
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<Role> roles) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                role.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(
              role.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role.description != null) ...[
                  const SizedBox(height: 4),
                  Text(role.description!),
                ],
              ],
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<Role> roles) {
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
                DataColumn(label: Text('Role Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Permissions Count', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: roles.map((role) {
                return DataRow(
                  cells: [
                    DataCell(Text(role.name)),
                    DataCell(Text(role.description ?? '-')),
                    DataCell(Text(role.permissions.length.toString())),
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
