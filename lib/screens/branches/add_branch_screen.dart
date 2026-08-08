import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/branch.dart';
import '../../models/company.dart';
import '../../services/branch_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/company_dropdown.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final BranchService _branchService = branchService;
  bool _isLoading = false;
  
  String _name = '';
  String _code = '';
  String _companyId = ''; 
  int? _selectedCompId;
  String _gst = '';
  String _contactPerson = '';
  String _mobile = '';
  String _email = '';
  String _address = '';
  String _city = '';
  String _state = '';
  String _pincode = '';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _selectedCompId = sessionService.selectedCompId;
    if (_selectedCompId != null && _selectedCompId! > 0) {
      _companyId = _selectedCompId.toString();
    }
  }

  Future<void> _saveBranch({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final newBranch = Branch(
        id: 'BR-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        code: _code.isNotEmpty ? _code : null,
        companyId: _companyId,
        gstNumber: _gst.isNotEmpty ? _gst : null,
        contactPerson: _contactPerson.isNotEmpty ? _contactPerson : null,
        mobileNumber: _mobile.isNotEmpty ? _mobile : null,
        email: _email.isNotEmpty ? _email : null,
        address: _address.isNotEmpty ? _address : null,
        city: _city.isNotEmpty ? _city : null,
        state: _state.isNotEmpty ? _state : null,
        pincode: _pincode.isNotEmpty ? _pincode : null,
        isActive: _isActive,
      );

      await _branchService.addBranch(newBranch);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch saved successfully!'),
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
          content: Text('Error saving branch: $e'),
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
                              'Branch Information',
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildCompanyIdField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildGSTField()),
                                ],
                              ),
                            ] else ...[
                              _buildNameField(),
                              const SizedBox(height: 16),
                              _buildCodeField(),
                              const SizedBox(height: 16),
                              _buildCompanyIdField(),
                              const SizedBox(height: 16),
                              _buildGSTField(),
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
                                  Expanded(child: _buildContactPersonField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildMobileField()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildEmailField(),
                            ] else ...[
                              _buildContactPersonField(),
                              const SizedBox(height: 16),
                              _buildMobileField(),
                              const SizedBox(height: 16),
                              _buildEmailField(),
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
                            if (constraints.maxWidth >= 600) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildCityField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildStateField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildPincodeField()),
                                ],
                              ),
                            ] else ...[
                              _buildCityField(),
                              const SizedBox(height: 16),
                              _buildStateField(),
                              const SizedBox(height: 16),
                              _buildPincodeField(),
                            ],
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
                    appBar: AppBar(title: const Text('Add Branch')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Branch')),
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
        labelText: 'Branch Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.store),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter branch name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Branch Code',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.code),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _code = value?.trim() ?? '',
    );
  }

  Widget _buildCompanyIdField() {
    return CompanyDropdown(
      selectedCompId: _selectedCompId,
      isRequired: true,
      labelText: 'Company',
      onChanged: (CompanyListItem? comp) {
        setState(() {
          _selectedCompId = comp?.compId;
          _companyId = comp != null ? comp.compId.toString() : '';
        });
      },
    );
  }

  Widget _buildContactPersonField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Contact Person',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _contactPerson = value?.trim() ?? '',
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

  Widget _buildGSTField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'GST Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.receipt),
      ),
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (value.length != 15) {
            return 'GST number must be 15 characters';
          }
        }
        return null;
      },
      onSaved: (value) => _gst = value?.trim() ?? '',
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

  Widget _buildCityField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'City',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _city = value?.trim() ?? '',
    );
  }

  Widget _buildStateField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _state = value?.trim() ?? '',
    );
  }

  Widget _buildPincodeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Pincode',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      onSaved: (value) => _pincode = value?.trim() ?? '',
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
            onPressed: () => _saveBranch(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveBranch(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveBranch(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveBranch(saveAndNew: true),
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
