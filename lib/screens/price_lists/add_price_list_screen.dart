import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/price_list.dart';
import '../../services/price_list_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';

class AddPriceListScreen extends StatefulWidget {
  const AddPriceListScreen({super.key});

  @override
  State<AddPriceListScreen> createState() => _AddPriceListScreenState();
}

class _AddPriceListScreenState extends State<AddPriceListScreen> {
  final _formKey = GlobalKey<FormState>();
  final PriceListService _priceListService = PriceListService();
  bool _isLoading = false;

  String _name = '';
  String _description = '';
  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  bool _isDefault = false;
  bool _isActive = true;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate
        ? (_effectiveFrom ?? DateTime.now())
        : (_effectiveTo ?? (_effectiveFrom ?? DateTime.now()));
        
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _effectiveFrom = picked;
          // Validate effective to is after effective from
          if (_effectiveTo != null && _effectiveTo!.isBefore(picked)) {
            _effectiveTo = null;
          }
        } else {
          _effectiveTo = picked;
        }
      });
    }
  }

  Future<void> _savePriceList({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newPriceList = PriceList(
        id: 'PL-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        description: _description.isNotEmpty ? _description : null,
        effectiveFrom: _effectiveFrom,
        effectiveTo: _effectiveTo,
        isDefault: _isDefault,
        isActive: _isActive,
      );

      await _priceListService.addPriceList(newPriceList);

      if (!mounted) return;

      await showSuccessDialog(context, 'Price list saved successfully!');
      if (!mounted) return;

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _effectiveFrom = null;
          _effectiveTo = null;
          _isDefault = false;
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
      await showErrorDialog(context, 'Error saving price list: $e');
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
                            'Price List Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildNameField(),
                          const SizedBox(height: 16),
                          _buildDescriptionField(),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildEffectiveFromField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildEffectiveToField()),
                              ],
                            ),
                          ] else ...[
                            _buildEffectiveFromField(),
                            const SizedBox(height: 16),
                            _buildEffectiveToField(),
                          ],
                          const SizedBox(height: 16),
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
                    appBar: AppBar(title: const Text('Add Price List')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Price List')),
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
        labelText: 'Price List Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.list_alt),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter price list name';
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

  Widget _buildEffectiveFromField() {
    return InkWell(
      onTap: () => _selectDate(context, true),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Effective From',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _effectiveFrom != null
              ? DateFormat('dd-MMM-yyyy').format(_effectiveFrom!)
              : 'Select Date',
          style: TextStyle(
            color: _effectiveFrom != null ? null : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildEffectiveToField() {
    return InkWell(
      onTap: () => _selectDate(context, false),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Effective To',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.event),
          errorText: _effectiveTo != null && _effectiveFrom != null && _effectiveTo!.isBefore(_effectiveFrom!) 
              ? 'Must be after Effective From' 
              : null,
        ),
        child: Text(
          _effectiveTo != null
              ? DateFormat('dd-MMM-yyyy').format(_effectiveTo!)
              : 'Select Date',
          style: TextStyle(
            color: _effectiveTo != null ? null : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultField() {
    return SwitchListTile(
      title: const Text('Set as Default Price List'),
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
            onPressed: () => _savePriceList(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _savePriceList(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _savePriceList(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _savePriceList(saveAndNew: true),
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
