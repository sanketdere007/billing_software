// --- OLD DUMMY MODELS FOR COMPATIBILITY ---
class PurchaseReturnProduct {
  final String id;
  final String productId;
  final String productName;
  final double returnQuantity;
  final String unit;
  final double price;
  final double taxAmount;
  final double refundAmount;
  final String? returnReason;
  final bool isDamaged;

  PurchaseReturnProduct({
    required this.id,
    required this.productId,
    required this.productName,
    required this.returnQuantity,
    required this.unit,
    required this.price,
    this.taxAmount = 0.0,
    required this.refundAmount,
    this.returnReason,
    this.isDamaged = false,
  });
}

class PurchaseReturn {
  final String id;
  final String returnNo;
  final DateTime returnDate;
  final String invoiceNo;
  final String supplierId;
  final String supplierName;
  
  final List<PurchaseReturnProduct> products;
  
  final double totalReturnQuantity;
  final double returnAmount;
  final double taxAdjustment;
  final double grandRefund;
  
  final String refundMode;
  final String refundStatus;

  PurchaseReturn({
    required this.id,
    required this.returnNo,
    required this.returnDate,
    required this.invoiceNo,
    required this.supplierId,
    required this.supplierName,
    required this.products,
    required this.totalReturnQuantity,
    required this.returnAmount,
    this.taxAdjustment = 0.0,
    required this.grandRefund,
    required this.refundMode,
    this.refundStatus = 'Completed',
  });
}

// --- NEW API MODELS ---

class PurchaseReturnMasterData {
  int purchaseReturnMasterId;
  int compId;
  int branchId;
  int supplierId;
  int ledgerId;
  String returnDate;
  double subTotal;
  double discountAmount;
  double billWiseDiscountPercentage;
  double billWiseDiscountAmount;
  double gstAmount;
  double otherCharges;
  double netAmount;
  double refundAmount;
  double balanceAmount;
  String status;
  String remark;
  int createdBy;
  int modifiedBy;

  PurchaseReturnMasterData({
    required this.purchaseReturnMasterId,
    required this.compId,
    required this.branchId,
    required this.supplierId,
    required this.ledgerId,
    required this.returnDate,
    required this.subTotal,
    required this.discountAmount,
    required this.billWiseDiscountPercentage,
    required this.billWiseDiscountAmount,
    required this.gstAmount,
    required this.otherCharges,
    required this.netAmount,
    required this.refundAmount,
    required this.balanceAmount,
    required this.status,
    required this.remark,
    required this.createdBy,
    required this.modifiedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      "purchaseReturnMaster_Id": purchaseReturnMasterId,
      "purchaseReturnMaster_CompId": compId,
      "purchaseReturnMaster_BranchId": branchId,
      "purchaseReturnMaster_SupplierId": supplierId,
      "purchaseReturnMaster_LedgerId": ledgerId,
      "purchaseReturnMaster_ReturnDate": returnDate,
      "purchaseReturnMaster_SubTotal": subTotal,
      "purchaseReturnMaster_DiscountAmount": discountAmount,
      "purchaseReturnMaster_BillWiseDiscountPercentage": billWiseDiscountPercentage,
      "purchaseReturnMaster_BillWiseDiscountAmount": billWiseDiscountAmount,
      "purchaseReturnMaster_GSTAmount": gstAmount,
      "purchaseReturnMaster_OtherCharges": otherCharges,
      "purchaseReturnMaster_NetAmount": netAmount,
      "purchaseReturnMaster_RefundAmount": refundAmount,
      "purchaseReturnMaster_BalanceAmount": balanceAmount,
      "purchaseReturnMaster_Status": status,
      "purchaseReturnMaster_Remark": remark,
      "purchaseReturnMaster_CreatedBy": createdBy,
      "purchaseReturnMaster_ModifiedBy": modifiedBy,
    };
  }
}

class PurchaseReturnDetailData {
  int productId;
  int batchId;
  double qty;
  double landingPrice;
  double purchasePrice;
  double mrp;
  double sellingPrice;
  double discountPercent;
  double discountAmount;
  double gstPercent;
  double gstAmount;
  double totalAmount;
  int createdBy;

  PurchaseReturnDetailData({
    required this.productId,
    required this.batchId,
    required this.qty,
    required this.landingPrice,
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    required this.discountPercent,
    required this.discountAmount,
    required this.gstPercent,
    required this.gstAmount,
    required this.totalAmount,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      "purchaseReturnDetail_ProductId": productId,
      "purchaseReturnDetail_BatchId": batchId,
      "purchaseReturnDetail_Qty": qty,
      "purchaseReturnDetail_LandingPrice": landingPrice,
      "purchaseReturnDetail_PurchasePrice": purchasePrice,
      "purchaseReturnDetail_MRP": mrp,
      "purchaseReturnDetail_SellingPrice": sellingPrice,
      "purchaseReturnDetail_DiscountPercent": discountPercent,
      "purchaseReturnDetail_DiscountAmount": discountAmount,
      "purchaseReturnDetail_GSTPercent": gstPercent,
      "purchaseReturnDetail_GSTAmount": gstAmount,
      "purchaseReturnDetail_TotalAmount": totalAmount,
      "purchaseReturnDetail_CreatedBy": createdBy,
    };
  }
}

