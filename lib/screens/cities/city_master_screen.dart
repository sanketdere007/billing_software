import 'package:flutter/material.dart';
import '../../models/city.dart';
import '../../models/state_model.dart';
import '../../services/city_service.dart';
import '../../services/state_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/state_dropdown.dart';
import '../../widgets/save_clear_shortcuts.dart';

/// Screen to Insert or Update City details via `/api/City/InsertorUpdateCity`
class CityMasterScreen extends StatefulWidget {
  final CityListItem? cityToEdit;

  const CityMasterScreen({super.key, this.cityToEdit});

  @override
  State<CityMasterScreen> createState() => _CityMasterScreenState();
}

class _CityMasterScreenState extends State<CityMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final CityService _cityService = cityService;
  final StateService _stateService = stateService;
  final SessionService _sessionService = sessionService;

  final TextEditingController _cityNameController = TextEditingController();
  final FocusNode _stateFocusNode = FocusNode();
  final FocusNode _cityNameFocusNode = FocusNode();

  int? _selectedStateId;
  String? _selectedStateName;
  bool _isActive = true;
  bool _isLoading = false;
  int _currentEmpId = 0;

  bool get isEditing => widget.cityToEdit != null;

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
    _cityNameController.dispose();
    _stateFocusNode.dispose();
    _cityNameFocusNode.dispose();
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
    if (widget.cityToEdit != null) {
      final city = widget.cityToEdit!;
      _cityNameController.text = city.cityName;
      _isActive = city.cityIsActive;
      _selectedStateName = city.stateName;

      if (city.stateId != null && city.stateId! > 0) {
        _selectedStateId = city.stateId;
      } else {
        // Try matching state from StateService cache by name
        final matchedState = _stateService.getStateByName(city.stateName);
        if (matchedState != null) {
          _selectedStateId = matchedState.stateId;
        }
      }
    } else {
      _isActive = true;
    }
  }

  Future<void> _saveCity({bool saveAndNew = false}) async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CityUpsertRequest(
        cityId: isEditing ? widget.cityToEdit!.cityId : 0,
        cityStateId: _selectedStateId!,
        cityName: _cityNameController.text.trim(),
        cityIsActive: _isActive,
        cityCreatedBy: isEditing ? 0 : _currentEmpId,
        cityModifiedBy: _currentEmpId,
      );

      final response = await _cityService.insertOrUpdateCity(request);

      if (!mounted) return;

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing ? 'City updated successfully!' : 'City created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _cityNameController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _stateFocusNode.requestFocus();
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
        if (!_isLoading) _saveCity(saveAndNew: false);
      },
      onClear: () {
        _formKey.currentState?.reset();
        _cityNameController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _stateFocusNode.requestFocus();
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
                        title: Text(isEditing ? 'Edit City' : 'Add New City'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to City List',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
              title: Text(isEditing ? 'Edit City' : 'Add New City'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: formCard,
            ),
          );
        },
      ),
    ));
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
                      Icons.location_city_rounded,
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
                          isEditing ? 'Update City Details' : 'Create City Master',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Modify city information and state association'
                              : 'Add a new city linked to a state for location management',
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
                        'ID: ${widget.cityToEdit!.cityId}',
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
                nextFocusNode: _cityNameFocusNode,
                autofocus: true,
                selectedStateId: _selectedStateId,
                labelText: 'Select State',
                hintText: _selectedStateName ?? 'Choose a state',
                isRequired: true,
                prefixIcon: const Icon(Icons.map_rounded, size: 20, color: Colors.blueAccent),
                onChanged: (StateModel? state) {
                  setState(() {
                    _selectedStateId = state?.stateId;
                    _selectedStateName = state?.stateName;
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

              // City Name Input Field
              TextFormField(
                controller: _cityNameController,
                focusNode: _cityNameFocusNode,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveCity(saveAndNew: false),
                decoration: InputDecoration(
                  labelText: 'City Name *',
                  hintText: 'Enter city name (e.g. Mumbai, Pune)',
                  prefixIcon: const Icon(Icons.apartment_rounded, size: 20, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter city name';
                  }
                  if (value.trim().length < 2) {
                    return 'City name must be at least 2 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'City name cannot exceed 100 characters';
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
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'City will be available in dropdowns & billing'
                        : 'City will be inactive and hidden from active lists',
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
              ),
              const SizedBox(height: 28),

              // Action Buttons
              if (isDesktop)
                Row(
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
                        onPressed: _isLoading ? null : () => _saveCity(saveAndNew: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save & Add Another'),
                      ),
                    ],
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : () => _saveCity(saveAndNew: false),
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
                          : Text(isEditing ? 'Update City' : 'Save City'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isLoading ? null : () => _saveCity(saveAndNew: false),
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
                          : Text(isEditing ? 'Update City' : 'Save City'),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed: _isLoading ? null : () => _saveCity(saveAndNew: true),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
