class CollectionReportRequest {
  final int compId;
  final int branchId;
  final int customerId;
  final String fromDate;
  final String toDate;
  final String paymentMode;
  final String search;
  final int pageNumber;
  final int pageSize;

  CollectionReportRequest({
    required this.compId,
    required this.branchId,
    required this.customerId,
    required this.fromDate,
    required this.toDate,
    required this.paymentMode,
    required this.search,
    required this.pageNumber,
    required this.pageSize,
  });

  Map<String, dynamic> toJson() {
    return {
      "compId": compId,
      "branchId": branchId,
      "customerId": customerId,
      "fromDate": fromDate,
      "toDate": toDate,
      "paymentMode": paymentMode,
      "search": search,
      "pageNumber": pageNumber,
      "pageSize": pageSize,
    };
  }
}

class CollectionReportResponse {
  final bool status;
  final String message;
  final List<CollectionReportData> data;
  final String? error;

  CollectionReportResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory CollectionReportResponse.fromJson(Map<String, dynamic> json) {
    return CollectionReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)?.map((e) => CollectionReportData.fromJson(e)).toList() ?? [],
      error: json['error'],
    );
  }
}

class CollectionReportData {
  final int receiptMasterId;
  final String receiptMasterReceiptNo;
  final DateTime? receiptMasterReceiptDate;
  final String receiptMasterStatus;
  final bool receiptMasterIsActive;
  final int receiptMasterCompId;
  final int compId;
  final String compName;
  final int receiptMasterBranchId;
  final int branchId;
  final String branchName;
  final int receiptMasterCustomerId;
  final String custCode;
  final String custName;
  final String custMobileNo;
  final String custEmail;
  final int receiptMasterLedgerId;
  final String accLedgerName;
  final double totalCollection;
  final double cashAmount;
  final double upiAmount;
  final double cardAmount;
  final double chequeAmount;
  final double bankAmount;
  final double otherAmount;
  final String receiptMasterChequeNo;
  final DateTime? receiptMasterChequeDate;
  final String receiptMasterBankName;
  final String receiptMasterBankReferenceNo;
  final String receiptMasterNEFTType;
  final String receiptMasterNEFTReferenceNo;
  final String receiptMasterOtherPaymentType;
  final String receiptMasterOtherReferenceNo;
  final DateTime? receiptMasterOtherDate;
  final String receiptMasterOtherRemark;
  final String receiptMasterRemark;
  final int receiptMasterCreatedBy;
  final DateTime? receiptMasterCreatedDate;
  final int receiptMasterModifiedBy;
  final DateTime? receiptMasterModifiedDate;
  final int currentPage;
  final int pageSize;

  CollectionReportData({
    required this.receiptMasterId,
    required this.receiptMasterReceiptNo,
    this.receiptMasterReceiptDate,
    required this.receiptMasterStatus,
    required this.receiptMasterIsActive,
    required this.receiptMasterCompId,
    required this.compId,
    required this.compName,
    required this.receiptMasterBranchId,
    required this.branchId,
    required this.branchName,
    required this.receiptMasterCustomerId,
    required this.custCode,
    required this.custName,
    required this.custMobileNo,
    required this.custEmail,
    required this.receiptMasterLedgerId,
    required this.accLedgerName,
    required this.totalCollection,
    required this.cashAmount,
    required this.upiAmount,
    required this.cardAmount,
    required this.chequeAmount,
    required this.bankAmount,
    required this.otherAmount,
    required this.receiptMasterChequeNo,
    this.receiptMasterChequeDate,
    required this.receiptMasterBankName,
    required this.receiptMasterBankReferenceNo,
    required this.receiptMasterNEFTType,
    required this.receiptMasterNEFTReferenceNo,
    required this.receiptMasterOtherPaymentType,
    required this.receiptMasterOtherReferenceNo,
    this.receiptMasterOtherDate,
    required this.receiptMasterOtherRemark,
    required this.receiptMasterRemark,
    required this.receiptMasterCreatedBy,
    this.receiptMasterCreatedDate,
    required this.receiptMasterModifiedBy,
    this.receiptMasterModifiedDate,
    required this.currentPage,
    required this.pageSize,
  });

