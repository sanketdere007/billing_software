import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bank_account.dart';
import '../../services/bank_account_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/save_clear_shortcuts.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final BankAccountService _bankAccountService = BankAccountService();
  bool _isLoading = false;
  
  String _bankName = '';
  String _accountHolderName = '';
  String _accountNumber = '';
  String _ifscCode = '';
  String _branchName = '';
  String _upiId = '';
  double _openingBalance = 0.0;
  bool _isActive = true;

  Future<void> _saveBankAccount({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final newBankAccount = BankAccount(
        id: 'BANK-${DateTime.now().millisecondsSinceEpoch}',
        bankName: _bankName,
        accountHolderName: _accountHolderName,
        accountNumber: _accountNumber,
        ifscCode: _ifscCode,
        branchName: _branchName.isNotEmpty ? _branchName : null,
        upiId: _upiId.isNotEmpty ? _upiId : null,
        openingBalance: _openingBalance,
        isActive: _isActive,
      );

      await _bankAccountService.addBankAccount(newBankAccount);

      if (!mounted) return;
      
      await showSuccessDialog(context, 'Bank account saved successfully!');
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
      setState(() {
        _isLoading = false;
      });
      await showErrorDialog(context, 'Error saving bank account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveBankAccount(saveAndNew: false);
      },
      onClear: () {
        _formKey.currentState?.reset();
        setState(() {
          _isActive = true;
          _isLoading = false;
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
                              'Bank Account Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            if (constraints.maxWidth >= 600) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildBankNameField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildAccountHolderField()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildAccountNumberField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildIFSCField()),
                                ],
                              ),
                            ] else ...[
                              _buildBankNameField(),
                              const SizedBox(height: 16),
                              _buildAccountHolderField(),
                              const SizedBox(height: 16),
                              _buildAccountNumberField(),
                              const SizedBox(height: 16),
                              _buildIFSCField(),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Other Information',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            if (constraints.maxWidth >= 600) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildBranchNameField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildUPIField()),
                                ],
                              ),
                            ] else ...[
                              _buildBranchNameField(),
                              const SizedBox(height: 16),
                              _buildUPIField(),
                            ],
                            const SizedBox(height: 16),
                            _buildOpeningBalanceField(),
                            const SizedBox(height: 16),
                            _buildStatusField(),
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
                const SizedBox(
                  width: 250,
                  child: AppDrawer(isPermanent: true),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Add Bank Account')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Bank Account')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    ),
  );
}

  Widget _buildBankNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Bank Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.account_balance),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter bank name';
        }
        return null;
      },
      onSaved: (value) => _bankName = value!.trim(),
    );
  }

  Widget _buildAccountHolderField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Account Holder Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter account holder name';
        }
        return null;
      },
      onSaved: (value) => _accountHolderName = value!.trim(),
    );
  }

  Widget _buildAccountNumberField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Account Number *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers),
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter account number';
        }
        return null;
      },
      onSaved: (value) => _accountNumber = value!.trim(),
    );
  }

  Widget _buildIFSCField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'IFSC Code *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.code),
      ),
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter IFSC code';
        }
        return null;
      },
      onSaved: (value) => _ifscCode = value!.trim(),
    );
  }

  Widget _buildBranchNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Branch Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.store),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _branchName = value?.trim() ?? '',
    );
  }

  Widget _buildUPIField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'UPI ID',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.qr_code),
      ),
      textInputAction: TextInputAction.next,
      onSaved: (value) => _upiId = value?.trim() ?? '',
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
            onPressed: () => _saveBankAccount(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveBankAccount(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveBankAccount(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveBankAccount(saveAndNew: true),
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