class PurchaseReturnUpsertRequest {
  PurchaseReturnMasterData masterData;
  List<PurchaseReturnDetailData> detailData;

  PurchaseReturnUpsertRequest({
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

class PurchaseReturnResponseData {
  bool status;
  String message;
  int purchaseReturnMasterId;
  String returnNo;

  PurchaseReturnResponseData({
    required this.status,
    required this.message,
    required this.purchaseReturnMasterId,
    required this.returnNo,
  });

  factory PurchaseReturnResponseData.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnResponseData(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      purchaseReturnMasterId: json['purchaseReturnMaster_Id'] ?? 0,
      returnNo: json['purchaseReturnMaster_ReturnNo'] ?? '',
    );
  }
}

class PurchaseReturnUpsertResponse {
  bool status;
  String message;
  PurchaseReturnResponseData? data;
  String? error;

  PurchaseReturnUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory PurchaseReturnUpsertResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnUpsertResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PurchaseReturnResponseData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class PurchaseReturnMasterViewItem {
  final int purchaseReturnMasterId;
  final int compId;
  final int branchId;
  final int supplierId;
  final String supplierCode;
  final String supplierMobile;
  final int ledgerId;
  final String ledgerName;
  final String returnNo;
  final String returnDate;
  final double subTotal;
  final double discountAmount;
  final double billWiseDiscountPercentage;
  final double billWiseDiscountAmount;
  final double gstAmount;
  final double otherCharges;
  final double netAmount;
  final double refundAmount;
  final double balanceAmount;
  final String status;
  final String remark;
  final int createdBy;
  final String createdDate;
  final int modifiedBy;
  final String modifiedDate;
  final int totalRecords;

  PurchaseReturnMasterViewItem({
    required this.purchaseReturnMasterId,
    required this.compId,
    required this.branchId,
    required this.supplierId,
    required this.supplierCode,
    required this.supplierMobile,
    required this.ledgerId,
    required this.ledgerName,
    required this.returnNo,
    required this.returnDate,
    required this.subTotal,
    required this.discountAmount,
    required this.billWiseDiscountPercentage,
    required this.billWiseDiscountAmount,
    required this.gstAmount,
    required this.otherCharges,
    required this.netAmount,
    required this.refundAmount,
    required this.balanceAmount,
    required this.status,
    required this.remark,
    required this.createdBy,
    required this.createdDate,
    required this.modifiedBy,
    required this.modifiedDate,
    required this.totalRecords,
  });

  factory PurchaseReturnMasterViewItem.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnMasterViewItem(
      purchaseReturnMasterId: json['purchaseReturnMaster_Id'] ?? 0,
      compId: json['purchaseReturnMaster_CompId'] ?? 0,
      branchId: json['purchaseReturnMaster_BranchId'] ?? 0,
      supplierId: json['purchaseReturnMaster_SupplierId'] ?? 0,
      supplierCode: json['supplierCode'] ?? '',
      supplierMobile: json['supplierMobile'] ?? '',
      ledgerId: json['purchaseReturnMaster_LedgerId'] ?? 0,
      ledgerName: json['ledgerName'] ?? '',
      returnNo: json['purchaseReturnMaster_ReturnNo'] ?? '',
      returnDate: json['purchaseReturnMaster_ReturnDate'] ?? '',
      subTotal: (json['purchaseReturnMaster_SubTotal'] ?? 0.0).toDouble(),
      discountAmount: (json['purchaseReturnMaster_DiscountAmount'] ?? 0.0).toDouble(),
      billWiseDiscountPercentage: (json['purchaseReturnMaster_BillWiseDiscountPercentage'] ?? 0.0).toDouble(),
      billWiseDiscountAmount: (json['purchaseReturnMaster_BillWiseDiscountAmount'] ?? 0.0).toDouble(),
      gstAmount: (json['purchaseReturnMaster_GSTAmount'] ?? 0.0).toDouble(),
      otherCharges: (json['purchaseReturnMaster_OtherCharges'] ?? 0.0).toDouble(),
      netAmount: (json['purchaseReturnMaster_NetAmount'] ?? 0.0).toDouble(),
      refundAmount: (json['purchaseReturnMaster_RefundAmount'] ?? 0.0).toDouble(),
      balanceAmount: (json['purchaseReturnMaster_BalanceAmount'] ?? 0.0).toDouble(),
      status: json['purchaseReturnMaster_Status'] ?? '',
      remark: json['purchaseReturnMaster_Remark'] ?? '',
      createdBy: json['purchaseReturnMaster_CreatedBy'] ?? 0,
      createdDate: json['purchaseReturnMaster_CreatedDate'] ?? '',
      modifiedBy: json['purchaseReturnMaster_ModifiedBy'] ?? 0,
      modifiedDate: json['purchaseReturnMaster_ModifiedDate'] ?? '',
      totalRecords: json['totalRecords'] ?? 0,
    );
  }
}

class PurchaseReturnMasterViewResponseData {
  final List<PurchaseReturnMasterViewItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  PurchaseReturnMasterViewResponseData({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory PurchaseReturnMasterViewResponseData.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnMasterViewResponseData(
      items: (json['items'] as List?)?.map((e) => PurchaseReturnMasterViewItem.fromJson(e)).toList() ?? [],
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }
}

class PurchaseReturnMasterViewResponse {
  final bool status;
  final String message;
  final PurchaseReturnMasterViewResponseData? data;
  final String? error;

  PurchaseReturnMasterViewResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory PurchaseReturnMasterViewResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnMasterViewResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PurchaseReturnMasterViewResponseData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class PurchaseReturnDetailViewItem {
  final int purchaseReturnDetailId;
  final int purchaseReturnDetailMasterId;
  final int compId;
  final int branchId;
  final int productId;
  final String productCode;
  final String productName;
  final int batchId;
  final String batchNumber;
  final double batchStock;
  final double batchAvailableStock;
  final double qty;
  final double landingPrice;
  final double purchasePrice;
  final double mrp;
  final double sellingPrice;
  final double discountPercent;
  final double discountAmount;
  final double gstPercent;
  final double gstAmount;
  final double totalAmount;
  final int createdBy;
  final String createdDate;
  final int modifiedBy;
  final String modifiedDate;

  PurchaseReturnDetailViewItem({
    required this.purchaseReturnDetailId,
    required this.purchaseReturnDetailMasterId,
    required this.compId,
    required this.branchId,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.batchId,
    required this.batchNumber,
    required this.batchStock,
    required this.batchAvailableStock,
    required this.qty,
    required this.landingPrice,
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    required this.discountPercent,
    required this.discountAmount,
    required this.gstPercent,
    required this.gstAmount,
    required this.totalAmount,
    required this.createdBy,
    required this.createdDate,
    required this.modifiedBy,
    required this.modifiedDate,
  });

  factory PurchaseReturnDetailViewItem.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnDetailViewItem(
      purchaseReturnDetailId: json['purchaseReturnDetail_Id'] ?? 0,
      purchaseReturnDetailMasterId: json['purchaseReturnDetail_MasterId'] ?? 0,
      compId: json['purchaseReturnDetail_CompId'] ?? 0,
      branchId: json['purchaseReturnDetail_BranchId'] ?? 0,
      productId: json['purchaseReturnDetail_ProductId'] ?? 0,
      productCode: json['productCode'] ?? '',
      productName: json['productName'] ?? '',
      batchId: json['purchaseReturnDetail_BatchId'] ?? 0,
      batchNumber: json['batchNumber'] ?? '',
      batchStock: (json['batchStock'] ?? 0.0).toDouble(),
      batchAvailableStock: (json['batchAvailableStock'] ?? 0.0).toDouble(),
      qty: (json['purchaseReturnDetail_Qty'] ?? 0.0).toDouble(),
      landingPrice: (json['purchaseReturnDetail_LandingPrice'] ?? 0.0).toDouble(),
      purchasePrice: (json['purchaseReturnDetail_PurchasePrice'] ?? 0.0).toDouble(),
      mrp: (json['purchaseReturnDetail_MRP'] ?? 0.0).toDouble(),
      sellingPrice: (json['purchaseReturnDetail_SellingPrice'] ?? 0.0).toDouble(),
      discountPercent: (json['purchaseReturnDetail_DiscountPercent'] ?? 0.0).toDouble(),
      discountAmount: (json['purchaseReturnDetail_DiscountAmount'] ?? 0.0).toDouble(),
      gstPercent: (json['purchaseReturnDetail_GSTPercent'] ?? 0.0).toDouble(),
      gstAmount: (json['purchaseReturnDetail_GSTAmount'] ?? 0.0).toDouble(),
      totalAmount: (json['purchaseReturnDetail_TotalAmount'] ?? 0.0).toDouble(),
      createdBy: json['purchaseReturnDetail_CreatedBy'] ?? 0,
      createdDate: json['purchaseReturnDetail_CreatedDate'] ?? '',
      modifiedBy: json['purchaseReturnDetail_ModifiedBy'] ?? 0,
      modifiedDate: json['purchaseReturnDetail_ModifiedDate'] ?? '',
    );
  }
}

class PurchaseReturnDetailViewResponse {
  final bool status;
  final String message;
  final List<PurchaseReturnDetailViewItem> data;
  final String? error;

  PurchaseReturnDetailViewResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory PurchaseReturnDetailViewResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnDetailViewResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)?.map((e) => PurchaseReturnDetailViewItem.fromJson(e)).toList() ?? [],
      error: json['error'],
    );
  }
}
