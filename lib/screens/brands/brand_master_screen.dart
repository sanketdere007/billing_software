import 'package:flutter/material.dart';
import '../../models/brand.dart';
import '../../services/brand_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';

/// Screen to Insert or Update Brand details
class BrandMasterScreen extends StatefulWidget {
  final BrandListItem? brandToEdit; // Using brandToEdit to match UI parameter passing from list screen

  const BrandMasterScreen({super.key, this.brandToEdit});

  @override
  State<BrandMasterScreen> createState() => _BrandMasterScreenState();
}

class _BrandMasterScreenState extends State<BrandMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final BrandService _brandService = brandService;
  final SessionService _sessionService = sessionService;

  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _brandDescriptionController = TextEditingController();
  final FocusNode _brandNameFocusNode = FocusNode();
  final FocusNode _brandDescriptionFocusNode = FocusNode();

  bool _isActive = true;
  bool _isLoading = false;
  int _currentEmpId = 0;

  bool get isEditing => widget.brandToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _brandNameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _brandDescriptionController.dispose();
    _brandNameFocusNode.dispose();
    _brandDescriptionFocusNode.dispose();
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
    if (widget.brandToEdit != null) {
      final brand = widget.brandToEdit!;
      _brandNameController.text = brand.brandName;
      _brandDescriptionController.text = brand.brandDescription;
      _isActive = brand.brandIsActive;
    } else {
      _isActive = true;
    }
  }

  Future<void> _saveBrand({bool saveAndNew = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = BrandUpsertRequest(
        brandId: isEditing ? widget.brandToEdit!.brandId : 0,
        brandName: _brandNameController.text.trim(),
        brandDescription: _brandDescriptionController.text.trim(),
        brandIsActive: _isActive,
        brandCreatedBy: isEditing ? 0 : _currentEmpId,
        brandModifiedBy: _currentEmpId,
      );

      final response = await _brandService.insertOrUpdateBrand(request);

      if (!mounted) return;

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing ? 'Brand updated successfully!' : 'Brand created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _brandNameController.clear();
        _brandDescriptionController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _brandNameFocusNode.requestFocus();
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
        if (!_isLoading) _saveBrand(saveAndNew: false);
      },
      onClear: () {
        _formKey.currentState?.reset();
        _brandNameController.clear();
        _brandDescriptionController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _brandNameFocusNode.requestFocus();
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
                        title: Text(isEditing ? 'Edit Brand' : 'Add New Brand'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Brand List',
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

          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit Brand' : 'Add New Brand'),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.branding_watermark_rounded,
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
                          isEditing ? 'Update Brand Details' : 'Create Brand Master',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Modify brand information'
                              : 'Add a new brand for product management',
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
                        'ID: ${widget.brandToEdit!.brandId}',
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

              TextFormField(
                controller: _brandNameController,
                focusNode: _brandNameFocusNode,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _brandDescriptionFocusNode.requestFocus(),
                decoration: InputDecoration(
                  labelText: 'Brand Name *',
                  hintText: 'Enter brand name',
                  prefixIcon: const Icon(Icons.apartment_rounded, size: 20, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter brand name';
                  }
                  if (value.trim().length < 2) {
                    return 'Brand name must be at least 2 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'Brand name cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _brandDescriptionController,
                focusNode: _brandDescriptionFocusNode,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                onFieldSubmitted: (_) => _saveBrand(saveAndNew: false),
                decoration: InputDecoration(
                  labelText: 'Brand Description',
                  hintText: 'Enter brand description',
                  prefixIcon: const Icon(Icons.description_rounded, size: 20, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 18),

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
                        ? 'Brand will be available in dropdowns & billing'
                        : 'Brand will be inactive and hidden from active lists',
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
                        onPressed: _isLoading ? null : () => _saveBrand(saveAndNew: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save & Add Another'),
                      ),
                    ],
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : () => _saveBrand(saveAndNew: false),
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
                          : Text(isEditing ? 'Update Brand' : 'Save Brand'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isLoading ? null : () => _saveBrand(saveAndNew: false),
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
                          : Text(isEditing ? 'Update Brand' : 'Save Brand'),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed: _isLoading ? null : () => _saveBrand(saveAndNew: true),
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
