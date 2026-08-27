import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class CompanyMasterScreen extends StatefulWidget {
  final CompanyListItem? companyToEdit;

  const CompanyMasterScreen({super.key, this.companyToEdit});

  @override
  State<CompanyMasterScreen> createState() => _CompanyMasterScreenState();
}

class _CompanyMasterScreenState extends State<CompanyMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final CompanyService _companyService = companyService;

  final FocusNode _nameFocusNode = FocusNode();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _financialYearController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditing => widget.companyToEdit != null;

  @override
  void initState() {
    super.initState();
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _financialYearController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _initFormData() {
    if (widget.companyToEdit != null) {
      final comp = widget.companyToEdit!;
      _nameController.text = comp.compName;
      _codeController.text = comp.code ?? '';
      _emailController.text = comp.compEmail;
      _mobileController.text = comp.compMobileNo;
      _gstController.text = comp.compGSTNo;
      _panController.text = comp.compPANNo;
      _websiteController.text = comp.compWebsite;
      _addressController.text = comp.compAddress;
      _cityController.text = comp.compCity;
      _stateController.text = comp.compState;
      _pincodeController.text = comp.compPincode;
      _financialYearController.text = comp.financialYear ?? '';
      _currencyController.text = comp.currency ?? '';
      _isActive = comp.compIsActive;
    } else {
      _isActive = true;
    }
  }

  Future<void> _saveCompany({bool saveAndNew = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newCompany = Company(
        id: isEditing ? widget.companyToEdit!.compId.toString() : 'COMP-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
        panNumber: _panController.text.trim().isNotEmpty ? _panController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        mobileNumber: _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        pincode: _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : null,
        financialYear: _financialYearController.text.trim().isNotEmpty ? _financialYearController.text.trim() : null,
        currency: _currencyController.text.trim().isNotEmpty ? _currencyController.text.trim() : null,
        isActive: _isActive,
      );

      if (isEditing) {
        await _companyService.updateCompany(newCompany);
      } else {
        await _companyService.addCompany(newCompany);
      }

      if (!mounted) return;

      final successMsg = isEditing ? 'Company updated successfully!' : 'Company created successfully!';

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _codeController.clear();
        _emailController.clear();
        _mobileController.clear();
        _gstController.clear();
        _panController.clear();
        _websiteController.clear();
        _addressController.clear();
        _cityController.clear();
        _stateController.clear();
        _pincodeController.clear();
        _financialYearController.clear();
        _currencyController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _nameFocusNode.requestFocus();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        e.toString().replaceAll('ApiException: ', ''),
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
                        title: Text(isEditing ? 'Edit Company' : 'Add New Company'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Company List',
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
              title: Text(isEditing ? 'Edit Company' : 'Add New Company'),
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
                      Icons.business_rounded,
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
                          isEditing ? 'Update Company Details' : 'Create Company Master',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Modify company information and settings'
                              : 'Add a new company for billing and management',
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
                        'ID: ${widget.companyToEdit!.compId}',
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
                    Expanded(child: _buildEmailField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMobileField(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildGSTField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPANField(theme)),
                  ],
                ),
              ] else ...[
                _buildNameField(theme),
                const SizedBox(height: 16),
                _buildCodeField(theme),
                const SizedBox(height: 16),
                _buildEmailField(theme),
                const SizedBox(height: 16),
                _buildMobileField(theme),
                const SizedBox(height: 16),
                _buildGSTField(theme),
                const SizedBox(height: 16),
                _buildPANField(theme),
              ],
              
              const SizedBox(height: 16),
              _buildWebsiteField(theme),
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

              const SizedBox(height: 24),
              Text(
                'Other Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFinancialYearField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCurrencyField(theme)),
                  ],
                ),
              ] else ...[
                _buildFinancialYearField(theme),
                const SizedBox(height: 16),
                _buildCurrencyField(theme),
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
        labelText: 'Company Name *',
        hintText: 'Enter company name',
        prefixIcon: const Icon(Icons.business_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter company name';
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
        labelText: 'Company Code',
        hintText: 'e.g. COMP01',
        prefixIcon: const Icon(Icons.code_rounded, size: 20, color: Colors.blueAccent),
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
        hintText: 'contact@company.com',
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

  Widget _buildPANField(ThemeData theme) {
    return TextFormField(
      controller: _panController,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'PAN Number',
        hintText: '10-digit PAN',
        prefixIcon: const Icon(Icons.credit_card_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildWebsiteField(ThemeData theme) {
    return TextFormField(
      controller: _websiteController,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Website',
        hintText: 'https://www.company.com',
        prefixIcon: const Icon(Icons.language_rounded, size: 20, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
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
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Pincode',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildFinancialYearField(ThemeData theme) {
    return TextFormField(
      controller: _financialYearController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Financial Year',
        hintText: 'e.g. 2023-2024',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildCurrencyField(ThemeData theme) {
    return TextFormField(
      controller: _currencyController,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveCompany(saveAndNew: false),
      decoration: InputDecoration(
        labelText: 'Currency',
        hintText: 'e.g. INR',
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
              ? 'Company will be available in dropdowns & billing'
              : 'Company will be inactive and hidden from active lists',
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
              onPressed: _isLoading ? null : () => _saveCompany(saveAndNew: true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save & Add Another'),
            ),
          ],
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isLoading ? null : () => _saveCompany(saveAndNew: false),
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
                : Text(isEditing ? 'Update Company' : 'Save Company'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _isLoading ? null : () => _saveCompany(saveAndNew: false),
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
                : Text(isEditing ? 'Update Company' : 'Save Company'),
          ),
          if (!isEditing) ...[
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _isLoading ? null : () => _saveCompany(saveAndNew: true),
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
