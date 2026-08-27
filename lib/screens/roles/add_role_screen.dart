import 'package:flutter/material.dart';
import '../../models/role.dart';
import '../../services/role_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/save_clear_shortcuts.dart';

class AddRoleScreen extends StatefulWidget {
  const AddRoleScreen({super.key});

  @override
  State<AddRoleScreen> createState() => _AddRoleScreenState();
}

class _AddRoleScreenState extends State<AddRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final RoleService _roleService = RoleService();
  bool _isLoading = false;
  
  String _name = '';
  String _description = '';
  
  final Map<String, List<String>> _selectedPermissions = {};
  
  final List<String> _modules = [
    'Dashboard', 'Customer', 'Supplier', 'Product', 'Purchase', 
    'Sales', 'Reports', 'Stock', 'Users', 'Settings'
  ];
  
  final List<String> _permissionTypes = ['View', 'Add', 'Edit', 'Delete', 'Print', 'Export'];

  Future<void> _saveRole({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final newRole = Role(
        id: 'ROLE-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        description: _description.isNotEmpty ? _description : null,
        permissions: _selectedPermissions,
      );

      await _roleService.addRole(newRole);

      if (!mounted) return;
      
      await showSuccessDialog(context, 'Role saved successfully!');
      if (!mounted) return;

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _selectedPermissions.clear();
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      await showErrorDialog(context, 'Error saving role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveRole(saveAndNew: false);
      },
      onClear: () {
        _formKey.currentState?.reset();
        setState(() {
          _selectedPermissions.clear();
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;

          Widget content = _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role Information',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildNameField(),
                            const SizedBox(height: 16),
                            _buildDescriptionField(),
                            const SizedBox(height: 24),
                            Text(
                              'Permissions',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionsTable(constraints.maxWidth),
                            const SizedBox(height: 32),
                            _buildActionButtons(constraints.maxWidth >= 600),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                    appBar: AppBar(title: const Text('Add Role')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Role')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    ));
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Role Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.security),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter role name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      onSaved: (value) => _description = value?.trim() ?? '',
    );
  }

  Widget _buildPermissionsTable(double maxWidth) {
    if (maxWidth < 600) {
      // Mobile view: list of expansion tiles
      return Column(
        children: _modules.map((module) {
          return ExpansionTile(
            title: Text(module),
            children: [
              Wrap(
                spacing: 8.0,
                children: _permissionTypes.map((type) {
                  final isSelected = _selectedPermissions[module]?.contains(type) ?? false;
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPermissions.putIfAbsent(module, () => []).add(type);
                        } else {
                          _selectedPermissions[module]?.remove(type);
                          if (_selectedPermissions[module]?.isEmpty ?? false) {
                            _selectedPermissions.remove(module);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      );
    } else {
      // Desktop view: DataTable
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith(
                (states) => Theme.of(context).colorScheme.surfaceContainerHighest),
            columns: [
              const DataColumn(label: Text('Module', style: TextStyle(fontWeight: FontWeight.bold))),
              ..._permissionTypes.map((type) => DataColumn(label: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)))),
            ],
            rows: _modules.map((module) {
              return DataRow(
                cells: [
                  DataCell(Text(module, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ..._permissionTypes.map((type) {
                    final isSelected = _selectedPermissions[module]?.contains(type) ?? false;
                    return DataCell(
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedPermissions.putIfAbsent(module, () => []).add(type);
                            } else {
                              _selectedPermissions[module]?.remove(type);
                              if (_selectedPermissions[module]?.isEmpty ?? false) {
                                _selectedPermissions.remove(module);
                              }
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  Widget _buildActionButtons(bool isDesktop) {
    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          FilledButton.tonal(
            onPressed: () => _saveRole(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveRole(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveRole(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveRole(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
  }
}
