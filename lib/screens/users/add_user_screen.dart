import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/app_drawer.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  bool _isLoading = false;
  
  String _fullName = '';
  String _username = '';
  String _email = '';
  String _mobile = '';
  String _password = '';
  String _roleId = '';
  String _companyId = '';
  String _branchId = '';
  bool _isActive = true;

  Future<void> _saveUser({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final newUser = AppUser(
        id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
        fullName: _fullName,
        username: _username,
        email: _email.isNotEmpty ? _email : null,
        mobileNumber: _mobile,
        password: _password,
        roleId: _roleId,
        companyId: _companyId,
        branchId: _branchId,
        isActive: _isActive,
      );

      await _userService.addUser(newUser);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _isActive = true;
          _isLoading = false;
          _password = '';
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
          content: Text('Error saving user: $e'),
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
                              'User Information',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            if (constraints.maxWidth >= 600) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildFullNameField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildUsernameField()),
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
                              _buildFullNameField(),
                              const SizedBox(height: 16),
                              _buildUsernameField(),
                              const SizedBox(height: 16),
                              _buildEmailField(),
                              const SizedBox(height: 16),
                              _buildMobileField(),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Security',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            if (constraints.maxWidth >= 600) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildPasswordField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildConfirmPasswordField()),
                                ],
                              ),
                            ] else ...[
                              _buildPasswordField(),
                              const SizedBox(height: 16),
                              _buildConfirmPasswordField(),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Assignment Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            if (constraints.maxWidth >= 600) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildCompanyIdField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildBranchIdField()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildRoleIdField(),
                            ] else ...[
                              _buildCompanyIdField(),
                              const SizedBox(height: 16),
                              _buildBranchIdField(),
                              const SizedBox(height: 16),
                              _buildRoleIdField(),
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
                    appBar: AppBar(title: const Text('Add User')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add User')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Full Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter full name';
        }
        return null;
      },
      onSaved: (value) => _fullName = value!.trim(),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Username *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.account_circle),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter username';
        }
        return null;
      },
      onSaved: (value) => _username = value!.trim(),
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
        labelText: 'Mobile Number *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter mobile number';
        }
        if (value.trim().length < 10) {
          return 'Please enter valid mobile number';
        }
        return null;
      },
      onSaved: (value) => _mobile = value!.trim(),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Password *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
      ),
      obscureText: true,
      textInputAction: TextInputAction.next,
      onChanged: (value) => _password = value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      onSaved: (value) => _password = value!,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Confirm Password *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock_outline),
      ),
      obscureText: true,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm password';
        }
        if (value != _password) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyIdField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Company *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter/select company';
        }
        return null;
      },
      onSaved: (value) => _companyId = value!.trim(),
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

  Widget _buildRoleIdField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Role *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.security),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter/select role';
        }
        return null;
      },
      onSaved: (value) => _roleId = value!.trim(),
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
            onPressed: () => _saveUser(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveUser(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveUser(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveUser(saveAndNew: true),
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
