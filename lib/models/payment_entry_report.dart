class PaymentEntryReportRequest {
  final int compId;
  final int branchId;
  final String fromDate;
  final String toDate;
  final int? paymentMasterId;
  final String? paymentNo;
  final String? invoiceNo;
  final String? search;
  final String? paymentType;
  final String? status;
  final int page;
  final int pageSize;

  PaymentEntryReportRequest({
    required this.compId,
    required this.branchId,
    required this.fromDate,
    required this.toDate,
    this.paymentMasterId,
    this.paymentNo,
    this.invoiceNo,
    this.search,
    this.paymentType,
    this.status,
    required this.page,
    required this.pageSize,
  });

  Map<String, dynamic> toJson() {
    return {
      "CompId": compId,
      "BranchId": branchId,
      "FromDate": fromDate,
      "ToDate": toDate,
      if (paymentMasterId != null) "PaymentMaster_Id": paymentMasterId,
      if (paymentNo != null) "PaymentNo": paymentNo,
      if (invoiceNo != null) "InvoiceNo": invoiceNo,
      if (search != null) "Search": search,
      if (paymentType != null) "PaymentType": paymentType,
      if (status != null) "Status": status,
      "Page": page,
      "PageSize": pageSize,
    };
  }
}

class PaymentEntryReportResponse {
  final bool status;
  final String message;
  final PaymentEntryReportDataObj? data;
  final String? error;

  PaymentEntryReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory PaymentEntryReportResponse.fromJson(Map<String, dynamic> json) {
    return PaymentEntryReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PaymentEntryReportDataObj.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class PaymentEntryReportDataObj {
  final List<PaymentEntryReportData> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  PaymentEntryReportDataObj({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory PaymentEntryReportDataObj.fromJson(Map<String, dynamic> json) {
    return PaymentEntryReportDataObj(
      items: (json['items'] as List?)?.map((e) => PaymentEntryReportData.fromJson(e)).toList() ?? [],
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }
}

class PaymentEntryReportData {
  final int paymentMasterId;
  final String paymentMasterPaymentNo;
  final DateTime? paymentMasterPaymentDate;
  final String paymentMasterType;
  final String paymentMasterStatus;
  final int paymentMasterInvoiceId;
  final String paymentMasterInvoiceNo;
  final DateTime? paymentMasterInvoiceDate;
  final int paymentMasterAccountId;
  final double paymentMasterTotalAmount;
  final double paymentMasterCashAmount;
  final double paymentMasterUPIAmount;
  final double paymentMasterChequeAmount;
  final double paymentMasterBankAmount;
  final double paymentMasterCardAmount;
  final double paymentMasterOtherAmount;
  final String paymentModes;
  final String paymentMasterCashRemark;
  final String paymentMasterUPITransactionNo;
  final String paymentMasterUPIReferenceNo;
  final String paymentMasterChequeNo;
  final DateTime? paymentMasterChequeDate;
  final String paymentMasterChequeBankName;
  final String paymentMasterChequeBranchName;
  final String paymentMasterBankTransferType;
  final String paymentMasterBankName;
  final String paymentMasterBankAccountNo;
  final String paymentMasterBankTransactionNo;
  final String paymentMasterBankReferenceNo;
  final DateTime? paymentMasterBankDate;
  final String paymentMasterRemark;
  final int paymentMasterCreatedBy;
  final DateTime? paymentMasterCreatedDate;
  final int paymentMasterModifiedBy;
  final DateTime? paymentMasterModifiedDate;

  PaymentEntryReportData({
    required this.paymentMasterId,
    required this.paymentMasterPaymentNo,
    this.paymentMasterPaymentDate,
    required this.paymentMasterType,
    required this.paymentMasterStatus,
    required this.paymentMasterInvoiceId,
    required this.paymentMasterInvoiceNo,
    this.paymentMasterInvoiceDate,
    required this.paymentMasterAccountId,
    required this.paymentMasterTotalAmount,
    required this.paymentMasterCashAmount,
    required this.paymentMasterUPIAmount,
    required this.paymentMasterChequeAmount,
    required this.paymentMasterBankAmount,
    required this.paymentMasterCardAmount,
    required this.paymentMasterOtherAmount,
    required this.paymentModes,
    required this.paymentMasterCashRemark,
    required this.paymentMasterUPITransactionNo,
    required this.paymentMasterUPIReferenceNo,
    required this.paymentMasterChequeNo,
    this.paymentMasterChequeDate,
    required this.paymentMasterChequeBankName,
    required this.paymentMasterChequeBranchName,
    required this.paymentMasterBankTransferType,
    required this.paymentMasterBankName,
    required this.paymentMasterBankAccountNo,
    required this.paymentMasterBankTransactionNo,
    required this.paymentMasterBankReferenceNo,
    this.paymentMasterBankDate,
    required this.paymentMasterRemark,
    required this.paymentMasterCreatedBy,
    this.paymentMasterCreatedDate,
    required this.paymentMasterModifiedBy,
    this.paymentMasterModifiedDate,
  });

  factory PaymentEntryReportData.fromJson(Map<String, dynamic> json) {
    return PaymentEntryReportData(
      paymentMasterId: json['paymentMaster_Id'] ?? 0,
      paymentMasterPaymentNo: json['paymentMaster_PaymentNo'] ?? '',
      paymentMasterPaymentDate: json['paymentMaster_PaymentDate'] != null ? DateTime.tryParse(json['paymentMaster_PaymentDate']) : null,
      paymentMasterType: json['paymentMaster_Type'] ?? '',
      paymentMasterStatus: json['paymentMaster_Status'] ?? '',
      paymentMasterInvoiceId: json['paymentMaster_InvoiceId'] ?? 0,
      paymentMasterInvoiceNo: json['paymentMaster_InvoiceNo'] ?? '',
      paymentMasterInvoiceDate: json['paymentMaster_InvoiceDate'] != null ? DateTime.tryParse(json['paymentMaster_InvoiceDate']) : null,
      paymentMasterAccountId: json['paymentMaster_AccountId'] ?? 0,
      paymentMasterTotalAmount: (json['paymentMaster_TotalAmount'] ?? 0).toDouble(),
      paymentMasterCashAmount: (json['paymentMaster_CashAmount'] ?? 0).toDouble(),
      paymentMasterUPIAmount: (json['paymentMaster_UPIAmount'] ?? 0).toDouble(),
      paymentMasterChequeAmount: (json['paymentMaster_ChequeAmount'] ?? 0).toDouble(),
      paymentMasterBankAmount: (json['paymentMaster_BankAmount'] ?? 0).toDouble(),
      paymentMasterCardAmount: (json['paymentMaster_CardAmount'] ?? 0).toDouble(),
      paymentMasterOtherAmount: (json['paymentMaster_OtherAmount'] ?? 0).toDouble(),
      paymentModes: json['paymentModes'] ?? '',
      paymentMasterCashRemark: json['paymentMaster_CashRemark'] ?? '',
      paymentMasterUPITransactionNo: json['paymentMaster_UPITransactionNo'] ?? '',
      paymentMasterUPIReferenceNo: json['paymentMaster_UPIReferenceNo'] ?? '',
      paymentMasterChequeNo: json['paymentMaster_ChequeNo'] ?? '',
      paymentMasterChequeDate: json['paymentMaster_ChequeDate'] != null ? DateTime.tryParse(json['paymentMaster_ChequeDate']) : null,
      paymentMasterChequeBankName: json['paymentMaster_ChequeBankName'] ?? '',
      paymentMasterChequeBranchName: json['paymentMaster_ChequeBranchName'] ?? '',
      paymentMasterBankTransferType: json['paymentMaster_BankTransferType'] ?? '',
      paymentMasterBankName: json['paymentMaster_BankName'] ?? '',
      paymentMasterBankAccountNo: json['paymentMaster_BankAccountNo'] ?? '',
      paymentMasterBankTransactionNo: json['paymentMaster_BankTransactionNo'] ?? '',
      paymentMasterBankReferenceNo: json['paymentMaster_BankReferenceNo'] ?? '',
      paymentMasterBankDate: json['paymentMaster_BankDate'] != null ? DateTime.tryParse(json['paymentMaster_BankDate']) : null,
      paymentMasterRemark: json['paymentMaster_Remark'] ?? '',
      paymentMasterCreatedBy: json['paymentMaster_CreatedBy'] ?? 0,
      paymentMasterCreatedDate: json['paymentMaster_CreatedDate'] != null ? DateTime.tryParse(json['paymentMaster_CreatedDate']) : null,
      paymentMasterModifiedBy: json['paymentMaster_ModifiedBy'] ?? 0,
      paymentMasterModifiedDate: json['paymentMaster_ModifiedDate'] != null ? DateTime.tryParse(json['paymentMaster_ModifiedDate']) : null,
    );
  }
}
