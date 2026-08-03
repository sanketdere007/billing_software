import 'package:flutter/material.dart';
import '../../models/income_category.dart';
import '../../services/income_category_service.dart';
import '../../widgets/app_drawer.dart';

class AddIncomeCategoryScreen extends StatefulWidget {
  const AddIncomeCategoryScreen({super.key});

  @override
  State<AddIncomeCategoryScreen> createState() => _AddIncomeCategoryScreenState();
}

class _AddIncomeCategoryScreenState extends State<AddIncomeCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final IncomeCategoryService _service = IncomeCategoryService();
  bool _isLoading = false;

  String _name = '';
  String _description = '';
  bool _isActive = true;

  Future<void> _saveCategory({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newCategory = IncomeCategory(
        id: 'IC-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        description: _description.isNotEmpty ? _description : null,
        isActive: _isActive,
      );

      await _service.addCategory(newCategory);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income category saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving income category: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income Category Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildNameField(),
                          const SizedBox(height: 16),
                          _buildDescriptionField(),
                          const SizedBox(height: 16),
                          _buildStatusField(),
                          const SizedBox(height: 32),
                          _buildActionButtons(constraints.maxWidth >= 600),
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
                const SizedBox(
                  width: 250,
                  child: AppDrawer(isPermanent: true),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Add Income Category')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Income Category')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Category Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter category name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 2,
      textInputAction: TextInputAction.next,
      onSaved: (value) => _description = value?.trim() ?? '',
    );
  }

  Widget _buildStatusField() {
    return SwitchListTile(
      title: const Text('Status (Active)'),
      value: _isActive,
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          FilledButton.tonal(
            onPressed: () => _saveCategory(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveCategory(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveCategory(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveCategory(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
  }
}