  factory CollectionReportData.fromJson(Map<String, dynamic> json) {
    return CollectionReportData(
      receiptMasterId: json['receiptMaster_Id'] ?? 0,
      receiptMasterReceiptNo: json['receiptMaster_ReceiptNo'] ?? '',
      receiptMasterReceiptDate: json['receiptMaster_ReceiptDate'] != null ? DateTime.tryParse(json['receiptMaster_ReceiptDate']) : null,
      receiptMasterStatus: json['receiptMaster_Status'] ?? '',
      receiptMasterIsActive: json['receiptMaster_IsActive'] ?? false,
      receiptMasterCompId: json['receiptMaster_CompId'] ?? 0,
      compId: json['comp_Id'] ?? 0,
      compName: json['comp_Name'] ?? '',
      receiptMasterBranchId: json['receiptMaster_BranchId'] ?? 0,
      branchId: json['branch_Id'] ?? 0,
      branchName: json['branch_Name'] ?? '',
      receiptMasterCustomerId: json['receiptMaster_CustomerId'] ?? 0,
      custCode: json['cust_Code'] ?? '',
      custName: json['cust_Name'] ?? '',
      custMobileNo: json['cust_MobileNo'] ?? '',
      custEmail: json['cust_Email'] ?? '',
      receiptMasterLedgerId: json['receiptMaster_LedgerId'] ?? 0,
      accLedgerName: json['accLedger_Name'] ?? '',
      totalCollection: (json['totalCollection'] ?? 0).toDouble(),
      cashAmount: (json['cashAmount'] ?? 0).toDouble(),
      upiAmount: (json['upiAmount'] ?? 0).toDouble(),
      cardAmount: (json['cardAmount'] ?? 0).toDouble(),
      chequeAmount: (json['chequeAmount'] ?? 0).toDouble(),
      bankAmount: (json['bankAmount'] ?? 0).toDouble(),
      otherAmount: (json['otherAmount'] ?? 0).toDouble(),
      receiptMasterChequeNo: json['receiptMaster_ChequeNo'] ?? '',
      receiptMasterChequeDate: json['receiptMaster_ChequeDate'] != null ? DateTime.tryParse(json['receiptMaster_ChequeDate']) : null,
      receiptMasterBankName: json['receiptMaster_BankName'] ?? '',
      receiptMasterBankReferenceNo: json['receiptMaster_BankReferenceNo'] ?? '',
      receiptMasterNEFTType: json['receiptMaster_NEFTType'] ?? '',
      receiptMasterNEFTReferenceNo: json['receiptMaster_NEFTReferenceNo'] ?? '',
      receiptMasterOtherPaymentType: json['receiptMaster_OtherPaymentType'] ?? '',
      receiptMasterOtherReferenceNo: json['receiptMaster_OtherReferenceNo'] ?? '',
      receiptMasterOtherDate: json['receiptMaster_OtherDate'] != null ? DateTime.tryParse(json['receiptMaster_OtherDate']) : null,
      receiptMasterOtherRemark: json['receiptMaster_OtherRemark'] ?? '',
      receiptMasterRemark: json['receiptMaster_Remark'] ?? '',
      receiptMasterCreatedBy: json['receiptMaster_CreatedBy'] ?? 0,
      receiptMasterCreatedDate: json['receiptMaster_CreatedDate'] != null ? DateTime.tryParse(json['receiptMaster_CreatedDate']) : null,
      receiptMasterModifiedBy: json['receiptMaster_ModifiedBy'] ?? 0,
      receiptMasterModifiedDate: json['receiptMaster_ModifiedDate'] != null ? DateTime.tryParse(json['receiptMaster_ModifiedDate']) : null,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }
}
