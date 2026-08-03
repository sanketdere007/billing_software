import 'package:flutter/material.dart';
import '../../models/gst.dart';
import '../../services/gst_service.dart';
import '../../widgets/app_drawer.dart';

class AddGstScreen extends StatefulWidget {
  const AddGstScreen({super.key});

  @override
  State<AddGstScreen> createState() => _AddGstScreenState();
}

class _AddGstScreenState extends State<AddGstScreen> {
  final _formKey = GlobalKey<FormState>();
  final GstService _gstService = GstService();
  bool _isLoading = false;

  String _name = '';
  double _percentage = 0.0;
  double _cgst = 0.0;
  double _sgst = 0.0;
  double _igst = 0.0;
  String _description = '';
  bool _isActive = true;

  Future<void> _saveGst({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final newGst = Gst(
        id: 'GST-${DateTime.now().millisecondsSinceEpoch}',
        name: _name.isNotEmpty ? _name : null,
        percentage: _percentage,
        cgst: _cgst,
        sgst: _sgst,
        igst: _igst,
        description: _description.isNotEmpty ? _description : null,
        isActive: _isActive,
      );

      await _gstService.addGst(newGst);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GST saved successfully!'), backgroundColor: Colors.green));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving GST: $e'), backgroundColor: Colors.red));
    }
  }

  void _onPercentageChanged(String value) {
    final double? val = double.tryParse(value);
    if (val != null) {
      setState(() {
        _percentage = val;
        _cgst = val / 2;
        _sgst = val / 2;
        _igst = val;
      });
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
                          Text('GST Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'GST Name', border: OutlineInputBorder()),
                            onSaved: (value) => _name = value?.trim() ?? '',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'GST Percentage *', border: OutlineInputBorder(), suffixText: '%'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            onChanged: _onPercentageChanged,
                            onSaved: (value) => _percentage = double.tryParse(value ?? '') ?? 0.0,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('CGST_$_cgst'),
                                  initialValue: _cgst.toString(),
                                  decoration: const InputDecoration(labelText: 'CGST', border: OutlineInputBorder(), suffixText: '%'),
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('SGST_$_sgst'),
                                  initialValue: _sgst.toString(),
                                  decoration: const InputDecoration(labelText: 'SGST', border: OutlineInputBorder(), suffixText: '%'),
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('IGST_$_igst'),
                                  initialValue: _igst.toString(),
                                  decoration: const InputDecoration(labelText: 'IGST', border: OutlineInputBorder(), suffixText: '%'),
                                  readOnly: true,
                                ),
                              ),
                            ],
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
                                FilledButton.tonal(onPressed: () => _saveGst(saveAndNew: true), child: const Text('Save & New')),
                                const SizedBox(width: 16),
                                FilledButton(onPressed: () => _saveGst(saveAndNew: false), child: const Text('Save')),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(onPressed: () => _saveGst(saveAndNew: false), child: const Text('Save')),
                                const SizedBox(height: 12),
                                FilledButton.tonal(onPressed: () => _saveGst(saveAndNew: true), child: const Text('Save & New')),
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
                    appBar: AppBar(title: const Text('Add GST')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add GST')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }
}
