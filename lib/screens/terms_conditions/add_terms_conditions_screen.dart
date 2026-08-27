import 'package:flutter/material.dart';
import '../../models/terms_conditions.dart';
import '../../services/terms_conditions_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/save_clear_shortcuts.dart';

class AddTermsConditionsScreen extends StatefulWidget {
  const AddTermsConditionsScreen({super.key});

  @override
  State<AddTermsConditionsScreen> createState() => _AddTermsConditionsScreenState();
}

class _AddTermsConditionsScreenState extends State<AddTermsConditionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TermsConditionsService _service = TermsConditionsService();
  bool _isLoading = false;

  String _title = '';
  String _terms = '';
  bool _displayOnInvoice = true;
  bool _isActive = true;

  Future<void> _saveTerms({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newTerms = TermsConditions(
        id: 'TC-${DateTime.now().millisecondsSinceEpoch}',
        title: _title,
        terms: _terms,
        displayOnInvoice: _displayOnInvoice,
        isActive: _isActive,
      );

      await _service.addTerms(newTerms);

      if (!mounted) return;

      await showSuccessDialog(context, 'Terms saved successfully!');
      if (!mounted) return;

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _displayOnInvoice = true;
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
      await showErrorDialog(context, 'Error saving terms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) {
          _saveTerms(saveAndNew: false);
        }
      },
      onClear: () {
        _formKey.currentState?.reset();
        setState(() {
          _displayOnInvoice = true;
          _isActive = true;
        });
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
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms & Conditions Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildTitleField(),
                            const SizedBox(height: 16),
                            _buildTermsField(),
                            const SizedBox(height: 16),
                            _buildDisplayOnInvoiceField(),
                            const SizedBox(height: 8),
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
                      appBar: AppBar(title: const Text('Add Terms & Conditions')),
                      body: content,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(title: const Text('Add Terms & Conditions')),
              drawer: const AppDrawer(isPermanent: false),
              body: content,
            );
          }
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Title *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
        hintText: 'e.g., Standard Sales Policy',
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter title';
        }
        return null;
      },
      onSaved: (value) => _title = value!.trim(),
    );
  }

  Widget _buildTermsField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Terms & Conditions *',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 8,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter terms and conditions';
        }
        return null;
      },
      onSaved: (value) => _terms = value!.trim(),
    );
  }

  Widget _buildDisplayOnInvoiceField() {
    return SwitchListTile(
      title: const Text('Display on Invoice'),
      value: _displayOnInvoice,
      onChanged: (value) {
        setState(() {
          _displayOnInvoice = value;
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade400),
      ),
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
            onPressed: () => _saveTerms(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveTerms(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveTerms(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveTerms(saveAndNew: true),
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
