import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment_mode.dart';
import '../../services/payment_mode_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';

import '../../widgets/save_clear_shortcuts.dart';

class AddPaymentModeScreen extends StatefulWidget {
  const AddPaymentModeScreen({super.key});

  @override
  State<AddPaymentModeScreen> createState() => _AddPaymentModeScreenState();
}

class _AddPaymentModeScreenState extends State<AddPaymentModeScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentModeService _paymentModeService = PaymentModeService();
  bool _isLoading = false;

  String _name = '';
  String _type = 'Cash';
  String _description = '';
  int _displayOrder = 0;
  bool _isActive = true;

  final List<String> _paymentTypes = ['Cash', 'UPI', 'Card', 'Bank', 'Wallet', 'Cheque'];

  Future<void> _savePaymentMode({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newMode = PaymentMode(
        id: 'PM-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        type: _type,
        description: _description.isNotEmpty ? _description : null,
        displayOrder: _displayOrder,
        isActive: _isActive,
      );

      await _paymentModeService.addPaymentMode(newMode);

      if (!mounted) return;

      await showSuccessDialog(context, 'Payment mode saved successfully!');
      if (!mounted) return;

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _type = 'Cash';
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
      await showErrorDialog(context, 'Error saving payment mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) {
          _savePaymentMode(saveAndNew: false);
        }
      },
      onClear: () {
        if (!_isLoading) {
          _formKey.currentState?.reset();
          setState(() {
            _type = 'Cash';
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
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Mode Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildNameField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTypeField()),
                              ],
                            ),
                          ] else ...[
                            _buildNameField(),
                            const SizedBox(height: 16),
                            _buildTypeField(),
                          ],
                          const SizedBox(height: 16),
                          _buildDescriptionField(),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildDisplayOrderField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildStatusField()),
                              ],
                            ),
                          ] else ...[
                            _buildDisplayOrderField(),
                            const SizedBox(height: 16),
                            _buildStatusField(),
                          ],
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
                    appBar: AppBar(title: const Text('Add Payment Mode')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Payment Mode')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    ));
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Payment Mode Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter payment mode name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Payment Type *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      value: _type,
      items: _paymentTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _type = value;
          });
        }
      },
      onSaved: (value) => _type = value!,
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

  Widget _buildDisplayOrderField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Display Order',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.sort),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _displayOrder = int.tryParse(value) ?? 0;
        }
      },
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
            onPressed: () => _savePaymentMode(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _savePaymentMode(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _savePaymentMode(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _savePaymentMode(saveAndNew: true),
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
