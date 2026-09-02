import 'dart:io';

void main() {
  final paymentFile = File('lib/screens/accounts/payment_screen.dart');
  final receiptFile = File('lib/screens/accounts/receipt_entry_screen.dart');

  String content = paymentFile.readAsStringSync();

  // Rename classes and methods
  content = content.replaceAll('PaymentMasterScreen', 'ReceiptMasterScreen');
  content = content.replaceAll('_PaymentMasterScreenState', '_ReceiptMasterScreenState');
  
  // Replace imports
  content = content.replaceAll("import '../../models/payment.dart';", "");
  content = content.replaceAll("import '../../models/supplier_reports.dart';", "");
  content = content.replaceAll("import '../../services/payment_service.dart';", "");
  content = content.replaceAll("import '../../services/supplier_service.dart';", "");
  content = content.replaceAll("import '../../widgets/supplier_dropdown.dart';", "import '../../widgets/customer_dropdown.dart';");
  content = content.replaceAll("import '../../widgets/invoice_dropdown.dart';", "");
  
  // Fix state variables & text
  content = content.replaceAll("static const String _paymentType = 'Bill';", "static const String _receiptType = 'Bill';");
  content = content.replaceAll("Payment Entry", "Receipt Entry");
  content = content.replaceAll("Record a payment made to a supplier or party", "Record money received from a customer or party");
  content = content.replaceAll("Payment Breakup", "Receipt Breakup");
  content = content.replaceAll("_paymentDate", "_receiptDate");
  content = content.replaceAll("Payment Date", "Receipt Date");
  content = content.replaceAll("Other Payment", "Other Receipt");
  content = content.replaceAll("Payment saved successfully", "Receipt saved successfully");
  content = content.replaceAll("Failed to save payment", "Failed to save receipt");
  content = content.replaceAll("Save Payment", "Save Receipt");
  content = content.replaceAll("_savePayment", "_saveReceipt");
  
  // Supplier to Customer
  content = content.replaceAll("SupplierDropdown", "CustomerDropdown");
  content = content.replaceAll("_supplierNode", "_customerNode");
  content = content.replaceAll("_focusSupplier", "_focusCustomer");
  content = content.replaceAll("Party / Supplier", "Party / Customer");
  content = content.replaceAll("Select party / supplier", "Select party / customer");
  content = content.replaceAll("supplierId", "customerId");
  content = content.replaceAll("supplier", "customer");
  content = content.replaceAll("Supplier", "Customer");
  content = content.replaceAll("suppId", "custId");
  content = content.replaceAll("selectedSupplierId", "selectedCustomerId");
  
  // Remove pending invoice logic lines
  content = content.replaceAll(RegExp(r'\s*List<SupplierPendingInvoiceItem> _pendingInvoices = \[\];'), '');
  content = content.replaceAll(RegExp(r'\s*SupplierPendingInvoiceItem\? _selectedInvoice;'), '');
  content = content.replaceAll(RegExp(r'\s*bool _isLoadingInvoices = false;'), '');
  
  // The fetchPendingInvoices method
  content = content.replaceAll(RegExp(r'\s*Future<void> _fetchPendingInvoices.*?(?=\s*Future<void> _saveReceipt)', dotAll: true), '\n');
  
  // In the CustomerDropdown onChanged:
  content = content.replaceAll(RegExp(r'_selectedInvoice = null;\s*_invoiceNoController\.clear\(\);\s*_pendingInvoices = \[\];'), '');
  content = content.replaceAll(RegExp(r'if \(customer \!= null && customer\.custId > 0\) \{\s*_fetchPendingInvoices\(customer\.custId\);\s*\}'), '');

  // Remove InvoiceDropdown and its widget method
  content = content.replaceAll(RegExp(r'\s*Widget _buildInvoiceDropdown\(ThemeData theme\) \{.*?(?=\s*Widget _buildInvoiceDetailsCard)', dotAll: true), '''
  Widget _buildInvoiceDropdown(ThemeData theme) {
    return _buildTextField(
      controller: _invoiceNoController,
      label: 'Invoice No',
      theme: theme,
      focusNode: _invoiceNoNode,
    );
  }
''');

  // Remove _buildInvoiceDetailsCard
  content = content.replaceAll(RegExp(r'\s*Widget _buildInvoiceDetailsCard\(ThemeData theme\) \{.*?(?=\s*\}\s*\n\s*class _KeyboardDatePickerDialog)', dotAll: true), '');
  content = content.replaceAll(RegExp(r'\s*if \(_selectedInvoice \!= null\) _buildInvoiceDetailsCard\(theme\),'), '');
  
  // Replace the save logic
  final saveMethodStart = content.indexOf('Future<void> _saveReceipt() async {');
  final buildMethodStart = content.indexOf('@override\n  Widget build(BuildContext context) {');
  
  if (saveMethodStart != -1 && buildMethodStart != -1) {
    final beforeSave = content.substring(0, saveMethodStart);
    final afterSave = content.substring(buildMethodStart);
    
    const customSaveLogic = """
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
          "receiptMaster_LedgerId": 0,
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
            "receiptDetail_LedgerId": 0,
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
        Navigator.of(context).pop(true);
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

  """;
    content = beforeSave + customSaveLogic + afterSave;
  }
  
  // clearForm also needs _selectedInvoice and _pendingInvoices removed
  content = content.replaceAll(RegExp(r'\s*_selectedInvoice = null;\s*_pendingInvoices = \[\];'), '');
  
  // also _buildInvoiceDropdown in the form layout
  // It was already modified by regex, let's verify if _isLoadingInvoices is passed, it is not passed anymore because we replaced the whole widget build method
  
  receiptFile.writeAsStringSync(content);
}
