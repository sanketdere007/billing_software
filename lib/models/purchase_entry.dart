class PurchaseEntryProduct {
  final String id;
  final String productId;
  final String productName;
  final String barcode;
  final double quantity;
  final String unit;
  final double price;
  final double discountPercent;
  final double gstPercent;
  final double taxAmount;
  final double total;

  PurchaseEntryProduct({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode = '',
    required this.quantity,
    required this.unit,
    required this.price,
    this.discountPercent = 0.0,
    this.gstPercent = 0.0,
    this.taxAmount = 0.0,
    required this.total,
  });
}

class PurchaseEntry {
  final String id;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String supplierId;
  final String supplierName;
  final String? branchId;
  final String? warehouseId;
  
  final List<PurchaseEntryProduct> products;
  
  final double totalQuantity;
  final double grossAmount;
  final double discount;
  final double gst;
  final double otherCharges;
  final double roundOff;
  final double grandTotal;
  
  // Payments
  final Map<String, double> payments;
  final double amountPaid;
  final double balance;
  
  final String status;

  PurchaseEntry({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.supplierId,
    required this.supplierName,
    this.branchId,
    this.warehouseId,
    required this.products,
    required this.totalQuantity,
    required this.grossAmount,
    this.discount = 0.0,
    this.gst = 0.0,
    this.otherCharges = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    this.payments = const {},
    this.amountPaid = 0.0,
    this.balance = 0.0,
    this.status = 'Completed',
  });
}

class PurchaseEntryMasterData {
  final int compId;
  final int branchId;
  final int supplierId;
  final String invoiceNo;
  final String invoiceDate;
  final double subTotal;
  final double discountAmount;
  final double gstAmount;
  final double otherCharges;
  final double netAmount;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final String remark;
  final int createdBy;
  final int modifiedBy;
  final int ledgerId;

  PurchaseEntryMasterData({
    this.compId = 0,
    this.branchId = 0,
    required this.supplierId,
    required this.invoiceNo,
    required this.invoiceDate,
    this.subTotal = 0,
    this.discountAmount = 0,
    this.gstAmount = 0,
    this.otherCharges = 0,
    required this.netAmount,
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.status = 'Completed',
    this.remark = '',
    this.createdBy = 0,
    this.modifiedBy = 0,
    this.ledgerId = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      "purchaseMaster_CompId": compId,
      "purchaseMaster_BranchId": branchId,
      "purchaseMaster_SupplierId": supplierId,
      "purchaseMaster_InvoiceNo": invoiceNo,
      "purchaseMaster_InvoiceDate": invoiceDate,
      "purchaseMaster_SubTotal": subTotal,
      "purchaseMaster_DiscountAmount": discountAmount,
      "purchaseMaster_GSTAmount": gstAmount,
      "purchaseMaster_OtherCharges": otherCharges,
      "purchaseMaster_NetAmount": netAmount,
      "purchaseMaster_PaidAmount": paidAmount,
      "purchaseMaster_BalanceAmount": balanceAmount,
      "purchaseMaster_Status": status,
      "purchaseMaster_Remark": remark,
      "purchaseMaster_CreatedBy": createdBy,
      "purchaseMaster_ModifiedBy": modifiedBy,
      "purchaseMaster_LedgerId": ledgerId,
    };
  }
}

class PurchaseEntryDetailData {
  final int compId;
  final int branchId;
  final int productId;
  final String barcode;
  final String eanCode;
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

  PurchaseEntryDetailData({
    this.compId = 0,
    this.branchId = 0,
    required this.productId,
    this.barcode = '',
    this.eanCode = '',
    required this.qty,
    this.landingPrice = 0,
    required this.purchasePrice,
    this.mrp = 0,
    this.sellingPrice = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.gstPercent = 0,
    this.gstAmount = 0,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      "purchaseDetail_CompId": compId,
      "purchaseDetail_BranchId": branchId,
      "purchaseDetail_ProductId": productId,
      "purchaseDetail_Barcode": barcode,
      "purchaseDetail_EANCode": eanCode,
      "purchaseDetail_Qty": qty,
      "purchaseDetail_LandingPrice": landingPrice,
      "purchaseDetail_PurchasePrice": purchasePrice,
      "purchaseDetail_MRP": mrp,
      "purchaseDetail_SellingPrice": sellingPrice,
      "purchaseDetail_DiscountPercent": discountPercent,
      "purchaseDetail_DiscountAmount": discountAmount,
      "purchaseDetail_GSTPercent": gstPercent,
      "purchaseDetail_GSTAmount": gstAmount,
      "purchaseDetail_TotalAmount": totalAmount,
    };
  }
}

class PurchaseEntryUpsertRequest {
  final PurchaseEntryMasterData masterData;
  final List<PurchaseEntryDetailData> detailData;

  PurchaseEntryUpsertRequest({
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

class PurchaseEntryUpsertResponseData {
  final bool status;
  final String message;
  final int purchaseMasterId;

  PurchaseEntryUpsertResponseData({
    required this.status,
    required this.message,
    required this.purchaseMasterId,
  });

  factory PurchaseEntryUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return PurchaseEntryUpsertResponseData(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      purchaseMasterId: json['purchaseMaster_Id'] ?? 0,
    );
  }
}

class PurchaseEntryUpsertResponse {
  final bool status;
  final String message;
  final PurchaseEntryUpsertResponseData? data;
  final String? error;

  PurchaseEntryUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory PurchaseEntryUpsertResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseEntryUpsertResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PurchaseEntryUpsertResponseData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}
