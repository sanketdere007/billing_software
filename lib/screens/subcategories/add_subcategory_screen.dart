import 'package:flutter/material.dart';
import '../../models/subcategory.dart';
import '../../models/category.dart';
import '../../services/subcategory_service.dart';
import '../../services/category_service.dart';
import '../../widgets/app_drawer.dart';

class AddSubcategoryScreen extends StatefulWidget {
  final Subcategory? subcategoryToEdit;

  const AddSubcategoryScreen({super.key, this.subcategoryToEdit});

  @override
  State<AddSubcategoryScreen> createState() => _AddSubcategoryScreenState();
}

class _AddSubcategoryScreenState extends State<AddSubcategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubcategoryService _subcategoryService = SubcategoryService();
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = false;

  String? _selectedCategoryId;
  String _name = '';
  String _code = '';
  String _description = '';
  int? _displayOrder;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _categoryService.initializeDummyData();
    if (widget.subcategoryToEdit != null) {
      _selectedCategoryId = widget.subcategoryToEdit!.categoryId;
      _name = widget.subcategoryToEdit!.name;
      _code = widget.subcategoryToEdit!.code;
      _description = widget.subcategoryToEdit!.description ?? '';
      _displayOrder = widget.subcategoryToEdit!.displayOrder;
      _isActive = widget.subcategoryToEdit!.isActive;
    } else {
      _code = 'SUBCAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  Future<void> _saveSubcategory({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Custom Validation: Check duplicate name
    if (_subcategoryService.isDuplicateName(_name, _selectedCategoryId!, excludeId: widget.subcategoryToEdit?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A subcategory with this name already exists in the selected category.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final categoryName = _categoryService.categories.firstWhere((c) => c.id == _selectedCategoryId).name;

      if (widget.subcategoryToEdit == null) {
        final newSubcategory = Subcategory(
          id: 'SUBCAT-${DateTime.now().millisecondsSinceEpoch}',
          categoryId: _selectedCategoryId!,
          categoryName: categoryName,
          name: _name,
          code: _code,
          description: _description.isNotEmpty ? _description : null,
          displayOrder: _displayOrder,
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await _subcategoryService.addSubcategory(newSubcategory);
      } else {
        final updatedSubcategory = widget.subcategoryToEdit!.copyWith(
          categoryId: _selectedCategoryId,
          categoryName: categoryName,
          name: _name,
          code: _code,
          description: _description.isNotEmpty ? _description : null,
          displayOrder: _displayOrder,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );
        await _subcategoryService.updateSubcategory(updatedSubcategory);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.subcategoryToEdit == null ? 'Subcategory added successfully!' : 'Subcategory updated successfully!'), backgroundColor: Colors.green)
      );

      if (saveAndNew && widget.subcategoryToEdit == null) {
        _formKey.currentState!.reset();
        setState(() {
          _selectedCategoryId = null;
          _isActive = true;
          _isLoading = false;
          _code = 'SUBCAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving subcategory: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subcategoryToEdit != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isEditing ? 'Edit Subcategory' : 'Add Subcategory', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                            value: _selectedCategoryId,
                            items: _categoryService.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (value) => setState(() => _selectedCategoryId = value),
                            validator: (value) => value == null ? 'Please select a category' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: _name,
                            decoration: const InputDecoration(labelText: 'Subcategory Name *', border: OutlineInputBorder()),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            onSaved: (value) => _name = value!.trim(),
                            maxLength: 100,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: _code,
                            decoration: const InputDecoration(labelText: 'Subcategory Code *', border: OutlineInputBorder()),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            onSaved: (value) => _code = value!.trim(),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: _description,
                            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                            maxLines: 3,
                            onSaved: (value) => _description = value?.trim() ?? '',
                            maxLength: 250,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: _displayOrder?.toString(),
                            decoration: const InputDecoration(labelText: 'Display Order', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _displayOrder = value != null && value.isNotEmpty ? int.tryParse(value) : null,
                          ),
                          const SizedBox(height: 16),
                          
                          SwitchListTile(
                            title: const Text('Status (Active)'),
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 32),
                          
                          if (isDesktop)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                const SizedBox(width: 16),
                                if (!isEditing) ...[
                                  FilledButton.tonal(onPressed: () => _saveSubcategory(saveAndNew: true), child: const Text('Save & New')),
                                  const SizedBox(width: 16),
                                ],
                                FilledButton(onPressed: () => _saveSubcategory(saveAndNew: false), child: Text(isEditing ? 'Update' : 'Save')),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(onPressed: () => _saveSubcategory(saveAndNew: false), child: Text(isEditing ? 'Update' : 'Save')),
                                if (!isEditing) ...[
                                  const SizedBox(height: 12),
                                  FilledButton.tonal(onPressed: () => _saveSubcategory(saveAndNew: true), child: const Text('Save & New')),
                                ],
                                const SizedBox(height: 12),
                                OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                              ],
                            ),
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
                const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(title: Text(isEditing ? 'Edit Subcategory' : 'Add Subcategory')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: Text(isEditing ? 'Edit Subcategory' : 'Add Subcategory')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }
}
