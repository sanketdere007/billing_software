import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/salesperson.dart';
import '../../services/salesperson_service.dart';
import '../../widgets/app_drawer.dart';

class AddSalespersonScreen extends StatefulWidget {
  const AddSalespersonScreen({super.key});

  @override
  State<AddSalespersonScreen> createState() => _AddSalespersonScreenState();
}

class _AddSalespersonScreenState extends State<AddSalespersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final SalespersonService _salespersonService = SalespersonService();
  bool _isLoading = false;
  
  String _name = '';
  String _employeeCode = '';
  String _mobile = '';
  String _email = '';
  String _branchId = ''; // Dropdown in a real app
  double _commissionPercentage = 0.0;
  String _address = '';
  bool _isActive = true;

  Future<void> _saveSalesperson({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final newSalesperson = Salesperson(
        id: 'SP-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        employeeCode: _employeeCode.isNotEmpty ? _employeeCode : null,
        mobileNumber: _mobile.isNotEmpty ? _mobile : null,
        email: _email.isNotEmpty ? _email : null,
        branchId: _branchId.isNotEmpty ? _branchId : null,
        commissionPercentage: _commissionPercentage,
        address: _address.isNotEmpty ? _address : null,
        isActive: _isActive,
      );

      await _salespersonService.addSalesperson(newSalesperson);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salesperson saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving salesperson: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                              'Salesperson Information',
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
                                  Expanded(child: _buildEmployeeCodeField()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildEmailField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildMobileField()),
                                ],
                              ),
                            ] else ...[
                              _buildNameField(),
                              const SizedBox(height: 16),
                              _buildEmployeeCodeField(),
                              const SizedBox(height: 16),
                              _buildEmailField(),
                              const SizedBox(height: 16),
                              _buildMobileField(),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Other Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            if (constraints.maxWidth >= 600) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildBranchIdField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildCommissionField()),
                                ],
                              ),
                            ] else ...[
                              _buildBranchIdField(),
                              const SizedBox(height: 16),
                              _buildCommissionField(),
                            ],
                            const SizedBox(height: 16),
                            _buildAddressField(),
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
                    appBar: AppBar(title: const Text('Add Salesperson')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Salesperson')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Salesperson Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter salesperson name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildEmployeeCodeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Employee Code',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.badge),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _employeeCode = value?.trim() ?? '',
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
      onSaved: (value) => _email = value?.trim() ?? '',
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

  Widget _buildBranchIdField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Branch',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.store),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _branchId = value?.trim() ?? '',
    );
  }

  Widget _buildCommissionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Commission Percentage',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.percent),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _commissionPercentage = double.tryParse(value) ?? 0.0;
        }
      },
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
            onPressed: () => _saveSalesperson(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveSalesperson(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveSalesperson(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveSalesperson(saveAndNew: true),
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
