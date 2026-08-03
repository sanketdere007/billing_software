import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/barcode_settings.dart';
import '../../services/barcode_settings_service.dart';
import '../../widgets/app_drawer.dart';

class AddBarcodeSettingsScreen extends StatefulWidget {
  const AddBarcodeSettingsScreen({super.key});

  @override
  State<AddBarcodeSettingsScreen> createState() => _AddBarcodeSettingsScreenState();
}

class _AddBarcodeSettingsScreenState extends State<AddBarcodeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final BarcodeSettingsService _service = BarcodeSettingsService();
  bool _isLoading = false;

  String _format = 'CODE128';
  String _prefix = '';
  int _length = 8;
  bool _autoGenerate = true;
  double _width = 1.5;
  double _height = 0.5;
  String _labelSize = '';
  int _printCopies = 1;
  bool _isActive = true;

  final List<String> _barcodeFormats = ['CODE128', 'EAN13', 'UPCA', 'QR'];

  Future<void> _saveSettings({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newSettings = BarcodeSettings(
        id: 'BC-${DateTime.now().millisecondsSinceEpoch}',
        format: _format,
        prefix: _prefix.isNotEmpty ? _prefix : null,
        length: _length,
        autoGenerate: _autoGenerate,
        width: _width,
        height: _height,
        labelSize: _labelSize.isNotEmpty ? _labelSize : null,
        printCopies: _printCopies,
        isActive: _isActive,
      );

      await _service.addSettings(newSettings);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barcode settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _format = 'CODE128';
          _autoGenerate = true;
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
          content: Text('Error saving barcode settings: $e'),
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
                            'Barcode Configuration',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildFormatField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildPrefixField()),
                              ],
                            ),
                          ] else ...[
                            _buildFormatField(),
                            const SizedBox(height: 16),
                            _buildPrefixField(),
                          ],
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildLengthField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildLabelSizeField()),
                              ],
                            ),
                          ] else ...[
                            _buildLengthField(),
                            const SizedBox(height: 16),
                            _buildLabelSizeField(),
                          ],
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildWidthField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildHeightField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildPrintCopiesField()),
                              ],
                            ),
                          ] else ...[
                            _buildWidthField(),
                            const SizedBox(height: 16),
                            _buildHeightField(),
                            const SizedBox(height: 16),
                            _buildPrintCopiesField(),
                          ],
                          const SizedBox(height: 16),
                          _buildAutoGenerateField(),
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
                    appBar: AppBar(title: const Text('Add Barcode Configuration')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Barcode Configuration')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }

  Widget _buildFormatField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Barcode Format *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.qr_code_2),
      ),
      value: _format,
      items: _barcodeFormats.map((format) {
        return DropdownMenuItem(
          value: format,
          child: Text(format),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _format = value;
          });
        }
      },
      onSaved: (value) => _format = value!,
    );
  }

  Widget _buildPrefixField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Barcode Prefix',
        border: OutlineInputBorder(),
        hintText: 'e.g., ITEM-',
      ),
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      onSaved: (value) => _prefix = value?.trim() ?? '',
    );
  }

  Widget _buildLengthField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Barcode Length',
        border: OutlineInputBorder(),
      ),
      initialValue: '8',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final length = int.tryParse(value);
          if (length == null || length < 4 || length > 15) {
            return 'Length must be between 4 and 15';
          }
        }
        return null;
      },
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _length = int.tryParse(value) ?? 8;
        }
      },
    );
  }

  Widget _buildLabelSizeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Label Size',
        border: OutlineInputBorder(),
        hintText: 'e.g., 50x25 mm',
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _labelSize = value?.trim() ?? '',
    );
  }

  Widget _buildWidthField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Width (inches)',
        border: OutlineInputBorder(),
      ),
      initialValue: '1.5',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _width = double.tryParse(value) ?? 1.5;
        }
      },
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Height (inches)',
        border: OutlineInputBorder(),
      ),
      initialValue: '0.5',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _height = double.tryParse(value) ?? 0.5;
        }
      },
    );
  }

  Widget _buildPrintCopiesField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Print Copies',
        border: OutlineInputBorder(),
      ),
      initialValue: '1',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _printCopies = int.tryParse(value) ?? 1;
        }
      },
    );
  }

  Widget _buildAutoGenerateField() {
    return SwitchListTile(
      title: const Text('Auto Generate Barcode'),
      value: _autoGenerate,
      onChanged: (value) {
        setState(() {
          _autoGenerate = value;
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
            onPressed: () => _saveSettings(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveSettings(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveSettings(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveSettings(saveAndNew: true),
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
