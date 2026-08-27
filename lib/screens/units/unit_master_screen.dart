import 'package:flutter/material.dart';
import '../../models/unit.dart';
import '../../services/unit_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';

/// Screen to Insert or Update Unit details via `/api/Unit/InsertorUpdateUnit`
class UnitMasterScreen extends StatefulWidget {
  final UnitListItem? unitToEdit;

  const UnitMasterScreen({super.key, this.unitToEdit});

  @override
  State<UnitMasterScreen> createState() => _UnitMasterScreenState();
}

class _UnitMasterScreenState extends State<UnitMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final UnitService _unitService = unitService;
  final SessionService _sessionService = sessionService;

  final TextEditingController _unitNameController = TextEditingController();
  final TextEditingController _unitShortNameController =
      TextEditingController();
  final FocusNode _unitNameFocusNode = FocusNode();
  final FocusNode _unitShortNameFocusNode = FocusNode();

  bool _isActive = true;
  bool _isLoading = false;
  int _currentEmpId = 0;

  bool get isEditing => widget.unitToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _initFormData();

    // Automatically focus on the Unit Name when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _unitNameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _unitShortNameController.dispose();
    _unitNameFocusNode.dispose();
    _unitShortNameFocusNode.dispose();
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
    if (widget.unitToEdit != null) {
      final unit = widget.unitToEdit!;
      _unitNameController.text = unit.unitName;
      _unitShortNameController.text = unit.unitShortName;
      _isActive = unit.unitIsActive;
    } else {
      _isActive = true;
    }
  }

  Future<void> _saveUnit({bool saveAndNew = false}) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = UnitUpsertRequest(
        unitId: isEditing ? widget.unitToEdit!.unitId : 0,
        unitName: _unitNameController.text.trim(),
        unitShortName: _unitShortNameController.text.trim(),
        unitIsActive: _isActive,
        unitCreatedBy: isEditing ? 0 : _currentEmpId,
        unitModifiedBy: _currentEmpId,
      );

      final response = await _unitService.insertOrUpdateUnit(request);

      if (!mounted) return;

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing
                ? 'Unit updated successfully!'
                : 'Unit created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _unitNameController.clear();
        _unitShortNameController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _unitNameFocusNode.requestFocus();
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
          _saveUnit(saveAndNew: false);
        }
      },
      onClear: () {
        if (!isEditing) {
          _formKey.currentState?.reset();
          _unitNameController.clear();
          _unitShortNameController.clear();
          setState(() {
            _isActive = true;
          });
          _unitNameFocusNode.requestFocus();
        }
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
                          title: Text(isEditing ? 'Edit Unit' : 'Add New Unit'),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to Unit List',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        body: Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.15),
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 680,
                                ),
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
                title: Text(isEditing ? 'Edit Unit' : 'Add New Unit'),
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
                      Icons.straighten_rounded,
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
                              ? 'Update Unit Details'
                              : 'Create Unit Master',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Modify unit information'
                              : 'Add a new unit for measurement and billing',
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${widget.unitToEdit!.unitId}',
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

              // Unit Name Input Field
              TextFormField(
                controller: _unitNameController,
                focusNode: _unitNameFocusNode,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _unitShortNameFocusNode.requestFocus(),
                decoration: InputDecoration(
                  labelText: 'Unit Name *',
                  hintText: 'Enter unit name (e.g. Kilogram, Box)',
                  prefixIcon: const Icon(
                    Icons.straighten_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit name';
                  }
                  if (value.trim().length < 2) {
                    return 'Unit name must be at least 2 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'Unit name cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Unit Short Name Input Field
              TextFormField(
                controller: _unitShortNameController,
                focusNode: _unitShortNameFocusNode,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveUnit(saveAndNew: false),
                decoration: InputDecoration(
                  labelText: 'Unit Short Name *',
                  hintText: 'Enter short name (e.g. KG, PCS)',
                  prefixIcon: const Icon(
                    Icons.short_text_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter short name';
                  }
                  if (value.trim().length > 20) {
                    return 'Short name cannot exceed 20 characters';
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
                        ? 'Unit will be available in dropdowns & billing'
                        : 'Unit will be inactive and hidden from active lists',
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: _isLoading
                            ? null
                            : () => _saveUnit(saveAndNew: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save & Add Another'),
                      ),
                    ],
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () => _saveUnit(saveAndNew: false),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Update Unit' : 'Save Unit'),
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
                          : () => _saveUnit(saveAndNew: false),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Update Unit' : 'Save Unit'),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed: _isLoading
                            ? null
                            : () => _saveUnit(saveAndNew: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save & Add Another'),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
