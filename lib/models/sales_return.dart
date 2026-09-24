class SalesReturnMasterData {
  int salesReturnMasterId;
  int compId;
  int branchId;
  String date;
  int customerId;
  int ledgerId;
  double totalQty;
  double subTotal;
  double discountAmount;
  double taxAmount;
  double billWiseDiscountPercentage;
  double billWiseDiscountAmount;
  double grandTotal;
  double paidAmount;
  double balanceAmount;
  double cashAmount;
  double upiAmount;
  double chequeAmount;
  double creditAmount;
  String status;
  String remark;
  bool isActive;
  int createdBy;
  int modifiedBy;

  SalesReturnMasterData({
    required this.salesReturnMasterId,
    required this.compId,
    required this.branchId,
    required this.date,
    required this.customerId,
    required this.ledgerId,
    required this.totalQty,
    required this.subTotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.billWiseDiscountPercentage,
    required this.billWiseDiscountAmount,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.cashAmount,
    required this.upiAmount,
    required this.chequeAmount,
    required this.creditAmount,
    required this.status,
    required this.remark,
    required this.isActive,
    required this.createdBy,
    required this.modifiedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      "salesReturnMaster_Id": salesReturnMasterId,
      "salesReturnMaster_CompId": compId,
      "salesReturnMaster_BranchId": branchId,
      "salesReturnMaster_Date": date,
      "salesReturnMaster_CustomerId": customerId,
      "salesReturnMaster_LedgerId": ledgerId,
      "salesReturnMaster_TotalQty": totalQty,
      "salesReturnMaster_SubTotal": subTotal,
      "salesReturnMaster_DiscountAmount": discountAmount,
      "salesReturnMaster_TaxAmount": taxAmount,
      "salesReturnMaster_BillWiseDiscountPercentage": billWiseDiscountPercentage,
      "salesReturnMaster_BillWiseDiscountAmount": billWiseDiscountAmount,
      "salesReturnMaster_GrandTotal": grandTotal,
      "salesReturnMaster_PaidAmount": paidAmount,
      "salesReturnMaster_BalanceAmount": balanceAmount,
      "salesReturnMaster_CashAmount": cashAmount,
      "salesReturnMaster_UPIAmount": upiAmount,
      "salesReturnMaster_ChequeAmount": chequeAmount,
      "salesReturnMaster_CreditAmount": creditAmount,
      "salesReturnMaster_Status": status,
      "salesReturnMaster_Remark": remark,
      "salesReturnMaster_IsActive": isActive,
      "salesReturnMaster_CreatedBy": createdBy,
      "salesReturnMaster_ModifiedBy": modifiedBy,
    };
  }
}

class SalesReturnDetailData {
  int productId;
  int batchId;
  int unitId;
  double qty;
  double freeQty;
  double sellingPrice;
  double mrp;
  double discountPercentage;
  double discountAmount;
  double taxPercentage;
  double taxAmount;
  double subTotal;
  double totalAmount;
  String remark;
  bool isActive;
  int modifiedBy;

  SalesReturnDetailData({
    required this.productId,
    required this.batchId,
    required this.unitId,
    required this.qty,
    required this.freeQty,
    required this.sellingPrice,
    required this.mrp,
    required this.discountPercentage,
    required this.discountAmount,
    required this.taxPercentage,
    required this.taxAmount,
    required this.subTotal,
    required this.totalAmount,
    required this.remark,
    required this.isActive,
    required this.modifiedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      "salesReturnDetail_ProductId": productId,
      "salesReturnDetail_BatchId": batchId,
      "salesReturnDetail_UnitId": unitId,
      "salesReturnDetail_Qty": qty,
      "salesReturnDetail_FreeQty": freeQty,
      "salesReturnDetail_SellingPrice": sellingPrice,
      "salesReturnDetail_MRP": mrp,
      "salesReturnDetail_DiscountPercentage": discountPercentage,
      "salesReturnDetail_DiscountAmount": discountAmount,
      "salesReturnDetail_TaxPercentage": taxPercentage,
      "salesReturnDetail_TaxAmount": taxAmount,
      "salesReturnDetail_SubTotal": subTotal,
      "salesReturnDetail_TotalAmount": totalAmount,
      "salesReturnDetail_Remark": remark,
      "salesReturnDetail_IsActive": isActive,
      "salesReturnDetail_ModifiedBy": modifiedBy,
    };
  }
}

class SalesReturnUpsertRequest {
  SalesReturnMasterData masterData;
  List<SalesReturnDetailData> detailData;

  SalesReturnUpsertRequest({
    required this.masterData,
    required this.detailData,
  });

  Map<String, dynamic> toJson() {
    return {
      "masterData": masterData.toJson(),
      "detailData": detailData.map((e) => e.toJson()).toList(),
    };
  }
}

class SalesReturnResponseData {
  bool status;
  String message;
  int salesReturnMasterId;
  String invoiceNo;

  SalesReturnResponseData({
    required this.status,
    required this.message,
    required this.salesReturnMasterId,
    required this.invoiceNo,
  });

  factory SalesReturnResponseData.fromJson(Map<String, dynamic> json) {
    return SalesReturnResponseData(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      salesReturnMasterId: json['salesReturnMaster_Id'] ?? 0,
      invoiceNo: json['salesReturnMaster_InvoiceNo'] ?? '',
    );
  }
}

class SalesReturnUpsertResponse {
  bool status;
  String message;
  SalesReturnResponseData? data;
  String? error;

  SalesReturnUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory SalesReturnUpsertResponse.fromJson(Map<String, dynamic> json) {
    return SalesReturnUpsertResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SalesReturnResponseData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class SalesReturnMasterListResponse {
  final bool status;
  final String message;
  final List<SalesReturnMasterDataListItem> data;
  final String? error;

  SalesReturnMasterListResponse({required this.status, required this.message, required this.data, this.error});

  factory SalesReturnMasterListResponse.fromJson(Map<String, dynamic> json) {
    return SalesReturnMasterListResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: (json['data'] as List<dynamic>?)?.map((e) => SalesReturnMasterDataListItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      error: json['error']?.toString(),
    );
  }
}

class SalesReturnMasterDataListItem {
  final Map<String, dynamic> raw;

  SalesReturnMasterDataListItem(this.raw);

  factory SalesReturnMasterDataListItem.fromJson(Map<String, dynamic> json) {
    return SalesReturnMasterDataListItem(json);
  }
}

class SalesReturnDetailListResponse {
  final bool status;
  final String message;
  final List<SalesReturnDetailDataListItem> data;
  final String error;

  SalesReturnDetailListResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.error,
  });

  factory SalesReturnDetailListResponse.fromJson(Map<String, dynamic> json) {
    return SalesReturnDetailListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((e) => SalesReturnDetailDataListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      error: json['error'] ?? '',
    );
  }
}

class SalesReturnDetailDataListItem {
  final Map<String, dynamic> raw;

  SalesReturnDetailDataListItem({required this.raw});

  factory SalesReturnDetailDataListItem.fromJson(Map<String, dynamic> json) {
    return SalesReturnDetailDataListItem(raw: json);
  }
}
