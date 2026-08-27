import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/printer_settings.dart';
import '../../services/printer_settings_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/save_clear_shortcuts.dart';

class AddPrinterSettingsScreen extends StatefulWidget {
  const AddPrinterSettingsScreen({super.key});

  @override
  State<AddPrinterSettingsScreen> createState() => _AddPrinterSettingsScreenState();
}

class _AddPrinterSettingsScreenState extends State<AddPrinterSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final PrinterSettingsService _service = PrinterSettingsService();
  bool _isLoading = false;

  String _name = '';
  String _type = 'Thermal';
  String _paperSize = 'A4';
  String _printWidth = '80mm';
  bool _autoPrint = false;
  int _numberOfCopies = 1;
  bool _isDefault = false;
  bool _isActive = true;

  final List<String> _printerTypes = ['Thermal', 'A4'];
  final List<String> _paperSizes = ['A4', 'A5', 'Letter', 'Legal'];
  final List<String> _printWidths = ['80mm', '58mm', '76mm'];

  Future<void> _saveSettings({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newSettings = PrinterSettings(
        id: 'PS-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        type: _type,
        paperSize: _type == 'A4' ? _paperSize : null,
        printWidth: _type == 'Thermal' ? _printWidth : null,
        autoPrint: _autoPrint,
        numberOfCopies: _numberOfCopies,
        isDefault: _isDefault,
        isActive: _isActive,
      );

      await _service.addSettings(newSettings);

      if (!mounted) return;

      await showSuccessDialog(context, 'Printer saved successfully!');
      if (!mounted) return;

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _type = 'Thermal';
          _autoPrint = false;
          _isDefault = false;
          _isActive = true;
          _isLoading = false;
          _numberOfCopies = 1;
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      await showErrorDialog(context, 'Error saving printer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveSettings(saveAndNew: false);
      },
      onClear: () {
        _formKey.currentState?.reset();
        setState(() {
          _type = 'Thermal';
          _autoPrint = false;
          _isDefault = false;
          _isActive = true;
          _numberOfCopies = 1;
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
                            'Printer Details',
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
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_type == 'A4') Expanded(child: _buildPaperSizeField())
                                else Expanded(child: _buildPrintWidthField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildNumberOfCopiesField()),
                              ],
                            ),
                          ] else ...[
                            if (_type == 'A4') _buildPaperSizeField()
                            else _buildPrintWidthField(),
                            const SizedBox(height: 16),
                            _buildNumberOfCopiesField(),
                          ],
                          const SizedBox(height: 16),
                          _buildAutoPrintField(),
                          const SizedBox(height: 8),
                          _buildDefaultField(),
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
                    appBar: AppBar(title: const Text('Add Printer')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Printer')),
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
        labelText: 'Printer Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.print),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter printer name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Printer Type *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      value: _type,
      items: _printerTypes.map((type) {
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

  Widget _buildPaperSizeField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Paper Size',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      value: _paperSize,
      items: _paperSizes.map((size) {
        return DropdownMenuItem(
          value: size,
          child: Text(size),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _paperSize = value;
          });
        }
      },
      onSaved: (value) => _paperSize = value!,
    );
  }

  Widget _buildPrintWidthField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Print Width',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.line_weight),
      ),
      value: _printWidth,
      items: _printWidths.map((width) {
        return DropdownMenuItem(
          value: width,
          child: Text(width),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _printWidth = value;
          });
        }
      },
      onSaved: (value) => _printWidth = value!,
    );
  }

  Widget _buildNumberOfCopiesField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Number of Copies',
        border: OutlineInputBorder(),
      ),
      initialValue: '1',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _numberOfCopies = int.tryParse(value) ?? 1;
        }
      },
    );
  }

  Widget _buildAutoPrintField() {
    return SwitchListTile(
      title: const Text('Auto Print after Save'),
      value: _autoPrint,
      onChanged: (value) {
        setState(() {
          _autoPrint = value;
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildDefaultField() {
    return SwitchListTile(
      title: const Text('Set as Default Printer'),
      value: _isDefault,
      onChanged: (value) {
        setState(() {
          _isDefault = value;
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
