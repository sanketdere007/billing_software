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
