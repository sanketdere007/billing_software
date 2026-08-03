import 'package:flutter/material.dart';
import '../../models/unit.dart';
import '../../services/unit_service.dart';
import '../../widgets/app_drawer.dart';

class AddUnitScreen extends StatefulWidget {
  const AddUnitScreen({super.key});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final UnitService _unitService = UnitService();
  bool _isLoading = false;

  String _name = '';
  String _shortName = '';
  String _description = '';
  bool _isActive = true;

  Future<void> _saveUnit({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final newUnit = Unit(
        id: 'UNT-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        shortName: _shortName.isNotEmpty ? _shortName : null,
        description: _description.isNotEmpty ? _description : null,
        isActive: _isActive,
      );

      await _unitService.addUnit(newUnit);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit saved successfully!'), backgroundColor: Colors.green));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving unit: $e'), backgroundColor: Colors.red));
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
                          Text('Unit Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Unit Name *', border: OutlineInputBorder()),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            onSaved: (value) => _name = value!.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Short Name', border: OutlineInputBorder()),
                            onSaved: (value) => _shortName = value?.trim() ?? '',
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
                                FilledButton.tonal(onPressed: () => _saveUnit(saveAndNew: true), child: const Text('Save & New')),
                                const SizedBox(width: 16),
                                FilledButton(onPressed: () => _saveUnit(saveAndNew: false), child: const Text('Save')),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(onPressed: () => _saveUnit(saveAndNew: false), child: const Text('Save')),
                                const SizedBox(height: 12),
                                FilledButton.tonal(onPressed: () => _saveUnit(saveAndNew: true), child: const Text('Save & New')),
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
                    appBar: AppBar(title: const Text('Add Unit')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Unit')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }
}
