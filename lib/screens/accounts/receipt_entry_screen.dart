import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/save_clear_shortcuts.dart';
import '../../widgets/customer_dropdown.dart';
import '../../services/api_service.dart';
import '../../utils/api_constants.dart';

import '../../services/session_service.dart';

class ReceiptMasterScreen extends StatefulWidget {
  const ReceiptMasterScreen({super.key});

  @override
  State<ReceiptMasterScreen> createState() => _ReceiptMasterScreenState();
}

class _ReceiptMasterScreenState extends State<ReceiptMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final TextEditingController _cashAmountController = TextEditingController();
  final TextEditingController _cashRemarkController = TextEditingController();

  final TextEditingController _upiAmountController = TextEditingController();
  final TextEditingController _upiTransactionNoController = TextEditingController();
  final TextEditingController _upiReferenceNoController = TextEditingController();

  final TextEditingController _chequeAmountController = TextEditingController();
  final TextEditingController _chequeNoController = TextEditingController();
  final TextEditingController _chequeBankNameController = TextEditingController();
  final TextEditingController _chequeBranchNameController = TextEditingController();

  final TextEditingController _bankAmountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNoController = TextEditingController();
  final TextEditingController _bankTransactionNoController = TextEditingController();
  final TextEditingController _bankReferenceNoController = TextEditingController();

  final TextEditingController _cardAmountController = TextEditingController();

  final TextEditingController _otherAmountController = TextEditingController();
  final TextEditingController _otherTypeController = TextEditingController();
  final TextEditingController _otherReferenceController = TextEditingController();
  final TextEditingController _otherRemarksController = TextEditingController();

  final FocusNode _customerNode = FocusNode();
  final FocusNode _receiptDateNode = FocusNode();
  final FocusNode _invoiceNoNode = FocusNode();
  final FocusNode _cashAmountNode = FocusNode();
  final FocusNode _cashRemarkNode = FocusNode();
  final FocusNode _upiAmountNode = FocusNode();
  final FocusNode _upiTxnNode = FocusNode();
  final FocusNode _upiRefNode = FocusNode();
  final FocusNode _chequeAmountNode = FocusNode();
  final FocusNode _chequeNoNode = FocusNode();
  final FocusNode _chequeDateNode = FocusNode();
  final FocusNode _chequeBankNode = FocusNode();
  final FocusNode _chequeBranchNode = FocusNode();
  final FocusNode _bankAmountNode = FocusNode();
  final FocusNode _bankTransferTypeNode = FocusNode();
  final FocusNode _bankNameNode = FocusNode();
  final FocusNode _bankAccountNode = FocusNode();
  final FocusNode _bankTxnNode = FocusNode();
  final FocusNode _bankRefNode = FocusNode();
  final FocusNode _bankDateNode = FocusNode();
  final FocusNode _cardAmountNode = FocusNode();
  final FocusNode _otherAmountNode = FocusNode();
  final FocusNode _otherTypeNode = FocusNode();
  final FocusNode _otherRefNode = FocusNode();
  final FocusNode _otherDateNode = FocusNode();
  final FocusNode _otherRemarkNode = FocusNode();
  final FocusNode _remarksNode = FocusNode();

  DateTime _receiptDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _chequeDate;
  DateTime? _bankDate;
  DateTime? _otherDate;

  String? _selectedBankTransferType;
  int? _selectedAccountId;
  int? _selectedLedgerId;
  bool _isLoading = false;

  List<dynamic> _pendingInvoices = [];
  dynamic _selectedInvoice;
  bool _isLoadingInvoices = false;

  static const List<String> _bankTransferTypes = [
    'NEFT',
    'RTGS',
    'IMPS',
    'Fund Transfer',
  ];

  Future<void> _fetchPendingInvoices(int customerId) async {
    setState(() {
      _isLoadingInvoices = true;
      _pendingInvoices = [];
      _selectedInvoice = null;
      _invoiceNoController.clear();
    });

    try {
      final compId = sessionService.selectedCompId ?? 1;
      final branchId = sessionService.selectedBranchId ?? 1;

      final response = await apiService.get(
        ApiConstants.getAllPendingAmountEndpoint,
        queryParameters: {
          'CompId': compId.toString(),
          'BranchId': branchId.toString(),
          'CustomerId': customerId.toString(),
          'PageNumber': '1',
          'PageSize': '100',
        },
      );
      if (response != null && response['status'] == true && response['data'] != null) {
        if (response['data']['items'] != null) {
          setState(() {
            _pendingInvoices = response['data']['items'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending invoices: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInvoices = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _cashAmountController,
      _upiAmountController,
      _chequeAmountController,
      _bankAmountController,
      _cardAmountController,
      _otherAmountController,
    ]) {
      controller.addListener(_onAmountChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCustomer());
  }

  void _focusCustomer() {
    if (!mounted) return;
    _customerNode.requestFocus();
  }

  @override
  void dispose() {
    for (final controller in [
      _cashAmountController,
      _upiAmountController,
      _chequeAmountController,
      _bankAmountController,
      _cardAmountController,
      _otherAmountController,
    ]) {
      controller.removeListener(_onAmountChanged);
    }
    for (final node in _allFocusNodes) {
      node.dispose();
    }
    for (final controller in [
      _invoiceNoController,
      _remarksController,
      _cashAmountController,
      _cashRemarkController,
      _upiAmountController,
      _upiTransactionNoController,
      _upiReferenceNoController,
      _chequeAmountController,
      _chequeNoController,
      _chequeBankNameController,
      _chequeBranchNameController,
      _bankAmountController,
      _bankNameController,
      _bankAccountNoController,
      _bankTransactionNoController,
      _bankReferenceNoController,
      _cardAmountController,
      _otherAmountController,
      _otherTypeController,
      _otherReferenceController,
      _otherRemarksController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<FocusNode> get _allFocusNodes => [
    _customerNode,
    _receiptDateNode,
    _invoiceNoNode,
    _cashAmountNode,
    _cashRemarkNode,
    _upiAmountNode,
    _upiTxnNode,
    _upiRefNode,
    _chequeAmountNode,
    _chequeNoNode,
    _chequeDateNode,
    _chequeBankNode,
    _chequeBranchNode,
    _bankAmountNode,
    _bankTransferTypeNode,
    _bankNameNode,
    _bankAccountNode,
    _bankTxnNode,
    _bankRefNode,
    _bankDateNode,
    _cardAmountNode,
    _otherAmountNode,
    _otherTypeNode,
    _otherRefNode,
    _otherDateNode,
    _otherRemarkNode,
    _remarksNode,
  ];

  List<FocusNode> get _visibleFocusOrder {
    final nodes = <FocusNode>[
      _customerNode,
      _receiptDateNode,
      _invoiceNoNode,
      _cashAmountNode,
      _upiAmountNode,
      _chequeAmountNode,
      _bankAmountNode,
      _cardAmountNode,
      _otherAmountNode,
    ];
    if (_cashAmount > 0) nodes.add(_cashRemarkNode);
    if (_upiAmount > 0) {
      nodes.addAll([_upiTxnNode, _upiRefNode]);
    }
    if (_chequeAmount > 0) {
      nodes.addAll([
        _chequeNoNode,
        _chequeDateNode,
        _chequeBankNode,
        _chequeBranchNode,
      ]);
    }
    if (_bankAmount > 0) {
      nodes.addAll([
        _bankTransferTypeNode,
        _bankNameNode,
        _bankAccountNode,
        _bankTxnNode,
        _bankRefNode,
        _bankDateNode,
      ]);
    }
    if (_otherAmount > 0) {
      nodes.addAll([
        _otherTypeNode,
        _otherRefNode,
        _otherDateNode,
        _otherRemarkNode,
      ]);
    }
    nodes.add(_remarksNode);
    return nodes;
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  void _focusNext(FocusNode current) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final order = _visibleFocusOrder;
      final index = order.indexOf(current);
      if (index >= 0 && index < order.length - 1) {
        order[index + 1].requestFocus();
      }
    });
  }

  double _parseAmount(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0.0;
  }

  double get _cashAmount => _parseAmount(_cashAmountController);
  double get _upiAmount => _parseAmount(_upiAmountController);
  double get _chequeAmount => _parseAmount(_chequeAmountController);
  double get _bankAmount => _parseAmount(_bankAmountController);
  double get _cardAmount => _parseAmount(_cardAmountController);
  double get _otherAmount => _parseAmount(_otherAmountController);

  double get _totalAmount =>
      _cashAmount +
      _upiAmount +
      _chequeAmount +
      _bankAmount +
      _cardAmount +
      _otherAmount;

  Future<DateTime?> _selectDate(DateTime initialDate) async {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _KeyboardDatePickerDialog(
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
      },
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _invoiceNoController.clear();
    _remarksController.clear();
    _cashAmountController.clear();
    _cashRemarkController.clear();
    _upiAmountController.clear();
    _upiTransactionNoController.clear();
    _upiReferenceNoController.clear();
    _chequeAmountController.clear();
    _chequeNoController.clear();
    _chequeBankNameController.clear();
    _chequeBranchNameController.clear();
    _bankAmountController.clear();
    _bankNameController.clear();
    _bankAccountNoController.clear();
    _bankTransactionNoController.clear();
    _bankReferenceNoController.clear();
    _cardAmountController.clear();
    _otherAmountController.clear();
    _otherTypeController.clear();
    _otherReferenceController.clear();
    _otherRemarksController.clear();
    setState(() {
      _receiptDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      _chequeDate = null;
      _bankDate = null;
      _otherDate = null;
      _selectedBankTransferType = null;
      _selectedAccountId = null;
      _selectedLedgerId = null;
      _selectedInvoice = null;
      _pendingInvoices = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCustomer());
  }

  Future<void> _saveReceipt() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountId == null || _selectedAccountId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a party / customer')),
      );
      _focusCustomer();
      return;
    }

    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one receipt mode amount')),
      );
      _cashAmountNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await sessionService.getUserData();
      final empId = user?.empId ?? 0;
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;
      
      final requestData = {
        "masterData": {
          "receiptMaster_Id": 0,
          "receiptMaster_CompId": compId,
          "receiptMaster_BranchId": branchId,
          "receiptMaster_ReceiptDate": _receiptDate.toIso8601String(),
          "receiptMaster_CustomerId": _selectedAccountId,
          "receiptMaster_LedgerId": _selectedLedgerId ?? 0,
          "receiptMaster_TotalAmount": _totalAmount,
          "receiptMaster_CashAmount": _cashAmount,
          "receiptMaster_UPIAmount": _upiAmount,
          "receiptMaster_CardAmount": _cardAmount,
          "receiptMaster_ChequeAmount": _chequeAmount,
          "receiptMaster_BankAmount": _bankAmount,
          "receiptMaster_OtherAmount": _otherAmount,
          "receiptMaster_ChequeNo": _chequeNoController.text.trim(),
          "receiptMaster_ChequeDate": _chequeAmount > 0 ? (_chequeDate ?? _receiptDate).toIso8601String() : _receiptDate.toIso8601String(),
          "receiptMaster_BankName": _bankNameController.text.trim(),
          "receiptMaster_BankReferenceNo": _bankReferenceNoController.text.trim(),
          "receiptMaster_NEFTType": _selectedBankTransferType ?? "",
          "receiptMaster_NEFTReferenceNo": _bankTransactionNoController.text.trim(),
          "receiptMaster_OtherPaymentType": _otherTypeController.text.trim(),
          "receiptMaster_OtherReferenceNo": _otherReferenceController.text.trim(),
          "receiptMaster_OtherDate": _otherAmount > 0 ? (_otherDate ?? _receiptDate).toIso8601String() : _receiptDate.toIso8601String(),
          "receiptMaster_OtherRemark": _otherRemarksController.text.trim(),
          "receiptMaster_Remark": _remarksController.text.trim(),
          "receiptMaster_Status": "Active",
          "receiptMaster_IsActive": true,
          "receiptMaster_CreatedBy": empId,
          "receiptMaster_ModifiedBy": empId
        },
        "detailData": [
          {
            "receiptDetail_CompId": compId,
            "receiptDetail_BranchId": branchId,
            "receiptDetail_CustomerId": _selectedAccountId,
            "receiptDetail_LedgerId": _selectedLedgerId ?? 0,
            "receiptDetail_SalesMasterId": _selectedInvoice?['salesMaster_Id'] ?? 0,
            "receiptDetail_InvoiceAmount": _totalAmount,
            "receiptDetail_PendingAmount": 0,
            "receiptDetail_ReceivedAmount": _totalAmount,
            "receiptDetail_RemainingAmount": 0,
            "receiptDetail_Remark": _remarksController.text.trim(),
            "receiptDetail_CreatedBy": empId,
            "receiptDetail_ModifiedBy": empId
          }
        ]
      };

      final response = await apiService.post(
        ApiConstants.insertOrUpdateReceiptEntryEndpoint,
        body: requestData,
        requiresAuth: true,
      );

      if (!mounted) return;

      if (response != null && response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(response['message'] ?? 'Receipt saved successfully!')),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        String errorMsg = 'Failed to save receipt';
        if (response != null) {
          errorMsg = response['message'] ?? response['error'] ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveReceipt();
      },
      onClear: _clearForm,
      child: DirectBackScope(
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.15),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 920),
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
            appBar: AppBar(title: const Text('Receipt Entry')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: formCard,
            ),
          );
        },
      ),
    ));
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
        padding: EdgeInsets.all(isDesktop ? 16.0 : 18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sectionHeader(
                theme,
                'Voucher Details',
                Icons.description_outlined,
              ),
              CustomerDropdown(
                selectedCustomerId: _selectedAccountId,
                isRequired: true,
                autofocus: true,
                focusNode: _customerNode,
                nextFocusNode: _receiptDateNode,
                labelText: 'Party / Customer',
                hintText: 'Select party / customer',
                prefixIcon: Icon(
                  Icons.business_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                onChanged: (customer) {
                  setState(() {
                    _selectedAccountId = customer?.custId;
                    _selectedLedgerId = customer?.custLedgerId ?? 0;
                  });
                  if (customer?.custId != null) {
                    _fetchPendingInvoices(customer!.custId!);
                  } else {
                    setState(() {
                      _pendingInvoices = [];
                      _selectedInvoice = null;
                      _invoiceNoController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _responsiveRow(isDesktop, [
                _buildDateField(
                  theme: theme,
                  label: 'Receipt Date *',
                  date: _receiptDate,
                  node: _receiptDateNode,
                  onPicked: (date) => setState(() => _receiptDate = date),
                ),
                _isLoadingInvoices
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : DropdownButtonFormField<dynamic>(
                        value: _selectedInvoice,
                        focusNode: _invoiceNoNode,
                        decoration: _inputDecoration('Select Invoice No', theme).copyWith(
                          prefixIcon: const Icon(Icons.receipt_long, size: 20),
                        ),
                        items: _pendingInvoices.map((invoice) {
                          return DropdownMenuItem<dynamic>(
                            value: invoice,
                            child: Text('${invoice['salesMaster_InvoiceNo']} - ₹${invoice['salesMaster_BalanceAmount']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedInvoice = val;
                            if (val != null) {
                              _invoiceNoController.text = val['salesMaster_InvoiceNo']?.toString() ?? '';
                              _cashAmountController.text = val['salesMaster_BalanceAmount']?.toString() ?? '0';
                            } else {
                              _invoiceNoController.clear();
                              _cashAmountController.clear();
                            }
                          });
                          _focusNext(_invoiceNoNode);
                        },
                      ),
              ]),
              _sectionHeader(
                theme,
                'Receipt Breakup',
                Icons.account_balance_wallet_outlined,
              ),
              _buildBreakupAmounts(theme, isDesktop),
              const SizedBox(height: 12),
              _buildTotalSummary(theme),
              if (_cashAmount > 0) ...[
                _sectionHeader(theme, 'Cash Details', Icons.payments_outlined),
                _buildTextField(
                  controller: _cashRemarkController,
                  label: 'Cash Remark',
                  theme: theme,
                  focusNode: _cashRemarkNode,
                ),
              ],
              if (_upiAmount > 0) ...[
                _sectionHeader(theme, 'UPI Details', Icons.qr_code_2_rounded),
                _responsiveRow(isDesktop, [
                  _buildTextField(
                    controller: _upiTransactionNoController,
                    label: 'UPI Transaction No',
                    theme: theme,
                    focusNode: _upiTxnNode,
                  ),
                  _buildTextField(
                    controller: _upiReferenceNoController,
                    label: 'UPI Reference No',
                    theme: theme,
                    focusNode: _upiRefNode,
                  ),
                ]),
              ],
              if (_chequeAmount > 0) ...[
                _sectionHeader(theme, 'Cheque Details', Icons.money_outlined),
                _responsiveRow(isDesktop, [
                  _buildTextField(
                    controller: _chequeNoController,
                    label: 'Cheque No',
                    theme: theme,
                    focusNode: _chequeNoNode,
                  ),
                  _buildDateField(
                    theme: theme,
                    label: 'Cheque Date',
                    date: _chequeDate,
                    node: _chequeDateNode,
                    placeholder: 'Select Date',
                    onPicked: (date) => setState(() => _chequeDate = date),
                  ),
                ]),
                const SizedBox(height: 16),
                _responsiveRow(isDesktop, [
                  _buildTextField(
                    controller: _chequeBankNameController,
                    label: 'Cheque Bank Name',
                    theme: theme,
                    focusNode: _chequeBankNode,
                  ),
                  _buildTextField(
                    controller: _chequeBranchNameController,
                    label: 'Cheque Branch Name',
                    theme: theme,
                    focusNode: _chequeBranchNode,
                  ),
                ]),
              ],
              if (_bankAmount > 0) ...[
                _sectionHeader(
                  theme,
                  'Bank Transfer Details',
                  Icons.account_balance_outlined,
                ),
                _responsiveRow(isDesktop, [
                  _buildBankTransferTypeField(theme),
                  _buildTextField(
                    controller: _bankNameController,
                    label: 'Bank Name',
                    theme: theme,
                    focusNode: _bankNameNode,
                  ),
                ]),
                const SizedBox(height: 16),
                _responsiveRow(isDesktop, [
                  _buildTextField(
                    controller: _bankAccountNoController,
                    label: 'Bank Account No',
                    theme: theme,
                    focusNode: _bankAccountNode,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    controller: _bankTransactionNoController,
                    label: 'Bank Transaction No',
                    theme: theme,
                    focusNode: _bankTxnNode,
                  ),
                ]),
                const SizedBox(height: 16),
                _responsiveRow(isDesktop, [
                  _buildTextField(
                    controller: _bankReferenceNoController,
                    label: 'Bank Reference No',
                    theme: theme,
                    focusNode: _bankRefNode,
                  ),
                  _buildDateField(
                    theme: theme,
                    label: 'Bank Date',
                    date: _bankDate,
                    node: _bankDateNode,
                    placeholder: 'Select Date',
                    onPicked: (date) => setState(() => _bankDate = date),
                  ),
                ]),
              ],
              if (_otherAmount > 0) ...[
                _sectionHeader(
                  theme,
                  'Other Receipt Details',
                  Icons.more_horiz_rounded,
                ),
                _responsiveRow(isDesktop, [
                  _buildTextField(
                    controller: _otherTypeController,
                    label: 'Other Receipt Type',
                    theme: theme,
                    focusNode: _otherTypeNode,
                  ),
                  _buildTextField(
                    controller: _otherReferenceController,
                    label: 'Other Reference No',
                    theme: theme,
                    focusNode: _otherRefNode,
                  ),
                ]),
                const SizedBox(height: 16),
                _responsiveRow(isDesktop, [
                  _buildDateField(
                    theme: theme,
                    label: 'Other Date',
                    date: _otherDate,
                    node: _otherDateNode,
                    placeholder: 'Select Date',
                    onPicked: (date) => setState(() => _otherDate = date),
                  ),
                  _buildTextField(
                    controller: _otherRemarksController,
                    label: 'Other Remark',
                    theme: theme,
                    focusNode: _otherRemarkNode,
                  ),
                ]),
              ],
              const SizedBox(height: 8),
              _sectionHeader(theme, 'Remarks', Icons.notes_outlined),
              _buildTextField(
                controller: _remarksController,
                label: 'Remark',
                theme: theme,
                focusNode: _remarksNode,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 28),
              _buildActions(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }

  Widget _responsiveRow(bool isDesktop, List<Widget> children) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _buildBreakupAmounts(ThemeData theme, bool isDesktop) {
    final fields = [
      _buildModeAmountField(
        'Cash',
        _cashAmountController,
        _cashAmountNode,
        theme,
      ),
      _buildModeAmountField('UPI', _upiAmountController, _upiAmountNode, theme),
      _buildModeAmountField(
        'Cheque',
        _chequeAmountController,
        _chequeAmountNode,
        theme,
      ),
      _buildModeAmountField(
        'Bank',
        _bankAmountController,
        _bankAmountNode,
        theme,
      ),
      _buildModeAmountField(
        'Card',
        _cardAmountController,
        _cardAmountNode,
        theme,
      ),
      _buildModeAmountField(
        'Other',
        _otherAmountController,
        _otherAmountNode,
        theme,
      ),
    ];

    if (!isDesktop) {
      return Column(
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            fields[i],
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 16),
            Expanded(child: fields[1]),
            const SizedBox(width: 16),
            Expanded(child: fields[2]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: fields[3]),
            const SizedBox(width: 16),
            Expanded(child: fields[4]),
            const SizedBox(width: 16),
            Expanded(child: fields[5]),
          ],
        ),
      ],
    );
  }

  Widget _buildModeAmountField(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    ThemeData theme,
  ) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: _inputDecoration(
        label,
        theme,
      ).copyWith(prefixIcon: const Icon(Icons.currency_rupee, size: 18)),
      onEditingComplete: () => _focusNext(focusNode),
    );
  }

  Widget _buildTotalSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            'Total Amount',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '₹${_totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required ThemeData theme,
    required String label,
    required DateTime? date,
    required FocusNode node,
    required ValueChanged<DateTime> onPicked,
    String? placeholder,
  }) {
    Future<void> pickAndMove() async {
      final picked = await _selectDate(date ?? DateTime.now());
      if (!mounted) return;
      if (picked != null) {
        onPicked(picked);
        _focusNext(node);
      } else {
        node.requestFocus();
      }
    }

    return Focus(
      focusNode: node,
      onFocusChange: (_) {
        if (mounted) setState(() {});
      },
      onKeyEvent: (focus, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          pickAndMove();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: _isLoading ? null : pickAndMove,
        child: InputDecorator(
          isFocused: node.hasFocus,
          decoration: _inputDecoration(
            label,
            theme,
          ).copyWith(prefixIcon: const Icon(Icons.calendar_today, size: 20)),
          child: Text(
            date != null
                ? _dateFormat.format(date)
                : (placeholder ?? 'Select Date'),
          ),
        ),
      ),
    );
  }

  Widget _buildBankTransferTypeField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedBankTransferType,
      focusNode: _bankTransferTypeNode,
      decoration: _inputDecoration('Bank Transfer Type', theme),
      items: _bankTransferTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: _isLoading
          ? null
          : (val) {
              setState(() => _selectedBankTransferType = val);
              _focusNext(_bankTransferTypeNode);
            },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    FocusNode? focusNode,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: _inputDecoration(
        label,
        theme,
      ).copyWith(prefixIcon: prefixIcon),
      onEditingComplete: () {
        if (focusNode != null) {
          _focusNext(focusNode);
        }
      },
    );
  }

  Widget _buildActions(bool isDesktop) {
    final saveButton = FilledButton(
      onPressed: _isLoading ? null : _saveReceipt,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 28 : 16,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Save Receipt'),
    );

    final clearButton = OutlinedButton(
      onPressed: _isLoading ? null : _clearForm,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 16,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Clear'),
    );

    final cancelButton = OutlinedButton(
      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 16,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Cancel'),
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          clearButton,
          const SizedBox(width: 12),
          cancelButton,
          const SizedBox(width: 12),
          saveButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        saveButton,
        const SizedBox(height: 10),
        clearButton,
        const SizedBox(height: 10),
        cancelButton,
      ],
    );
  }

  InputDecoration _inputDecoration(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _KeyboardDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _KeyboardDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_KeyboardDatePickerDialog> createState() =>
      _KeyboardDatePickerDialogState();
}

class _KeyboardDatePickerDialogState extends State<_KeyboardDatePickerDialog> {
  late DateTime _selectedDate;
  final FocusNode _okFocusNode = FocusNode();
  final FocusNode _dialogFocusNode = FocusNode();
  bool _canConfirm = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _canConfirm = true);
      _okFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _okFocusNode.dispose();
    _dialogFocusNode.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(_selectedDate);
  }

  void _cancel() {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _cancel();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _dialogFocusNode,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final isEnter =
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter;
            if (!isEnter) return KeyEventResult.ignored;
            if (!_canConfirm) return KeyEventResult.handled;
            if (_okFocusNode.hasFocus) return KeyEventResult.ignored;
            _confirm();
            return KeyEventResult.handled;
          },
          child: AlertDialog(
            title: const Text('Select Date'),
            content: SizedBox(
              width: 330,
              height: 340,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
            ),
            actions: [
              TextButton(onPressed: _cancel, child: const Text('Cancel')),
              FilledButton(
                focusNode: _okFocusNode,
                onPressed: _confirm,
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

