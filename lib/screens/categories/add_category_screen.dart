import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../widgets/app_drawer.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = false;

  String _name = '';
  String _description = '';
  bool _isActive = true;

  Future<void> _saveCategory({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final newCategory = Category(
        id: 'CAT-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        description: _description.isNotEmpty ? _description : null,
        isActive: _isActive,
      );

      await _categoryService.addCategory(newCategory);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category saved successfully!'), backgroundColor: Colors.green));

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving category: $e'), backgroundColor: Colors.red));
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
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Category Name *', border: OutlineInputBorder()),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            onSaved: (value) => _name = value!.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                            maxLines: 3,
                            onSaved: (value) => _description = value?.trim() ?? '',
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
                                FilledButton.tonal(onPressed: () => _saveCategory(saveAndNew: true), child: const Text('Save & New')),
                                const SizedBox(width: 16),
                                FilledButton(onPressed: () => _saveCategory(saveAndNew: false), child: const Text('Save')),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(onPressed: () => _saveCategory(saveAndNew: false), child: const Text('Save')),
                                const SizedBox(height: 12),
                                FilledButton.tonal(onPressed: () => _saveCategory(saveAndNew: true), child: const Text('Save & New')),
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
                    appBar: AppBar(title: const Text('Add Category')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Category')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }
}
