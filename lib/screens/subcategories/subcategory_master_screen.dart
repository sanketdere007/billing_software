import 'package:flutter/material.dart';
import '../../models/subcategory.dart';
import '../../models/category.dart';
import '../../services/subcategory_service.dart';
import '../../services/category_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';

/// Screen to Insert or Update SubCategory details
class SubCategoryMasterScreen extends StatefulWidget {
  final SubCategoryListItem? subcategoryToEdit;

  const SubCategoryMasterScreen({super.key, this.subcategoryToEdit});

  @override
  State<SubCategoryMasterScreen> createState() => _SubCategoryMasterScreenState();
}

class _SubCategoryMasterScreenState extends State<SubCategoryMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubCategoryService _subcategoryService = subcategoryService;
  final CategoryService _categoryService = categoryService;
  final SessionService _sessionService = sessionService;

  final TextEditingController _subCategoryNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isActive = true;
  bool _isLoading = false;
  int _currentEmpId = 0;
  List<CategoryListItem> _categories = [];

  bool get isEditing => widget.subcategoryToEdit != null;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _fetchCategories();

    // Automatically focus on the Category Dropdown when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _categoryFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _subCategoryNameController.dispose();
    _descriptionController.dispose();
    _categoryFocusNode.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
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

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryService.getAllCategories(isActive: true);
      if (mounted) {
        setState(() {
          _categories = categories;
          _initFormData();
        });
      }
    } catch (_) {
      if (mounted) {
        _initFormData();
      }
    }
  }

  void _initFormData() {
    if (widget.subcategoryToEdit != null) {
      final subcategory = widget.subcategoryToEdit!;
      _subCategoryNameController.text = subcategory.subCatName;
      _descriptionController.text = subcategory.subCatDescription;
      _isActive = subcategory.subCatIsActive;
      _selectedCategoryName = subcategory.catName;

      if (subcategory.subCatCatId > 0) {
        _selectedCategoryId = subcategory.subCatCatId;
      } else {
        // Try matching category by name if ID is somehow missing
        try {
          final matchedCategory = _categories.firstWhere((c) => c.catName == subcategory.catName);
          _selectedCategoryId = matchedCategory.catId;
        } catch (_) {}
      }
    } else {
      _isActive = true;
    }
  }

  Future<void> _saveSubCategory({bool saveAndNew = false}) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId! <= 0) {
      await showWarningDialog(context, 'Please select a valid category.');
      _categoryFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = SubCategoryUpsertRequest(
        subCatId: isEditing ? widget.subcategoryToEdit!.subCatId : 0,
        subCatCatId: _selectedCategoryId!,
        subCatName: _subCategoryNameController.text.trim(),
        subCatDescription: _descriptionController.text.trim(),
        subCatIsActive: _isActive,
        subCatCreatedBy: isEditing ? 0 : _currentEmpId,
        subCatModifiedBy: _currentEmpId,
      );

      final response = await _subcategoryService.insertOrUpdateSubCategory(request);

      if (!mounted) return;

      final successMsg = response.message.isNotEmpty
          ? response.message
          : (isEditing ? 'SubCategory updated successfully!' : 'SubCategory created successfully!');

      await showSuccessDialog(context, successMsg);
      if (!mounted) return;

      if (saveAndNew && !isEditing) {
        _formKey.currentState?.reset();
        _subCategoryNameController.clear();
        _descriptionController.clear();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
        _categoryFocusNode.requestFocus();
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
          _saveSubCategory(saveAndNew: false);
        }
      },
      onClear: () {
        if (!isEditing) {
          _formKey.currentState?.reset();
          _subCategoryNameController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedCategoryId = null;
            _selectedCategoryName = null;
            _isActive = true;
          });
          _categoryFocusNode.requestFocus();
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
                        title: Text(isEditing ? 'Edit SubCategory' : 'Add New SubCategory'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to SubCategory List',
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
              title: Text(isEditing ? 'Edit SubCategory' : 'Add New SubCategory'),
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
                      Icons.category_rounded,
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
                          isEditing ? 'Update SubCategory Details' : 'Create SubCategory Master',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Modify subcategory information and category association'
                              : 'Add a new subcategory linked to a category for management',
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
                        'ID: ${widget.subcategoryToEdit!.subCatId}',
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

              // Category Dropdown
              DropdownButtonFormField<int>(
                focusNode: _categoryFocusNode,
                value: _selectedCategoryId,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Select Category *',
                  hintText: _selectedCategoryName ?? 'Choose a category',
                  prefixIcon: const Icon(Icons.folder_open_rounded, size: 20, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.catId,
                    child: Text(c.catName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    if (value != null) {
                      _selectedCategoryName = _categories.firstWhere((c) => c.catId == value).catName;
                    }
                  });
                  _nameFocusNode.requestFocus();
                },
                validator: (value) {
                  if (value == null || value <= 0) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // SubCategory Name Input Field
              TextFormField(
                controller: _subCategoryNameController,
                focusNode: _nameFocusNode,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _descriptionFocusNode.requestFocus(),
                decoration: InputDecoration(
                  labelText: 'SubCategory Name *',
                  hintText: 'Enter subcategory name',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter subcategory name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'Name cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Description Input Field
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveSubCategory(saveAndNew: false),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter optional description',
                  prefixIcon: const Icon(Icons.description_rounded, size: 20, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
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
                        ? 'SubCategory will be available in dropdowns'
                        : 'SubCategory will be inactive and hidden',
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
                        onPressed: _isLoading ? null : () => _saveSubCategory(saveAndNew: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save & Add Another'),
                      ),
                    ],
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : () => _saveSubCategory(saveAndNew: false),
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
                          : Text(isEditing ? 'Update SubCategory' : 'Save SubCategory'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isLoading ? null : () => _saveSubCategory(saveAndNew: false),
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
                          : Text(isEditing ? 'Update SubCategory' : 'Save SubCategory'),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed: _isLoading ? null : () => _saveSubCategory(saveAndNew: true),
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
