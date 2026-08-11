import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gst.dart';
import '../../services/gst_service.dart';
import '../../widgets/app_drawer.dart';

class AddGstScreen extends StatefulWidget {
  final GstTaxListItem? gstToEdit;
  const AddGstScreen({super.key, this.gstToEdit});

  @override
  State<AddGstScreen> createState() => _AddGstScreenState();
}

class _AddGstScreenState extends State<AddGstScreen> {
  final _formKey = GlobalKey<FormState>();
  final GstService _gstService = gstService;
  bool _isLoading = false;

  late int _id;
  String _name = '';
  double _percentage = 0.0;
  double _cgst = 0.0;
  double _sgst = 0.0;
  double _igst = 0.0;
  bool _isActive = true;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _percentageFocus = FocusNode();
  final FocusNode _saveFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final editGst = widget.gstToEdit;
    if (editGst != null) {
      _id = editGst.gstTaxId;
      _name = editGst.gstTaxName;
      _percentage = editGst.gstTaxPercentage;
      _cgst = editGst.gstTaxCgst;
      _sgst = editGst.gstTaxSgst;
      _igst = editGst.gstTaxIgst;
      _isActive = editGst.gstTaxIsActive;
    } else {
      _id = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _percentageFocus.dispose();
    _saveFocus.dispose();
    super.dispose();
  }

  Future<void> _saveGst({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final request = GstTaxUpsertRequest(
        gstTaxId: _id,
        gstTaxName: _name,
        gstTaxPercentage: _percentage,
        gstTaxCgst: _cgst,
        gstTaxSgst: _sgst,
        gstTaxIgst: _igst,
        gstTaxIsActive: _isActive,
        gstTaxCreatedBy: 0,
        gstTaxModifiedBy: 0,
      );

      await _gstService.insertOrUpdateGst(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GST saved successfully!'), backgroundColor: Colors.green));

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _id = 0;
          _percentage = 0;
          _cgst = 0;
          _sgst = 0;
          _igst = 0;
          _isActive = true;
          _isLoading = false;
        });
        _nameFocus.requestFocus();
      } else {
        Navigator.of(context).pop(true); // pass true to refresh list
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '')), backgroundColor: Colors.red));
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
    } else {
      setState(() {
        _percentage = 0.0;
        _cgst = 0.0;
        _sgst = 0.0;
        _igst = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = _id != 0;
    final title = isEditMode ? 'Edit GST Tax' : 'Add GST Tax';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    initialValue: _name,
                                    focusNode: _nameFocus,
                                    decoration: InputDecoration(
                                      labelText: 'GST Name *',
                                      hintText: 'e.g. GST 18%',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      prefixIcon: const Icon(Icons.label_outline_rounded),
                                    ),
                                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter GST Name' : null,
                                    onSaved: (value) => _name = value?.trim() ?? '',
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => _percentageFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: isEditMode ? _percentage.toStringAsFixed(2) : null,
                                    focusNode: _percentageFocus,
                                    decoration: InputDecoration(
                                      labelText: 'GST Percentage *',
                                      hintText: '0.00',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      prefixIcon: const Icon(Icons.percent_rounded),
                                      suffixText: '%',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) return 'Required';
                                      if (double.tryParse(value) == null) return 'Invalid number';
                                      return null;
                                    },
                                    onChanged: _onPercentageChanged,
                                    onSaved: (value) => _percentage = double.tryParse(value ?? '') ?? 0.0,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _saveGst(saveAndNew: false),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Auto Calculated Fields Container
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Calculated Tax Components', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                key: ValueKey('CGST_$_cgst'),
                                                initialValue: _cgst.toStringAsFixed(2),
                                                decoration: InputDecoration(
                                                  labelText: 'CGST', 
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                                                  suffixText: '%',
                                                  filled: true,
                                                  fillColor: Theme.of(context).colorScheme.surface,
                                                ),
                                                readOnly: true,
                                                enabled: false,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                key: ValueKey('SGST_$_sgst'),
                                                initialValue: _sgst.toStringAsFixed(2),
                                                decoration: InputDecoration(
                                                  labelText: 'SGST', 
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                                                  suffixText: '%',
                                                  filled: true,
                                                  fillColor: Theme.of(context).colorScheme.surface,
                                                ),
                                                readOnly: true,
                                                enabled: false,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                key: ValueKey('IGST_$_igst'),
                                                initialValue: _igst.toStringAsFixed(2),
                                                decoration: InputDecoration(
                                                  labelText: 'IGST', 
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                                                  suffixText: '%',
                                                  filled: true,
                                                  fillColor: Theme.of(context).colorScheme.surface,
                                                ),
                                                readOnly: true,
                                                enabled: false,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text('Is Active?'),
                                    subtitle: const Text('Active taxes can be used in transactions'),
                                    value: _isActive,
                                    onChanged: (value) => setState(() => _isActive = value),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (isDesktop)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(), 
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('Cancel'),
                                ),
                                const SizedBox(width: 16),
                                if (!isEditMode) ...[
                                  FilledButton.tonalIcon(
                                    onPressed: () => _saveGst(saveAndNew: true), 
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Save & New'),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                FilledButton.icon(
                                  focusNode: _saveFocus,
                                  onPressed: () => _saveGst(saveAndNew: false), 
                                  icon: const Icon(Icons.save_rounded, size: 18),
                                  label: const Text('Save'),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton.icon(
                                  focusNode: _saveFocus,
                                  onPressed: () => _saveGst(saveAndNew: false), 
                                  icon: const Icon(Icons.save_rounded, size: 18),
                                  label: const Text('Save'),
                                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                                ),
                                const SizedBox(height: 12),
                                if (!isEditMode) ...[
                                  FilledButton.tonalIcon(
                                    onPressed: () => _saveGst(saveAndNew: true), 
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Save & New'),
                                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(), 
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('Cancel'),
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                                ),
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
                    appBar: AppBar(title: Text(title)),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }
}
