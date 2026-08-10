import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/branch.dart';
import '../../models/company.dart';
import '../../services/branch_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/company_dropdown.dart';
import '../../widgets/direct_back_scope.dart';

class BranchMasterScreen extends StatefulWidget {
  final BranchListItem? branchToEdit;

  const BranchMasterScreen({super.key, this.branchToEdit});

  @override
  State<BranchMasterScreen> createState() => _BranchMasterScreenState();
}

class _BranchMasterScreenState extends State<BranchMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final BranchService _branchService = branchService;
  final SessionService _sessionService = sessionService;

  final FocusNode _companyFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  int? _selectedCompId;
  String _companyId = '';

  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditing => widget.branchToEdit != null;

  @override
  void initState() {
    super.initState();
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _companyFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _companyFocusNode.dispose();
    _nameFocusNode.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _contactPersonController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _initFormData() {
    if (widget.branchToEdit != null) {
      final branch = widget.branchToEdit!;
      _nameController.text = branch.branchName;
      _codeController.text = branch.code ?? '';
      _contactPersonController.text = branch.branchContactPerson;
      _mobileController.text = branch.branchMobileNo;
      _emailController.text = branch.branchEmail;
      _gstController.text = branch.branchGSTNo;
      _addressController.text = branch.branchAddress;
      _cityController.text = branch.branchCity;
      _stateController.text = branch.branchState;
      _pincodeController.text = branch.branchPincode;
      
      _selectedCompId = branch.branchCompId;
      if (_selectedCompId != null && _selectedCompId! > 0) {
        _companyId = _selectedCompId.toString();
      }
      
      _isActive = branch.branchIsActive;
    } else {
      _selectedCompId = _sessionService.selectedCompId;
      if (_selectedCompId != null && _selectedCompId! > 0) {
        _companyId = _selectedCompId.toString();
      }
      _isActive = true;
    }
  }

  Future<void> _saveBranch({bool saveAndNew = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCompId == null || _selectedCompId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company.'),
          backgroundColor: Colors.red,
        ),
      );
      _companyFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newBranch = Branch(
        id: isEditing ? widget.branchToEdit!.branchId.toString() : 'BR-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        companyId: _companyId,
        contactPerson: _contactPersonController.text.trim().isNotEmpty ? _contactPersonController.text.trim() : null,
        mobileNumber: _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        pincode: _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : null,
        isActive: _isActive,
      );

      if (isEditing) {
        await _branchService.updateBranch(newBranch);
      } else {
        await _branchService.addBranch(newBranch);
      }

      if (!mounted) return;

      final successMsg = isEditing ? 'Branch updated successfully!' : 'Branch created successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(successMsg)),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _codeController.clear();
        _contactPersonController.clear();
        _mobileController.clear();
        _emailController.clear();
        _gstController.clear();
        _addressController.clear();
        _cityController.clear();
        _stateController.clear();
        _pincodeController.clear();
        
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _companyFocusNode.requestFocus();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(e.toString().replaceAll('ApiException: ', ''))),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          final formCard = _buildFormCard(context, isDesktop);

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
                        title: Text(isEditing ? 'Edit Branch' : 'Add New Branch'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Branch List',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: formCard,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit Branch' : 'Add New Branch'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: formCard,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    return Card(
      elevation: isDesktop ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 28.0 : 18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Update Branch Details' : 'Create Branch Master',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Modify branch information and settings'
                              : 'Add a new branch associated with a company',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${widget.branchToEdit!.branchId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Reusable Company Dropdown
              CompanyDropdown(
                selectedCompId: _selectedCompId,
                isRequired: true,
                labelText: 'Select Company *',
                onChanged: (CompanyListItem? comp) {
                  setState(() {
                    _selectedCompId = comp?.compId;
                    _companyId = comp != null ? comp.compId.toString() : '';
                  });
                },
              ),
              const SizedBox(height: 16),

              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildNameField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCodeField(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildGSTField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildContactPersonField(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildEmailField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMobileField(theme)),
                  ],
                ),
              ] else ...[
                _buildNameField(theme),
                const SizedBox(height: 16),
                _buildCodeField(theme),
                const SizedBox(height: 16),
                _buildGSTField(theme),
                const SizedBox(height: 16),
                _buildContactPersonField(theme),
                const SizedBox(height: 16),
                _buildEmailField(theme),
                const SizedBox(height: 16),
                _buildMobileField(theme),
              ],
              
              const SizedBox(height: 24),
              Text(
                'Address Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildAddressField(theme),
              const SizedBox(height: 16),
              
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCityField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStateField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPincodeField(theme)),
                  ],
                ),
              ] else ...[
                _buildCityField(theme),
                const SizedBox(height: 16),
                _buildStateField(theme),
                const SizedBox(height: 16),
                _buildPincodeField(theme),
              ],

              const SizedBox(height: 18),
              _buildStatusTile(theme),
              
              const SizedBox(height: 28),
              _buildActionButtons(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Branch Name *',
        hintText: 'Enter branch name',
        prefixIcon: const Icon(Icons.store_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter branch name';
        }
        return null;
      },
    );
  }

  Widget _buildCodeField(ThemeData theme) {
    return TextFormField(
      controller: _codeController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Branch Code',
        hintText: 'e.g. BR01',
        prefixIcon: const Icon(Icons.code_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildContactPersonField(ThemeData theme) {
    return TextFormField(
      controller: _contactPersonController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Contact Person',
        hintText: 'Manager name',
        prefixIcon: const Icon(Icons.person_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'branch@company.com',
        prefixIcon: const Icon(Icons.email_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }

  Widget _buildMobileField(ThemeData theme) {
    return TextFormField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        hintText: 'e.g. 9876543210',
        prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
          return 'Please enter valid mobile number';
        }
        return null;
      },
    );
  }

  Widget _buildGSTField(ThemeData theme) {
    return TextFormField(
      controller: _gstController,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'GST Number',
        hintText: '15-digit GSTIN',
        prefixIcon: const Icon(Icons.receipt_long_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          if (value.trim().length != 15) {
            return 'GST number must be exactly 15 characters';
          }
        }
        return null;
      },
    );
  }

  Widget _buildAddressField(ThemeData theme) {
    return TextFormField(
      controller: _addressController,
      maxLines: 2,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Address',
        hintText: 'Enter full address',
        prefixIcon: const Icon(Icons.location_on_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildCityField(ThemeData theme) {
    return TextFormField(
      controller: _cityController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'City',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildStateField(ThemeData theme) {
    return TextFormField(
      controller: _stateController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildPincodeField(ThemeData theme) {
    return TextFormField(
      controller: _pincodeController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveBranch(saveAndNew: false),
      decoration: InputDecoration(
        labelText: 'Pincode',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildStatusTile(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
      ),
      child: SwitchListTile(
        value: _isActive,
        onChanged: _isLoading
            ? null
            : (val) {
                setState(() {
                  _isActive = val;
                });
              },
        title: const Text(
          'Active Status',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          _isActive
              ? 'Branch will be available in dropdowns & billing'
              : 'Branch will be inactive and hidden from active lists',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        secondary: Icon(
          _isActive ? Icons.check_circle_outline_rounded : Icons.block_rounded,
          color: _isActive ? Colors.green : Colors.grey,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          if (!isEditing) ...[
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: _isLoading ? null : () => _saveBranch(saveAndNew: true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save & Add Another'),
            ),
          ],
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isLoading ? null : () => _saveBranch(saveAndNew: false),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isEditing ? 'Update Branch' : 'Save Branch'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _isLoading ? null : () => _saveBranch(saveAndNew: false),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isEditing ? 'Update Branch' : 'Save Branch'),
          ),
          if (!isEditing) ...[
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _isLoading ? null : () => _saveBranch(saveAndNew: true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save & Add Another'),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
  }
}
