import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';
import '../../models/city.dart';
import '../../models/area.dart';
import '../../models/state_model.dart';
import '../../services/customer_service.dart';
import '../../services/city_service.dart';
import '../../services/area_service.dart';
import '../../services/state_service.dart';
import '../../services/session_service.dart';
import '../../utils/text_formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/city_dropdown.dart';
import '../../widgets/area_dropdown.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';
import '../../widgets/state_dropdown.dart';

/// Customer Master / Add / Edit screen
/// Saves customer data via POST `/api/Customer/InsertorUpdateCustomer`
class CustomerMasterScreen extends StatefulWidget {
  final CustomerListItem? customerToEdit;
  final int? customerId;

  const CustomerMasterScreen({super.key, this.customerToEdit, this.customerId});

  @override
  State<CustomerMasterScreen> createState() => _CustomerMasterScreenState();
}

class _CustomerMasterScreenState extends State<CustomerMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = customerService;
  final StateService _stateService = stateService;
  final CityService _cityService = cityService;
  final AreaService _areaService = areaService;
  final SessionService _sessionService = sessionService;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _altMobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(
    text: 'India',
  );

  // Focus Nodes for keyboard navigation
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _companyFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _altMobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _gstFocusNode = FocusNode();
  final FocusNode _panFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _stateFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _areaFocusNode = FocusNode();
  final FocusNode _pincodeFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();

  int? _selectedStateId;
  String _selectedStateName = '';
  int? _selectedCityId;
  String _selectedCityName = '';
  int? _selectedAreaId;
  String _selectedAreaName = '';

  bool _isActive = true;
  bool _isLoading = false;
  bool _isFetchingDetails = false;
  int _currentEmpId = 0;
  int _custId = 0;

  bool get isEditing => _custId > 0 || widget.customerToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _mobileController.dispose();
    _altMobileController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();

    _nameFocusNode.dispose();
    _companyFocusNode.dispose();
    _mobileFocusNode.dispose();
    _altMobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _gstFocusNode.dispose();
    _panFocusNode.dispose();
    _addressFocusNode.dispose();
    _stateFocusNode.dispose();
    _cityFocusNode.dispose();
    _areaFocusNode.dispose();
    _pincodeFocusNode.dispose();
    _countryFocusNode.dispose();

    super.dispose();
  }

  Future<void> _initUserData() async {
    try {
      final user = await _sessionService.getUserData();
      if (user?.empId != null) {
        _currentEmpId = user!.empId!;
      }
    } catch (_) {}
  }

  void _initFormData() {
    if (widget.customerToEdit != null) {
      _populateCustomerFields(widget.customerToEdit!);
    } else if (widget.customerId != null && widget.customerId! > 0) {
      _fetchCustomerDetails(widget.customerId!);
    } else {
      _isActive = true;
      _countryController.text = 'India';
    }
  }

  Future<void> _fetchCustomerDetails(int custId) async {
    setState(() {
      _isFetchingDetails = true;
    });

    try {
      final cust = await _customerService.getCustomerById(custId);
      if (cust != null && mounted) {
        _populateCustomerFields(cust);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Failed to load customer details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingDetails = false;
        });
      }
    }
  }

  void _populateCustomerFields(CustomerListItem customer) {
    _custId = customer.custId;
    _nameController.text = customer.custName;
    _companyController.text = customer.custCompanyName;
    _mobileController.text = customer.custMobileNo;
    _altMobileController.text = customer.custAlternateMobileNo;
    _emailController.text = customer.custEmail;
    _gstController.text = customer.custGSTNo;
    _panController.text = customer.custPANNo;
    _addressController.text = customer.custAddress;
    _areaController.text = customer.custArea;
    _pincodeController.text = customer.custPincode;
    _countryController.text = customer.custCountry.isNotEmpty
        ? customer.custCountry
        : 'India';
    _isActive = customer.custIsActive;
    _selectedStateName = customer.custState;
    _selectedCityName = customer.custCity;
    _selectedAreaName = customer.custArea;

    _selectedStateId = customer.custStateId > 0 ? customer.custStateId : null;
    _selectedCityId = customer.custCityId > 0 ? customer.custCityId : null;
    _selectedAreaId = customer.custAreaId > 0 ? customer.custAreaId : null;

    // Resolve state ID if available
    if (_selectedStateId == null && customer.custState.isNotEmpty) {
      final matchedState = _stateService.getStateByName(customer.custState);
      if (matchedState != null) {
        _selectedStateId = matchedState.stateId;
      }
    }

    // Resolve city ID if available
    if (_selectedCityId == null && customer.custCity.isNotEmpty) {
      final matchedCity = _cityService.getCityByName(customer.custCity);
      if (matchedCity != null) {
        _selectedCityId = matchedCity.cityId;
        if (_selectedStateId == null && matchedCity.stateId != null) {
          _selectedStateId = matchedCity.stateId;
        }
      }
    }

    // Resolve area ID if available
    if (_selectedAreaId == null && customer.custArea.isNotEmpty) {
      try {
        final matchedArea = _areaService.areas.firstWhere(
          (a) =>
              a.areaName.trim().toLowerCase() ==
              customer.custArea.trim().toLowerCase(),
        );
        _selectedAreaId = matchedArea.areaId;
      } catch (_) {}
    }
  }

  void _focusFirstError() {
    if (_nameController.text.trim().isEmpty || _nameController.text.trim().length < 2) {
      _nameFocusNode.requestFocus();
      return;
    }
    if (_mobileController.text.trim().isEmpty || _mobileController.text.trim().length != 10) {
      _mobileFocusNode.requestFocus();
      return;
    }
    if (_altMobileController.text.trim().isNotEmpty && _altMobileController.text.trim().length != 10) {
      _altMobileFocusNode.requestFocus();
      return;
    }
    if (_emailController.text.trim().isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _emailFocusNode.requestFocus();
      return;
    }
    if (_gstController.text.trim().isNotEmpty && _gstController.text.trim().length != 15) {
      _gstFocusNode.requestFocus();
      return;
    }
    if (_panController.text.trim().isNotEmpty && _panController.text.trim().length != 10) {
      _panFocusNode.requestFocus();
      return;
    }
    if (_pincodeController.text.trim().isNotEmpty && _pincodeController.text.trim().length != 6) {
      _pincodeFocusNode.requestFocus();
      return;
    }
  }

  Future<void> _saveCustomer({bool saveAndNew = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _focusFirstError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int areaId = _selectedAreaId ?? 0;
      int cityId = _selectedCityId ?? 0;
      int stateId = _selectedStateId ?? 0;

      if (stateId == 0 && _selectedStateName.isNotEmpty) {
        final s = _stateService.getStateByName(_selectedStateName);
        if (s != null) stateId = s.stateId;
      }
      if (cityId == 0 && _selectedCityName.isNotEmpty) {
        final c = _cityService.getCityByName(_selectedCityName);
        if (c != null) cityId = c.cityId;
      }
      if (areaId == 0 &&
          (_selectedAreaName.isNotEmpty ||
              _areaController.text.trim().isNotEmpty)) {
        final aName = _selectedAreaName.isNotEmpty
            ? _selectedAreaName
            : _areaController.text.trim();
        try {
          final a = _areaService.areas.firstWhere(
            (item) => item.areaName.trim().toLowerCase() == aName.toLowerCase(),
          );
          areaId = a.areaId;
        } catch (_) {}
      }

      final request = CustomerUpsertRequest(
        custId: isEditing ? _custId : 0,
        custName: _nameController.text.trim(),
        custCompanyName: _companyController.text.trim(),
        custMobileNo: _mobileController.text.trim(),
        custAlternateMobileNo: _altMobileController.text.trim(),
        custEmail: _emailController.text.trim(),
        custGSTNo: _gstController.text.trim().toUpperCase(),
        custPANNo: _panController.text.trim().toUpperCase(),
        custAddress: _addressController.text.trim(),
        custAreaId: areaId,
        custCityId: cityId,
        custStateId: stateId,
        custPincode: _pincodeController.text.trim(),
        custCountry: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : 'India',
        custBranchId: (isEditing && widget.customerToEdit != null && widget.customerToEdit!.custBranchId > 0)
            ? widget.customerToEdit!.custBranchId
            : ((sessionService.selectedBranchId != null && sessionService.selectedBranchId! > 0) ? sessionService.selectedBranchId! : 1),
        custCompId: (isEditing && widget.customerToEdit != null && widget.customerToEdit!.custCompId > 0)
            ? widget.customerToEdit!.custCompId
            : ((sessionService.selectedCompId != null && sessionService.selectedCompId! > 0) ? sessionService.selectedCompId! : 1),
        custIsActive: _isActive,
        custCreatedBy: isEditing ? 0 : _currentEmpId,
        custModifiedBy: _currentEmpId,
      );

      final response = await _customerService.insertOrUpdateCustomer(request);

      if (!mounted) return;

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing
                ? 'Customer updated successfully!'
                : 'Customer created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _companyController.clear();
        _mobileController.clear();
        _altMobileController.clear();
        _emailController.clear();
        _gstController.clear();
        _panController.clear();
        _addressController.clear();
        _areaController.clear();
        _pincodeController.clear();
        _countryController.text = 'India';

        setState(() {
          _selectedStateId = null;
          _selectedStateName = '';
          _selectedCityId = null;
          _selectedCityName = '';
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
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) {
          _saveCustomer(saveAndNew: false);
        }
      },
      onClear: () {
        if (!_isLoading) {
          _formKey.currentState?.reset();
          _nameController.clear();
          _companyController.clear();
          _mobileController.clear();
          _altMobileController.clear();
          _emailController.clear();
          _gstController.clear();
          _panController.clear();
          _addressController.clear();
          _areaController.clear();
          _pincodeController.clear();
          _countryController.text = 'India';

          setState(() {
            _selectedStateId = null;
            _selectedStateName = '';
            _selectedCityId = null;
            _selectedCityName = '';
            _selectedAreaId = null;
            _selectedAreaName = '';
            _isActive = true;
          });
          _nameFocusNode.requestFocus();
        }
      },
      child: DirectBackScope(
        child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (_isFetchingDetails) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading customer details...'),
                  ],
                ),
              ),
            );
          }

          final formContent = _buildFormCard(context, isDesktop);

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
                        title: Text(
                          isEditing ? 'Edit Customer' : 'Add New Customer',
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Customer List',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.12),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 24,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 860,
                                    ),
                                    child: formContent,
                                  ),
                                ),
                              ),
                            ),
                            _buildStickyActionBar(context, isDesktop),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Mobile / Tablet View
          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: formContent,
                  ),
                ),
                _buildStickyActionBar(context, isDesktop),
              ],
            ),
          );
        },
      ),
    ));
  }

  Widget _buildFormCard(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Customer & Business Info
          _buildCardSection(
            context,
            title: 'Basic & Business Information',
            icon: Icons.person_outline_rounded,
            color: Colors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCustomerNameField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCompanyNameField()),
                    ],
                  ),
                ] else ...[
                  _buildCustomerNameField(),
                  const SizedBox(height: 14),
                  _buildCompanyNameField(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 2: Contact Info
          _buildCardSection(
            context,
            title: 'Contact Details',
            icon: Icons.phone_outlined,
            color: Colors.teal,
            child: Column(
              children: [
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMobileField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildAltMobileField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                ] else ...[
                  _buildMobileField(),
                  const SizedBox(height: 14),
                  _buildAltMobileField(),
                  const SizedBox(height: 14),
                  _buildEmailField(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 3: Tax & Identification Details
          _buildCardSection(
            context,
            title: 'Tax & Identification Details',
            icon: Icons.badge_outlined,
            color: Colors.indigo,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildGstField()),
                const SizedBox(width: 16),
                Expanded(child: _buildPanField()),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 4: Address & Geographical Details
          _buildCardSection(
            context,
            title: 'Address & Geographical Location',
            icon: Icons.location_on_outlined,
            color: Colors.deepOrange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAddressField(),
                const SizedBox(height: 12),
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: StateDropdown(
                          selectedStateId: _selectedStateId,
                          focusNode: _stateFocusNode,
                          nextFocusNode: _cityFocusNode,
                          labelText: 'State',
                          hintText: 'Select State',
                          onChanged: (StateModel? state) {
                            setState(() {
                              _selectedStateId = state?.stateId;
                              _selectedStateName = state?.stateName ?? '';
                              _selectedCityId = null;
                              _selectedCityName = '';
                              _selectedAreaId = null;
                              _selectedAreaName = '';
                              _areaController.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CityDropdown(
                          selectedCityId: _selectedCityId,
                          stateId: _selectedStateId,
                          focusNode: _cityFocusNode,
                          nextFocusNode: _areaFocusNode,
                          labelText: 'City',
                          hintText: 'Select City',
                          onChanged: (CityListItem? city) {
                            setState(() {
                              _selectedCityId = city?.cityId;
                              _selectedCityName = city?.cityName ?? '';
                              _selectedAreaId = null;
                              _selectedAreaName = '';
                              _areaController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAreaField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPincodeField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCountryField()),
                    ],
                  ),
                ] else ...[
                  StateDropdown(
                    selectedStateId: _selectedStateId,
                    focusNode: _stateFocusNode,
                    nextFocusNode: _cityFocusNode,
                    labelText: 'State',
                    hintText: 'Select State',
                    onChanged: (StateModel? state) {
                      setState(() {
                        _selectedStateId = state?.stateId;
                        _selectedStateName = state?.stateName ?? '';
                        _selectedCityId = null;
                        _selectedCityName = '';
                        _selectedAreaId = null;
                        _selectedAreaName = '';
                        _areaController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CityDropdown(
                    selectedCityId: _selectedCityId,
                    stateId: _selectedStateId,
                    focusNode: _cityFocusNode,
                    nextFocusNode: _areaFocusNode,
                    labelText: 'City',
                    hintText: 'Select City',
                    onChanged: (CityListItem? city) {
                      setState(() {
                        _selectedCityId = city?.cityId;
                        _selectedCityName = city?.cityName ?? '';
                        _selectedAreaId = null;
                        _selectedAreaName = '';
                        _areaController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAreaField(),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPincodeField()),
                      const SizedBox(width: 14),
                      Expanded(child: _buildCountryField()),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section 5: Status Switch
          Card(
            elevation: isDesktop ? 2 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isActive ? Colors.green : Colors.grey)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isActive
                          ? Icons.check_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: _isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isActive
                              ? 'Active - Can place orders, bills, and transactions'
                              : 'Inactive - Temporarily disabled for new billing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: Colors.green,
                    onChanged: _isLoading
                        ? null
                        : (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStickyActionBar(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withOpacity(0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 12,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 860 : double.infinity,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _saveCustomer(saveAndNew: true),
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text('Save & Add Another'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _saveCustomer(saveAndNew: false),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isEditing
                                  ? Icons.save_rounded
                                  : Icons.check_circle_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isLoading
                            ? 'Saving...'
                            : (isEditing ? 'Update Customer' : 'Save Customer'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required MaterialColor color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (isDark ? color.shade900 : color.shade50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isDark ? color.shade700 : color.shade200),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? color.shade200 : color.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      inputFormatters: const [
        CapitalizeWordsInputFormatter(),
      ],
      onFieldSubmitted: (_) => _companyFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Customer Name *',
        hintText: 'Enter full name',
        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter customer name';
        }
        if (val.trim().length < 2) {
          return 'Customer name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyNameField() {
    return TextFormField(
      controller: _companyController,
      focusNode: _companyFocusNode,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      inputFormatters: const [
        CapitalizeWordsInputFormatter(),
      ],
      onFieldSubmitted: (_) => _mobileFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Company / Business Name',
        hintText: 'e.g. Acme Enterprises',
        prefixIcon: const Icon(Icons.business_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      controller: _mobileController,
      focusNode: _mobileFocusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onFieldSubmitted: (_) => _altMobileFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Mobile Number *',
        hintText: '10-digit mobile number',
        prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
        prefixText: '+91 ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter mobile number';
        }
        if (val.trim().length != 10) {
          return 'Mobile number must be 10 digits';
        }
        return null;
      },
    );
  }

  Widget _buildAltMobileField() {
    return TextFormField(
      controller: _altMobileController,
      focusNode: _altMobileFocusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Alternate Mobile',
        hintText: 'Optional contact number',
        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val != null && val.trim().isNotEmpty && val.trim().length != 10) {
          return 'Alternate number must be 10 digits';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _gstFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'e.g. customer@example.com',
        prefixIcon: const Icon(Icons.email_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val != null && val.trim().isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(val.trim())) {
            return 'Please enter a valid email address';
          }
        }
        return null;
      },
    );
  }

  Widget _buildGstField() {
    return TextFormField(
      controller: _gstController,
      focusNode: _gstFocusNode,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [LengthLimitingTextInputFormatter(15)],
      onFieldSubmitted: (_) => _panFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'GSTIN',
        hintText: '15-character GST Number',
        prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val != null && val.trim().isNotEmpty) {
          if (val.trim().length != 15) {
            return 'GSTIN must be 15 characters';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPanField() {
    return TextFormField(
      controller: _panController,
      focusNode: _panFocusNode,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [LengthLimitingTextInputFormatter(10)],
      onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'PAN Number',
        hintText: '10-character PAN Number',
        prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val != null && val.trim().isNotEmpty) {
          if (val.trim().length != 10) {
            return 'PAN must be 10 characters';
          }
        }
        return null;
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      focusNode: _addressFocusNode,
      textInputAction: TextInputAction.next,
      maxLines: 2,
      onFieldSubmitted: (_) => _stateFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Street Address',
        hintText: 'Building, Street, Landmark...',
        prefixIcon: const Icon(Icons.home_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAreaField() {
    return AreaDropdown(
      selectedAreaId: _selectedAreaId,
      selectedAreaName: _selectedAreaName.isNotEmpty
          ? _selectedAreaName
          : _areaController.text,
      cityId: _selectedCityId,
      stateId: _selectedStateId,
      focusNode: _areaFocusNode,
      nextFocusNode: _pincodeFocusNode,
      labelText: 'Area / Locality',
      hintText: 'Select Area',
      onChanged: (AreaListItem? area) {
        setState(() {
          _selectedAreaId = area?.areaId;
          _selectedAreaName = area?.areaName ?? '';
          _areaController.text = area?.areaName ?? '';
          if (area != null && area.areaPincode.isNotEmpty) {
            _pincodeController.text = area.areaPincode;
          }
          if (area != null &&
              _selectedCityId == null &&
              area.cityId != null &&
              area.cityId! > 0) {
            _selectedCityId = area.cityId;
            _selectedCityName = area.cityName;
          }
          if (area != null &&
              _selectedStateId == null &&
              area.stateId != null &&
              area.stateId! > 0) {
            _selectedStateId = area.stateId;
            _selectedStateName = area.stateName;
          }
        });
      },
    );
  }

  Widget _buildPincodeField() {
    return TextFormField(
      controller: _pincodeController,
      focusNode: _pincodeFocusNode,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onFieldSubmitted: (_) => _countryFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Pincode',
        hintText: '6-digit PIN',
        prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (val != null && val.trim().isNotEmpty && val.trim().length != 6) {
          return 'Pincode must be 6 digits';
        }
        return null;
      },
    );
  }

  Widget _buildCountryField() {
    return TextFormField(
      controller: _countryController,
      focusNode: _countryFocusNode,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveCustomer(),
      decoration: InputDecoration(
        labelText: 'Country',
        hintText: 'e.g. India',
        prefixIcon: const Icon(Icons.public_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
