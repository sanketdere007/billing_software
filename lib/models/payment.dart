class PaymentUpsertRequest {
  final int paymentMasterId;
  final int companyId;
  final int branchId;
  final String? paymentNo;
  final String? paymentDate;
  final String? type;
  final double totalAmount;
  final int? invoiceId;
  final String? invoiceNo;
  final String? invoiceDate;
  final int accountId;
  final double cashAmount;
  final double upiAmount;
  final double chequeAmount;
  final double bankAmount;
  final double cardAmount;
  final double otherAmount;
  final String? cashRemark;
  final String? upiTransactionNo;
  final String? upiReferenceNo;
  final String? chequeNo;
  final String? chequeDate;
  final String? chequeBankName;
  final String? chequeBranchName;
  final String? bankTransferType;
  final String? bankName;
  final String? bankAccountNo;
  final String? bankTransactionNo;
  final String? bankReferenceNo;
  final String? bankDate;
  final String? otherPaymentType;
  final String? otherReferenceNo;
  final String? otherDate;
  final String? otherRemark;
  final String? remark;
  final String? status;
  final int createdBy;
  final int modifiedBy;

  PaymentUpsertRequest({
    this.paymentMasterId = 0,
    this.companyId = 0,
    this.branchId = 0,
    this.paymentNo,
    this.paymentDate,
    this.type,
    this.totalAmount = 0.0,
    this.invoiceId = 0,
    this.invoiceNo,
    this.invoiceDate,
    this.accountId = 0,
    this.cashAmount = 0.0,
    this.upiAmount = 0.0,
    this.chequeAmount = 0.0,
    this.bankAmount = 0.0,
    this.cardAmount = 0.0,
    this.otherAmount = 0.0,
    this.cashRemark,
    this.upiTransactionNo,
    this.upiReferenceNo,
    this.chequeNo,
    this.chequeDate,
    this.chequeBankName,
    this.chequeBranchName,
    this.bankTransferType,
    this.bankName,
    this.bankAccountNo,
    this.bankTransactionNo,
    this.bankReferenceNo,
    this.bankDate,
    this.otherPaymentType,
    this.otherReferenceNo,
    this.otherDate,
    this.otherRemark,
    this.remark,
    this.status,
    this.createdBy = 0,
    this.modifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentMaster_Id': paymentMasterId,
      'paymentMaster_CompId': companyId,
      'paymentMaster_BranchId': branchId,
      'paymentMaster_PaymentNo': paymentNo ?? '',
      'paymentMaster_PaymentDate': paymentDate,
      'paymentMaster_Type': type ?? '',
      'paymentMaster_TotalAmount': totalAmount,
      'paymentMaster_InvoiceId': invoiceId ?? 0,
      'paymentMaster_InvoiceNo': invoiceNo ?? '',
      'paymentMaster_InvoiceDate': invoiceDate,
      'paymentMaster_AccountId': accountId,
      'paymentMaster_CashAmount': cashAmount,
      'paymentMaster_UPIAmount': upiAmount,
      'paymentMaster_ChequeAmount': chequeAmount,
      'paymentMaster_BankAmount': bankAmount,
      'paymentMaster_CardAmount': cardAmount,
      'paymentMaster_OtherAmount': otherAmount,
      'paymentMaster_CashRemark': cashRemark ?? '',
      'paymentMaster_UPITransactionNo': upiTransactionNo ?? '',
      'paymentMaster_UPIReferenceNo': upiReferenceNo ?? '',
      'paymentMaster_ChequeNo': chequeNo ?? '',
      'paymentMaster_ChequeDate': chequeDate,
      'paymentMaster_ChequeBankName': chequeBankName ?? '',
      'paymentMaster_ChequeBranchName': chequeBranchName ?? '',
      'paymentMaster_BankTransferType': bankTransferType ?? '',
      'paymentMaster_BankName': bankName ?? '',
      'paymentMaster_BankAccountNo': bankAccountNo ?? '',
      'paymentMaster_BankTransactionNo': bankTransactionNo ?? '',
      'paymentMaster_BankReferenceNo': bankReferenceNo ?? '',
      'paymentMaster_BankDate': bankDate,
      'paymentMaster_OtherPaymentType': otherPaymentType ?? '',
      'paymentMaster_OtherReferenceNo': otherReferenceNo ?? '',
      'paymentMaster_OtherDate': otherDate,
      'paymentMaster_OtherRemark': otherRemark ?? '',
      'paymentMaster_Remark': remark ?? '',
      'paymentMaster_Status': status ?? 'Active',
      'paymentMaster_CreatedBy': createdBy,
      'paymentMaster_ModifiedBy': modifiedBy,
    };
  }
}

class PaymentUpsertResponseData {
  final bool status;
  final String message;
  final int paymentMasterId;
  final String paymentNo;

  PaymentUpsertResponseData({
    required this.status,
    required this.message,
    required this.paymentMasterId,
    required this.paymentNo,
  });

  factory PaymentUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return PaymentUpsertResponseData(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      paymentMasterId: json['paymentMaster_Id'] ?? 0,
      paymentNo: json['paymentMaster_PaymentNo'] ?? '',
    );
  }
}

class PaymentUpsertResponse {
  final bool status;
  final String message;
  final PaymentUpsertResponseData? data;
  final String? error;

  PaymentUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory PaymentUpsertResponse.fromJson(Map<String, dynamic> json) {
    return PaymentUpsertResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PaymentUpsertResponseData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}
