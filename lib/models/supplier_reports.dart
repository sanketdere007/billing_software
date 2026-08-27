class SupplierOutstandingReportItem {
  final int suppId;
  final String suppCode;
  final String suppName;
  final String suppCompanyName;
  final String suppMobileNo;
  final String suppAlternateMobileNo;
  final String suppEmail;
  final String suppGSTNo;
  final String suppPANNo;
  final int suppAreaId;
  final String suppAreaName;
  final int suppCityId;
  final String suppCityName;
  final int suppStateId;
  final String suppStateName;
  final String suppPincode;
  final String suppCountry;
  final int suppCompId;
  final String compName;
  final int suppBranchId;
  final String branchName;
  final int accLedgerId;
  final String accLedgerName;
  final int purchaseLedgerId;
  final int totalPurchaseCount;
  final double totalSubTotal;
  final double totalDiscountAmount;
  final double totalGSTAmount;
  final double totalOtherCharges;
  final double totalPurchaseAmount;
  final double totalPaidAmount;
  final double outstandingAmount;
  final bool suppIsActive;
  final int totalRecords;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  SupplierOutstandingReportItem({
    required this.suppId,
    required this.suppCode,
    required this.suppName,
    required this.suppCompanyName,
    required this.suppMobileNo,
    required this.suppAlternateMobileNo,
    required this.suppEmail,
    required this.suppGSTNo,
    required this.suppPANNo,
    required this.suppAreaId,
    required this.suppAreaName,
    required this.suppCityId,
    required this.suppCityName,
    required this.suppStateId,
    required this.suppStateName,
    required this.suppPincode,
    required this.suppCountry,
    required this.suppCompId,
    required this.compName,
    required this.suppBranchId,
    required this.branchName,
    required this.accLedgerId,
    required this.accLedgerName,
    required this.purchaseLedgerId,
    required this.totalPurchaseCount,
    required this.totalSubTotal,
    required this.totalDiscountAmount,
    required this.totalGSTAmount,
    required this.totalOtherCharges,
    required this.totalPurchaseAmount,
    required this.totalPaidAmount,
    required this.outstandingAmount,
    required this.suppIsActive,
    required this.totalRecords,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory SupplierOutstandingReportItem.fromJson(Map<String, dynamic> json) {
    return SupplierOutstandingReportItem(
      suppId: json['supp_Id'] ?? 0,
      suppCode: json['supp_Code'] ?? '',
      suppName: json['supp_Name'] ?? '',
      suppCompanyName: json['supp_CompanyName'] ?? '',
      suppMobileNo: json['supp_MobileNo'] ?? '',
      suppAlternateMobileNo: json['supp_AlternateMobileNo'] ?? '',
      suppEmail: json['supp_Email'] ?? '',
      suppGSTNo: json['supp_GSTNo'] ?? '',
      suppPANNo: json['supp_PANNo'] ?? '',
      suppAreaId: json['supp_AreaId'] ?? 0,
      suppAreaName: json['supp_AreaName'] ?? '',
      suppCityId: json['supp_CityId'] ?? 0,
      suppCityName: json['supp_CityName'] ?? '',
      suppStateId: json['supp_StateId'] ?? 0,
      suppStateName: json['supp_StateName'] ?? '',
      suppPincode: json['supp_Pincode'] ?? '',
      suppCountry: json['supp_Country'] ?? '',
      suppCompId: json['supp_CompId'] ?? 0,
      compName: json['comp_Name'] ?? '',
      suppBranchId: json['supp_BranchId'] ?? 0,
      branchName: json['branch_Name'] ?? '',
      accLedgerId: json['accLedger_Id'] ?? 0,
      accLedgerName: json['accLedger_Name'] ?? '',
      purchaseLedgerId: json['purchaseLedgerId'] ?? 0,
      totalPurchaseCount: json['totalPurchaseCount'] ?? 0,
      totalSubTotal: (json['totalSubTotal'] ?? 0).toDouble(),
      totalDiscountAmount: (json['totalDiscountAmount'] ?? 0).toDouble(),
      totalGSTAmount: (json['totalGSTAmount'] ?? 0).toDouble(),
      totalOtherCharges: (json['totalOtherCharges'] ?? 0).toDouble(),
      totalPurchaseAmount: (json['totalPurchaseAmount'] ?? 0).toDouble(),
      totalPaidAmount: (json['totalPaidAmount'] ?? 0).toDouble(),
      outstandingAmount: (json['outstandingAmount'] ?? 0).toDouble(),
      suppIsActive: json['supp_IsActive'] ?? true,
      totalRecords: json['totalRecords'] ?? 0,
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class SupplierOutstandingReportResponse {
  final bool status;
  final String message;
  final List<SupplierOutstandingReportItem> data;
  final String? error;

  SupplierOutstandingReportResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory SupplierOutstandingReportResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return SupplierOutstandingReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: dataList.map((e) => SupplierOutstandingReportItem.fromJson(e)).toList(),
      error: json['error'],
    );
  }
}

class SupplierPendingInvoiceItem {
  final int purchaseMasterId;
  final int purchaseMasterCompId;
  final String compName;
  final int purchaseMasterBranchId;
  final String branchName;
  final int purchaseMasterSupplierId;
  final String suppCode;
  final String suppName;
  final int accLedgerId;
  final String accLedgerName;
  final int purchaseMasterLedgerId;
  final String purchaseMasterInvoiceNo;
  final DateTime? purchaseMasterInvoiceDate;
  final double subTotal;
  final double discountAmount;
  final double gstAmount;
  final double otherCharges;
  final double netAmount;
  final double paidAmount;
  final double balanceAmount;
  final String purchaseMasterStatus;
  final String purchaseMasterRemark;
  final DateTime? purchaseMasterCreatedDate;
  final int totalRecords;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  SupplierPendingInvoiceItem({
    required this.purchaseMasterId,
    required this.purchaseMasterCompId,
    required this.compName,
    required this.purchaseMasterBranchId,
    required this.branchName,
    required this.purchaseMasterSupplierId,
    required this.suppCode,
    required this.suppName,
    required this.accLedgerId,
    required this.accLedgerName,
    required this.purchaseMasterLedgerId,
    required this.purchaseMasterInvoiceNo,
    this.purchaseMasterInvoiceDate,
    required this.subTotal,
    required this.discountAmount,
    required this.gstAmount,
    required this.otherCharges,
    required this.netAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.purchaseMasterStatus,
    required this.purchaseMasterRemark,
    this.purchaseMasterCreatedDate,
    required this.totalRecords,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory SupplierPendingInvoiceItem.fromJson(Map<String, dynamic> json) {
    return SupplierPendingInvoiceItem(
      purchaseMasterId: json['purchaseMaster_Id'] ?? 0,
      purchaseMasterCompId: json['purchaseMaster_CompId'] ?? 0,
      compName: json['comp_Name'] ?? '',
      purchaseMasterBranchId: json['purchaseMaster_BranchId'] ?? 0,
      branchName: json['branch_Name'] ?? '',
      purchaseMasterSupplierId: json['purchaseMaster_SupplierId'] ?? 0,
      suppCode: json['supp_Code'] ?? '',
      suppName: json['supp_Name'] ?? '',
      accLedgerId: json['accLedger_Id'] ?? 0,
      accLedgerName: json['accLedger_Name'] ?? '',
      purchaseMasterLedgerId: json['purchaseMaster_LedgerId'] ?? 0,
      purchaseMasterInvoiceNo: json['purchaseMaster_InvoiceNo'] ?? '',
      purchaseMasterInvoiceDate: json['purchaseMaster_InvoiceDate'] != null ? DateTime.tryParse(json['purchaseMaster_InvoiceDate']) : null,
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      gstAmount: (json['gstAmount'] ?? 0).toDouble(),
      otherCharges: (json['otherCharges'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceAmount: (json['balanceAmount'] ?? 0).toDouble(),
      purchaseMasterStatus: json['purchaseMaster_Status'] ?? '',
      purchaseMasterRemark: json['purchaseMaster_Remark'] ?? '',
      purchaseMasterCreatedDate: json['purchaseMaster_CreatedDate'] != null ? DateTime.tryParse(json['purchaseMaster_CreatedDate']) : null,
      totalRecords: json['totalRecords'] ?? 0,
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class SupplierPendingInvoiceResponse {
  final bool status;
  final String message;
  final List<SupplierPendingInvoiceItem> data;
  final String? error;

  SupplierPendingInvoiceResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory SupplierPendingInvoiceResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return SupplierPendingInvoiceResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: dataList.map((e) => SupplierPendingInvoiceItem.fromJson(e)).toList(),
      error: json['error'],
    );
  }
}
