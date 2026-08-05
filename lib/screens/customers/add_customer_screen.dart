import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../widgets/app_drawer.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  // Form values
  String _name = '';
  String _mobile = '';
  String _email = '';
  String _gst = '';
  String _address = '';
  String _city = '';
  String _state = '';
  String _pincode = '';
  double _creditLimit = 0.0;
  double _openingBalance = 0.0;
  bool _isActive = true;
  String _notes = '';

  Future<void> _saveCustomer({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newCustomer = Customer(
        id: 'CUST-${DateTime.now().millisecondsSinceEpoch}', // Dummy ID generator
        name: _name,
        mobile: _mobile,
        email: _email.isNotEmpty ? _email : null,
        gstNumber: _gst.isNotEmpty ? _gst : null,
        address: _address.isNotEmpty ? _address : null,
        city: _city.isNotEmpty ? _city : null,
        state: _state.isNotEmpty ? _state : null,
        pincode: _pincode.isNotEmpty ? _pincode : null,
        creditLimit: _creditLimit,
        openingBalance: _openingBalance,
        isActive: _isActive,
        notes: _notes.isNotEmpty ? _notes : null,
      );

      await _customerService.addCustomer(newCustomer);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving customer: $e'),
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
                            'Customer Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            // Desktop/Tablet layout (Two columns)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildNameField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMobileField()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildEmailField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildGSTField()),
                              ],
                            ),
                          ] else ...[
                            // Mobile layout (Single column)
                            _buildNameField(),
                            const SizedBox(height: 16),
                            _buildMobileField(),
                            const SizedBox(height: 16),
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            _buildGSTField(),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Address Details',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildAddressField(),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildCityField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildStateField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildPincodeField()),
                              ],
                            ),
                          ] else ...[
                            _buildCityField(),
                            const SizedBox(height: 16),
                            _buildStateField(),
                            const SizedBox(height: 16),
                            _buildPincodeField(),
                          ],
                          const SizedBox(height: 24),
                          // Text(
                          //   'Financial Details',
                          //   style: Theme.of(context).textTheme.titleLarge
                          //       ?.copyWith(fontWeight: FontWeight.bold),
                          // ),
                          // const SizedBox(height: 16),
                          // if (constraints.maxWidth >= 600) ...[
                          //   Row(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Expanded(child: _buildCreditLimitField()),
                          //       const SizedBox(width: 16),
                          //       Expanded(child: _buildOpeningBalanceField()),
                          //     ],
                          //   ),
                          // ] else ...[
                          //   _buildCreditLimitField(),
                          //   const SizedBox(height: 16),
                          //   _buildOpeningBalanceField(),
                          // ],
                          const SizedBox(height: 16),
                          _buildStatusField(),
                          const SizedBox(height: 16),

                          const SizedBox(height: 32),
                          _buildActionButtons(constraints.maxWidth >= 600),
                          const SizedBox(height: 32),
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
                    appBar: AppBar(title: const Text('Add Customer')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Customer')),
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
        labelText: 'Customer Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter customer name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Mobile Number *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter mobile number';
        }
        if (value.trim().length < 10) {
          return 'Please enter valid mobile number';
        }
        return null;
      },
      onSaved: (value) => _mobile = value!.trim(),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
      onSaved: (value) => _email = value?.trim() ?? '',
    );
  }

  Widget _buildGSTField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'GST Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.receipt),
      ),
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (value.length != 15) {
            return 'GST number must be 15 characters';
          }
        }
        return null;
      },
      onSaved: (value) => _gst = value?.trim() ?? '',
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Address',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      maxLines: 2,
      textInputAction: TextInputAction.next,
      onSaved: (value) => _address = value?.trim() ?? '',
    );
  }

  Widget _buildCityField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'City',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _city = value?.trim() ?? '',
    );
  }

  Widget _buildStateField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _state = value?.trim() ?? '',
    );
  }

  Widget _buildPincodeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Pincode',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      onSaved: (value) => _pincode = value?.trim() ?? '',
    );
  }

  Widget _buildCreditLimitField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Credit Limit',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _creditLimit = double.tryParse(value) ?? 0.0;
        }
      },
    );
  }

  Widget _buildOpeningBalanceField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Opening Balance',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _openingBalance = double.tryParse(value) ?? 0.0;
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
      contentPadding: EdgeInsets.zero,
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
            onPressed: () => _saveCustomer(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveCustomer(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveCustomer(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveCustomer(saveAndNew: true),
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
