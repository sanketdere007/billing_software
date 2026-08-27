import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/area.dart';
import '../../models/city.dart';
import '../../models/state_model.dart';
import '../../services/area_service.dart';
import '../../services/city_service.dart';
import '../../services/state_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/city_dropdown.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';
import '../../widgets/state_dropdown.dart';

/// Screen to Insert or Update Area details via `/api/Area/InsertorUpdateArea`
class AreaMasterScreen extends StatefulWidget {
  final AreaListItem? areaToEdit;

  const AreaMasterScreen({super.key, this.areaToEdit});

  @override
  State<AreaMasterScreen> createState() => _AreaMasterScreenState();
}

class _AreaMasterScreenState extends State<AreaMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AreaService _areaService = areaService;
  final CityService _cityService = cityService;
  final StateService _stateService = stateService;
  final SessionService _sessionService = sessionService;

  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  final FocusNode _stateFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _areaNameFocusNode = FocusNode();
  final FocusNode _pincodeFocusNode = FocusNode();

  int? _selectedStateId;
  String? _selectedStateName;
  int? _selectedCityId;
  String? _selectedCityName;
  bool _isActive = true;
  bool _isLoading = false;
  int _currentEmpId = 0;

  bool get isEditing => widget.areaToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _initFormData();

    // Automatically focus on the State Dropdown when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _stateFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    _pincodeController.dispose();
    _stateFocusNode.dispose();
    _cityFocusNode.dispose();
    _areaNameFocusNode.dispose();
    _pincodeFocusNode.dispose();
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
    if (widget.areaToEdit != null) {
      final area = widget.areaToEdit!;
      _areaNameController.text = area.areaName;
      _pincodeController.text = area.areaPincode;
      _isActive = area.areaIsActive;
      _selectedStateName = area.stateName;
      _selectedCityName = area.cityName;

      // State ID resolution
      if (area.stateId != null && area.stateId! > 0) {
        _selectedStateId = area.stateId;
      } else {
        final matchedState = _stateService.getStateByName(area.stateName);
        if (matchedState != null) {
          _selectedStateId = matchedState.stateId;
        }
      }

      // City ID resolution
      if (area.cityId != null && area.cityId! > 0) {
        _selectedCityId = area.cityId;
      } else {
        final matchedCity = _cityService.getCityByName(area.cityName);
        if (matchedCity != null) {
          _selectedCityId = matchedCity.cityId;
          if (_selectedStateId == null && matchedCity.stateId != null) {
            _selectedStateId = matchedCity.stateId;
          }
        }
      }
    } else {
      _isActive = true;
    }
  }

  Future<void> _saveArea({bool saveAndNew = false}) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStateId == null || _selectedStateId! <= 0) {
      await showWarningDialog(context, 'Please select a valid state.');
      _stateFocusNode.requestFocus();
      return;
    }

    if (_selectedCityId == null || _selectedCityId! <= 0) {
      await showWarningDialog(context, 'Please select a valid city.');
      _cityFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = AreaUpsertRequest(
        areaId: isEditing ? widget.areaToEdit!.areaId : 0,
        areaStateId: _selectedStateId!,
        areaCityId: _selectedCityId!,
        areaName: _areaNameController.text.trim(),
        areaPincode: _pincodeController.text.trim(),
        areaIsActive: _isActive,
        areaCreatedBy: isEditing ? 0 : _currentEmpId,
        areaModifiedBy: _currentEmpId,
      );

      final response = await _areaService.insertOrUpdateArea(request);

      if (!mounted) return;

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing
              ? 'Area updated successfully!'
              : 'Area created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _areaNameController.clear();
        _pincodeController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _areaNameFocusNode.requestFocus();
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
        if (!_isLoading) _saveArea(saveAndNew: false);
      },
      onClear: () {
        _formKey.currentState?.reset();
        _areaNameController.clear();
        _pincodeController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _areaNameFocusNode.requestFocus();
      },
      child: DirectBackScope(
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
                        title: Text(isEditing ? 'Edit Area' : 'Add New Area'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Area List',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.15),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
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

          // Mobile / Tablet layout
          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit Area' : 'Add New Area'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: formCard,
            ),
          );
        },
      ),
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
              // Header with icon and description
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.place_rounded,
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
                          isEditing
                              ? 'Update Area Details'
                              : 'Create Area Master',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Modify area information, pincode, and city association'
                              : 'Add a new area linked to a state & city for customer & delivery management',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${widget.areaToEdit!.areaId}',
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

              // Reusable State Dropdown
              StateDropdown(
                focusNode: _stateFocusNode,
                nextFocusNode: _cityFocusNode,
                autofocus: true,
                selectedStateId: _selectedStateId,
                labelText: 'Select State',
                hintText: _selectedStateName ?? 'Choose a state',
                isRequired: true,
                prefixIcon: const Icon(Icons.map_rounded,
                    size: 20, color: Colors.blueAccent),
                onChanged: (StateModel? state) {
                  setState(() {
                    _selectedStateId = state?.stateId;
                    _selectedStateName = state?.stateName;
                    // Reset selected city if state changes
                    _selectedCityId = null;
                    _selectedCityName = null;
                  });
                },
                validator: (state) {
                  if (_selectedStateId == null || _selectedStateId! <= 0) {
                    return 'Please select a state';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Reusable City Dropdown (Filtered by selected state)
              CityDropdown(
                focusNode: _cityFocusNode,
                nextFocusNode: _areaNameFocusNode,
                selectedCityId: _selectedCityId,
                stateId: _selectedStateId,
                labelText: 'Select City',
                hintText: _selectedCityName ?? 'Choose a city',
                isRequired: true,
                prefixIcon: const Icon(Icons.location_city_rounded,
                    size: 20, color: Colors.blueAccent),
                onChanged: (CityListItem? city) {
                  setState(() {
                    _selectedCityId = city?.cityId;
                    _selectedCityName = city?.cityName;
                    if (city != null &&
                        city.stateId != null &&
                        city.stateId! > 0 &&
                        _selectedStateId == null) {
                      _selectedStateId = city.stateId;
                      _selectedStateName = city.stateName;
                    }
                  });
                },
                validator: (city) {
                  if (_selectedCityId == null || _selectedCityId! <= 0) {
                    return 'Please select a city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Area Name Input Field
              TextFormField(
                controller: _areaNameController,
                focusNode: _areaNameFocusNode,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _pincodeFocusNode.requestFocus(),
                decoration: InputDecoration(
                  labelText: 'Area Name *',
                  hintText: 'Enter area or locality name (e.g. Andheri West)',
                  prefixIcon: const Icon(Icons.place_outlined,
                      size: 20, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter area name';
                  }
                  if (value.trim().length < 2) {
                    return 'Area name must be at least 2 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'Area name cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Pincode Input Field
              TextFormField(
                controller: _pincodeController,
                focusNode: _pincodeFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onFieldSubmitted: (_) => _saveArea(saveAndNew: false),
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  hintText: 'Enter postal/pin code (e.g. 400053)',
                  prefixIcon: const Icon(Icons.pin_drop_outlined,
                      size: 20, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 3) {
                      return 'Pincode must be at least 3 digits';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Active Status Switch Tile
              Container(
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
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Area will be available in customer addresses & dropdowns'
                        : 'Area will be inactive and hidden from active lists',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  secondary: Icon(
                    _isActive
                        ? Icons.check_circle_outline_rounded
                        : Icons.block_rounded,
                    color: _isActive ? Colors.green : Colors.grey,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: _isLoading
                            ? null
                            : () => _saveArea(saveAndNew: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save & Add Another'),
                      ),
                    ],
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () => _saveArea(saveAndNew: false),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Update Area' : 'Save Area'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () => _saveArea(saveAndNew: false),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Update Area' : 'Save Area'),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed: _isLoading
                            ? null
                            : () => _saveArea(saveAndNew: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save & Add Another'),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
