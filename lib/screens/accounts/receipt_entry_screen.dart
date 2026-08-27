import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';

class ReceiptMasterScreen extends StatefulWidget {
  const ReceiptMasterScreen({super.key});

  @override
  State<ReceiptMasterScreen> createState() => _ReceiptMasterScreenState();
}

class _ReceiptMasterScreenState extends State<ReceiptMasterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final TextEditingController _otherTypeController = TextEditingController();
  final TextEditingController _otherReferenceController = TextEditingController();
  final TextEditingController _otherRemarksController = TextEditingController();

  DateTime _receiptDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _referenceDate;
  DateTime? _otherDate;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String? _selectedReceiptType;
  String? _selectedParty;
  String? _selectedReceiptMode = 'Cash';

  bool _isLoading = false;

  final List<String> _receiptModes = [
    'Cash',
    'Bank',
    'Cheque',
    'UPI',
    'NEFT',
    'RTGS',
    'Other'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    _otherTypeController.dispose();
    _otherReferenceController.dispose();
    _otherRemarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate, ValueChanged<DateTime> onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _saveReceipt() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Mock saving delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Receipt saved successfully!')),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          final formCard = _buildFormCard(context, isDesktop);

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
                      appBar: AppBar(
                        title: const Text('Receipt Entry'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: formCard,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Receipt Entry'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: formCard,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    return Card(
      elevation: isDesktop ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 28.0 : 18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Entry',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Record money received from a customer or party',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildReceiptDateField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildReceiptTypeField(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildPartyField(theme)),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _buildAmountField(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildReceiptModeField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAccountField(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildReferenceField(theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildReferenceDateField(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRemarksField(theme),
              ] else ...[
                _buildReceiptDateField(theme),
                const SizedBox(height: 16),
                _buildReceiptTypeField(theme),
                const SizedBox(height: 16),
                _buildPartyField(theme),
                const SizedBox(height: 16),
                _buildAmountField(theme),
                const SizedBox(height: 16),
                _buildReceiptModeField(theme),
                const SizedBox(height: 16),
                _buildAccountField(theme),
                const SizedBox(height: 16),
                _buildReferenceField(theme),
                const SizedBox(height: 16),
                _buildReferenceDateField(theme),
                const SizedBox(height: 16),
                _buildRemarksField(theme),
              ],

              if (_selectedReceiptMode == 'Other') ...[
                const SizedBox(height: 24),
                Text(
                  'Other Details',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildOtherTypeField(theme)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildOtherReferenceField(theme)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildOtherDateField(theme)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildOtherRemarksField(theme)),
                    ],
                  ),
                ] else ...[
                  _buildOtherTypeField(theme),
                  const SizedBox(height: 16),
                  _buildOtherReferenceField(theme),
                  const SizedBox(height: 16),
                  _buildOtherDateField(theme),
                  const SizedBox(height: 16),
                  _buildOtherRemarksField(theme),
                ]
              ],

              const SizedBox(height: 28),
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        _formKey.currentState?.reset();
                        setState(() {
                          _selectedReceiptMode = 'Cash';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : _saveReceipt,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Receipt'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isLoading ? null : _saveReceipt,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Receipt'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        _formKey.currentState?.reset();
                        setState(() {
                          _selectedReceiptMode = 'Cash';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Clear'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptDateField(ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(context, _receiptDate, (date) => setState(() => _receiptDate = date)),
      child: InputDecorator(
        decoration: _inputDecoration('Receipt Date *', theme).copyWith(
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(_dateFormat.format(_receiptDate)),
      ),
    );
  }

  Widget _buildReceiptTypeField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedReceiptType,
      decoration: _inputDecoration('Receipt Type', theme),
      items: const [
        DropdownMenuItem(value: 'Advance', child: Text('Advance')),
        DropdownMenuItem(value: 'Against Bill', child: Text('Against Bill')),
        DropdownMenuItem(value: 'On Account', child: Text('On Account')),
      ],
      onChanged: (val) => setState(() => _selectedReceiptType = val),
    );
  }

  Widget _buildPartyField(ThemeData theme) {
    return TextFormField(
      decoration: _inputDecoration('Customer / Party *', theme).copyWith(
        prefixIcon: const Icon(Icons.person, size: 20),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
      onChanged: (val) => _selectedParty = val,
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: _inputDecoration('Amount *', theme).copyWith(
        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Invalid amount';
        return null;
      },
    );
  }

  Widget _buildReceiptModeField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedReceiptMode,
      decoration: _inputDecoration('Receipt Mode *', theme),
      items: _receiptModes.map((mode) => DropdownMenuItem(value: mode, child: Text(mode))).toList(),
      onChanged: (val) {
        setState(() {
          _selectedReceiptMode = val;
        });
      },
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildAccountField(ThemeData theme) {
    return TextFormField(
      controller: _accountController,
      decoration: _inputDecoration('Bank/Cash Account', theme),
    );
  }

  Widget _buildReferenceField(ThemeData theme) {
    return TextFormField(
      controller: _referenceController,
      decoration: _inputDecoration('Reference / Cheque No.', theme),
    );
  }

  Widget _buildReferenceDateField(ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(
        context, 
        _referenceDate ?? DateTime.now(), 
        (date) => setState(() => _referenceDate = date)
      ),
      child: InputDecorator(
        decoration: _inputDecoration('Reference Date', theme).copyWith(
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(_referenceDate != null ? _dateFormat.format(_referenceDate!) : 'Select Date'),
      ),
    );
  }

  Widget _buildRemarksField(ThemeData theme) {
    return TextFormField(
      controller: _remarksController,
      maxLines: 2,
      decoration: _inputDecoration('Remarks', theme),
    );
  }

  Widget _buildOtherTypeField(ThemeData theme) {
    return TextFormField(
      controller: _otherTypeController,
      decoration: _inputDecoration('Other Receipt Type', theme),
    );
  }

  Widget _buildOtherReferenceField(ThemeData theme) {
    return TextFormField(
      controller: _otherReferenceController,
      decoration: _inputDecoration('Other Reference No.', theme),
    );
  }

  Widget _buildOtherDateField(ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(
        context, 
        _otherDate ?? DateTime.now(), 
        (date) => setState(() => _otherDate = date)
      ),
      child: InputDecorator(
        decoration: _inputDecoration('Other Date', theme).copyWith(
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(_otherDate != null ? _dateFormat.format(_otherDate!) : 'Select Date'),
      ),
    );
  }

  Widget _buildOtherRemarksField(ThemeData theme) {
    return TextFormField(
      controller: _otherRemarksController,
      decoration: _inputDecoration('Other Remark', theme),
    );
  }

  InputDecoration _inputDecoration(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
