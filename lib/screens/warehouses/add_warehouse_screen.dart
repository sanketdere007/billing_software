import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/warehouse.dart';
import '../../services/warehouse_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/save_clear_shortcuts.dart';

class AddWarehouseScreen extends StatefulWidget {
  const AddWarehouseScreen({super.key});

  @override
  State<AddWarehouseScreen> createState() => _AddWarehouseScreenState();
}

class _AddWarehouseScreenState extends State<AddWarehouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final WarehouseService _warehouseService = WarehouseService();
  bool _isLoading = false;
  
  String _name = '';
  String _code = '';
  String _branchId = ''; // Dropdown in real app
  String _managerName = '';
  String _mobile = '';
  String _address = '';
  String _description = '';
  bool _isActive = true;

  Future<void> _saveWarehouse({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final newWarehouse = Warehouse(
        id: 'WH-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        code: _code.isNotEmpty ? _code : null,
        branchId: _branchId,
        managerName: _managerName.isNotEmpty ? _managerName : null,
        mobileNumber: _mobile.isNotEmpty ? _mobile : null,
        address: _address.isNotEmpty ? _address : null,
        description: _description.isNotEmpty ? _description : null,
        isActive: _isActive,
      );

      await _warehouseService.addWarehouse(newWarehouse);

      if (!mounted) return;
      
      await showSuccessDialog(context, 'Warehouse saved successfully!');
      if (!mounted) return;

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      await showErrorDialog(context, 'Error saving warehouse: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) {
          _saveWarehouse(saveAndNew: false);
        }
      },
      onClear: () {
        _formKey.currentState?.reset();
        setState(() {
          _isActive = true;
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
                                'Warehouse Information',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              if (constraints.maxWidth >= 600) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildNameField()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildCodeField()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildBranchIdField(),
                              ] else ...[
                                _buildNameField(),
                                const SizedBox(height: 16),
                                _buildCodeField(),
                                const SizedBox(height: 16),
                                _buildBranchIdField(),
                              ],
                              const SizedBox(height: 24),
                              Text(
                                'Contact Details',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              if (constraints.maxWidth >= 600) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildManagerNameField()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildMobileField()),
                                  ],
                                ),
                              ] else ...[
                                _buildManagerNameField(),
                                const SizedBox(height: 16),
                                _buildMobileField(),
                              ],
                              const SizedBox(height: 24),
                              Text(
                                'Address Details',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _buildAddressField(),
                              const SizedBox(height: 16),
                              _buildDescriptionField(),
                              const SizedBox(height: 16),
                              _buildStatusField(),
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
                      appBar: AppBar(title: const Text('Add Warehouse')),
                      body: content,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(title: const Text('Add Warehouse')),
              drawer: const AppDrawer(isPermanent: false),
              body: content,
            );
          }
        },
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Warehouse Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warehouse),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter warehouse name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Warehouse Code',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.code),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _code = value?.trim() ?? '',
    );
  }

  Widget _buildBranchIdField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Branch *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.store),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter/select branch';
        }
        return null;
      },
      onSaved: (value) => _branchId = value!.trim(),
    );
  }

  Widget _buildManagerNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Manager Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _managerName = value?.trim() ?? '',
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Mobile Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
          return 'Please enter valid mobile number';
        }
        return null;
      },
      onSaved: (value) => _mobile = value?.trim() ?? '',
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Address',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      maxLines: 2,
      textInputAction: TextInputAction.next,
      onSaved: (value) => _address = value?.trim() ?? '',
    );
  }
  
  Widget _buildDescriptionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      textInputAction: TextInputAction.next,
      onSaved: (value) => _description = value?.trim() ?? '',
    );
  }

  Widget _buildStatusField() {
    return SwitchListTile(
      title: const Text('Status (Active)'),
      value: _isActive,
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
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
            onPressed: () => _saveWarehouse(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveWarehouse(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveWarehouse(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveWarehouse(saveAndNew: true),
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
