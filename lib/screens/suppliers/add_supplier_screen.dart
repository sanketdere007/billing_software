import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/supplier.dart';
import '../../models/state_model.dart';
import '../../models/city.dart';
import '../../models/area.dart';
import '../../services/supplier_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/state_dropdown.dart';
import '../../widgets/city_dropdown.dart';
import '../../widgets/area_dropdown.dart';

class AddSupplierScreen extends StatefulWidget {
  final SupplierListItem? supplierToEdit;
  const AddSupplierScreen({super.key, this.supplierToEdit});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _supplierService = supplierService;
  bool _isLoading = false;

  late int _id;
  String _code = '';
  String _name = '';
  String _companyName = '';
  String _mobile = '';
  String _altMobile = '';
  String _email = '';
  String _gst = '';
  String _pan = '';
  String _address = '';
  int _areaId = 0;
  int _cityId = 0;
  int _stateId = 0;
  String _pincode = '';
  String _country = 'India';
  String _paymentTerms = '';
  double _creditLimit = 0.0;
  int _creditDays = 0;
  bool _isActive = true;

  final FocusNode _saveFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final editSupplier = widget.supplierToEdit;
    if (editSupplier != null) {
      _id = editSupplier.suppId;
      _code = editSupplier.suppCode;
      _name = editSupplier.suppName;
      _companyName = editSupplier.suppCompanyName;
      _mobile = editSupplier.suppMobileNo;
      _altMobile = editSupplier.suppAlternateMobileNo;
      _email = editSupplier.suppEmail;
      _gst = editSupplier.suppGSTNo;
      _pan = editSupplier.suppPANNo;
      _address = editSupplier.suppAddress;
      _areaId = editSupplier.suppAreaId;
      _cityId = editSupplier.suppCityId;
      _stateId = editSupplier.suppStateId;
      _pincode = editSupplier.suppPincode;
      _country = editSupplier.suppCountry;
      _paymentTerms = editSupplier.suppPaymentTerms;
      _creditLimit = editSupplier.suppCreditLimit;
      _creditDays = editSupplier.suppCreditDays;
      _isActive = editSupplier.suppIsActive;
    } else {
      _id = 0;
    }
  }

  @override
  void dispose() {
    _saveFocus.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final request = SupplierUpsertRequest(
        suppId: _id,
        suppCode: _code,
        suppName: _name,
        suppCompanyName: _companyName,
        suppMobileNo: _mobile,
        suppAlternateMobileNo: _altMobile,
        suppEmail: _email,
        suppGSTNo: _gst,
        suppPANNo: _pan,
        suppAddress: _address,
        suppAreaId: _areaId,
        suppCityId: _cityId,
        suppStateId: _stateId,
        suppPincode: _pincode,
        suppCountry: _country,
        suppPaymentTerms: _paymentTerms,
        suppCreditLimit: _creditLimit,
        suppCreditDays: _creditDays,
        suppIsActive: _isActive,
        suppCreatedBy: 0,
        suppModifiedBy: 0,
        suppCompId: 0,
        suppBranchId: 0,
      );

      await _supplierService.insertOrUpdateSupplier(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier saved successfully!'), backgroundColor: Colors.green));

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _id = 0;
          _code = '';
          _name = '';
          _companyName = '';
          _mobile = '';
          _altMobile = '';
          _email = '';
          _gst = '';
          _pan = '';
          _address = '';
          _areaId = 0;
          _cityId = 0;
          _stateId = 0;
          _pincode = '';
          _paymentTerms = '';
          _creditLimit = 0.0;
          _creditDays = 0;
          _isActive = true;
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '')), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = _id != 0;
    final title = isEditMode ? 'Edit Supplier' : 'Add Supplier';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_shipping_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Basic Details Card
                          _buildSectionCard(
                            title: 'Basic Details',
                            icon: Icons.info_outline_rounded,
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _name,
                                        decoration: InputDecoration(
                                          labelText: 'Supplier Name *',
                                          prefixIcon: const Icon(Icons.person_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                        onSaved: (val) => _name = val?.trim() ?? '',
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _companyName,
                                        decoration: InputDecoration(
                                          labelText: 'Company Name',
                                          prefixIcon: const Icon(Icons.business_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onSaved: (val) => _companyName = val?.trim() ?? '',
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _code,
                                        decoration: InputDecoration(
                                          labelText: 'Supplier Code',
                                          prefixIcon: const Icon(Icons.tag_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onSaved: (val) => _code = val?.trim() ?? '',
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _email,
                                        decoration: InputDecoration(
                                          labelText: 'Email Address',
                                          prefixIcon: const Icon(Icons.email_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        onSaved: (val) => _email = val?.trim() ?? '',
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Contact Details Card
                          _buildSectionCard(
                            title: 'Contact Details',
                            icon: Icons.contact_phone_rounded,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _mobile,
                                    decoration: InputDecoration(
                                      labelText: 'Mobile No *',
                                      prefixIcon: const Icon(Icons.phone_rounded),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                    onSaved: (val) => _mobile = val?.trim() ?? '',
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _altMobile,
                                    decoration: InputDecoration(
                                      labelText: 'Alternate Mobile No',
                                      prefixIcon: const Icon(Icons.phone_android_rounded),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onSaved: (val) => _altMobile = val?.trim() ?? '',
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Address & Location Details Card
                          _buildSectionCard(
                            title: 'Location Details',
                            icon: Icons.location_on_rounded,
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: _address,
                                  decoration: InputDecoration(
                                    labelText: 'Address',
                                    prefixIcon: const Icon(Icons.home_work_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  maxLines: 2,
                                  onSaved: (val) => _address = val?.trim() ?? '',
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: StateDropdown(
                                        selectedStateId: _stateId == 0 ? null : _stateId,
                                        onChanged: (StateModel? s) {
                                          setState(() {
                                            _stateId = s?.stateId ?? 0;
                                            _cityId = 0;
                                            _areaId = 0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CityDropdown(
                                        selectedCityId: _cityId == 0 ? null : _cityId,
                                        stateId: _stateId == 0 ? null : _stateId,
                                        onChanged: (CityListItem? c) {
                                          setState(() {
                                            _cityId = c?.cityId ?? 0;
                                            _areaId = 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: AreaDropdown(
                                        selectedAreaId: _areaId == 0 ? null : _areaId,
                                        cityId: _cityId == 0 ? null : _cityId,
                                        stateId: _stateId == 0 ? null : _stateId,
                                        onChanged: (AreaListItem? a) {
                                          setState(() {
                                            _areaId = a?.areaId ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _pincode,
                                        decoration: InputDecoration(
                                          labelText: 'Pincode',
                                          prefixIcon: const Icon(Icons.pin_drop_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onSaved: (val) => _pincode = val?.trim() ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tax & Financials
                          _buildSectionCard(
                            title: 'Tax & Financials',
                            icon: Icons.account_balance_wallet_rounded,
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _gst,
                                        decoration: InputDecoration(
                                          labelText: 'GST No',
                                          prefixIcon: const Icon(Icons.receipt_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        textCapitalization: TextCapitalization.characters,
                                        onSaved: (val) => _gst = val?.trim() ?? '',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _pan,
                                        decoration: InputDecoration(
                                          labelText: 'PAN No',
                                          prefixIcon: const Icon(Icons.credit_card_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        textCapitalization: TextCapitalization.characters,
                                        onSaved: (val) => _pan = val?.trim() ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _creditLimit > 0 ? _creditLimit.toStringAsFixed(2) : null,
                                        decoration: InputDecoration(
                                          labelText: 'Credit Limit',
                                          prefixIcon: const Icon(Icons.currency_rupee_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        onSaved: (val) => _creditLimit = double.tryParse(val ?? '') ?? 0.0,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _creditDays > 0 ? _creditDays.toString() : null,
                                        decoration: InputDecoration(
                                          labelText: 'Credit Days',
                                          prefixIcon: const Icon(Icons.calendar_month_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onSaved: (val) => _creditDays = int.tryParse(val ?? '') ?? 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Settings
                          _buildSectionCard(
                            title: 'Settings',
                            icon: Icons.settings_rounded,
                            child: SwitchListTile(
                              title: const Text('Is Active?'),
                              subtitle: const Text('Active suppliers can be selected in purchase bills.'),
                              value: _isActive,
                              onChanged: (val) => setState(() => _isActive = val),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ),

                          const SizedBox(height: 32),
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
                                    onPressed: () => _saveSupplier(saveAndNew: true), 
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Save & New'),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                FilledButton.icon(
                                  focusNode: _saveFocus,
                                  onPressed: () => _saveSupplier(saveAndNew: false), 
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
                                  onPressed: () => _saveSupplier(saveAndNew: false), 
                                  icon: const Icon(Icons.save_rounded, size: 18),
                                  label: const Text('Save'),
                                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                                ),
                                const SizedBox(height: 12),
                                if (!isEditMode) ...[
                                  FilledButton.tonalIcon(
                                    onPressed: () => _saveSupplier(saveAndNew: true), 
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

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
