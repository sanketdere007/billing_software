import 'package:flutter/material.dart';
import '../../models/hsn_sac.dart';
import '../../services/hsn_sac_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';

import '../../widgets/save_clear_shortcuts.dart';

class AddHsnSacScreen extends StatefulWidget {
  const AddHsnSacScreen({super.key});

  @override
  State<AddHsnSacScreen> createState() => _AddHsnSacScreenState();
}

class _AddHsnSacScreenState extends State<AddHsnSacScreen> {
  final _formKey = GlobalKey<FormState>();
  final HsnSacService _hsnSacService = HsnSacService();
  bool _isLoading = false;

  String _code = '';
  String _description = '';
  String _gstPercentage = '';
  bool _isActive = true;

  Future<void> _saveHsnSac({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final newHsnSac = HsnSac(
        id: 'HSN-${DateTime.now().millisecondsSinceEpoch}',
        code: _code,
        description: _description.isNotEmpty ? _description : null,
        gstPercentage: _gstPercentage.isNotEmpty ? _gstPercentage : null,
        isActive: _isActive,
      );

      await _hsnSacService.addHsnSac(newHsnSac);

      if (!mounted) return;
      await showSuccessDialog(context, 'HSN/SAC saved successfully!');
      if (!mounted) return;

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
      await showErrorDialog(context, 'Error saving HSN/SAC: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) {
          _saveHsnSac(saveAndNew: false);
        }
      },
      onClear: () {
        if (!_isLoading) {
          _formKey.currentState?.reset();
          setState(() {
            _isActive = true;
          });
        }
      },
      child: LayoutBuilder(
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
                          Text('HSN/SAC Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'HSN/SAC Code *', border: OutlineInputBorder()),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            onSaved: (value) => _code = value!.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                            maxLines: 3,
                            onSaved: (value) => _description = value?.trim() ?? '',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'GST Percentage', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: '0%', child: Text('0%')),
                              DropdownMenuItem(value: '5%', child: Text('5%')),
                              DropdownMenuItem(value: '12%', child: Text('12%')),
                              DropdownMenuItem(value: '18%', child: Text('18%')),
                              DropdownMenuItem(value: '28%', child: Text('28%')),
                            ],
                            onChanged: (value) {},
                            onSaved: (value) => _gstPercentage = value ?? '',
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
                                FilledButton.tonal(onPressed: () => _saveHsnSac(saveAndNew: true), child: const Text('Save & New')),
                                const SizedBox(width: 16),
                                FilledButton(onPressed: () => _saveHsnSac(saveAndNew: false), child: const Text('Save')),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(onPressed: () => _saveHsnSac(saveAndNew: false), child: const Text('Save')),
                                const SizedBox(height: 12),
                                FilledButton.tonal(onPressed: () => _saveHsnSac(saveAndNew: true), child: const Text('Save & New')),
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
                    appBar: AppBar(title: const Text('Add HSN/SAC')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add HSN/SAC')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    ));
  }
}
