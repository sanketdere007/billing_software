class SalesEntryProduct {
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

  SalesEntryProduct({
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

class SalesEntry {
  final String id;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String? customerId;
  final String customerName;
  final String? salespersonId;
  final String? branchId;
  final String? warehouseId;
  
  final List<SalesEntryProduct> products;
  
  final double totalQuantity;
  final double grossAmount;
  final double discount;
  final double gst;
  final double otherCharges;
  final double roundOff;
  final double grandTotal;
  
  final Map<String, double> payments;
  final double amountReceived;
  final double balance;
  final double changeReturn;
  
  final String status;

  SalesEntry({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    this.customerId,
    required this.customerName,
    this.salespersonId,
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
    required this.payments,
    this.amountReceived = 0.0,
    this.balance = 0.0,
    this.changeReturn = 0.0,
    this.status = 'Completed',
  });
}

class SalesEntryMasterData {
  final int compId;
  final int branchId;
  final int customerId;
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

  SalesEntryMasterData({
    this.compId = 0,
    this.branchId = 0,
    required this.customerId,
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
      "salesMaster_CompId": compId,
      "salesMaster_BranchId": branchId,
      "salesMaster_CustomerId": customerId,
      "salesMaster_InvoiceNo": invoiceNo,
      "salesMaster_InvoiceDate": invoiceDate,
      "salesMaster_SubTotal": subTotal,
      "salesMaster_DiscountAmount": discountAmount,
      "salesMaster_GSTAmount": gstAmount,
      "salesMaster_OtherCharges": otherCharges,
      "salesMaster_NetAmount": netAmount,
      "salesMaster_PaidAmount": paidAmount,
      "salesMaster_BalanceAmount": balanceAmount,
      "salesMaster_Status": status,
      "salesMaster_Remark": remark,
      "salesMaster_CreatedBy": createdBy,
      "salesMaster_ModifiedBy": modifiedBy,
      "salesMaster_LedgerId": ledgerId,
    };
  }
}

class SalesEntryDetailData {
  final int compId;
  final int branchId;
  final int productId;
  final String barcode;
  final String eanCode;
  final double qty;
  final double mrp;
  final double sellingPrice;
  final double discountPercent;
  final double discountAmount;
  final double gstPercent;
  final double gstAmount;
  final double totalAmount;

  SalesEntryDetailData({
    this.compId = 0,
    this.branchId = 0,
    required this.productId,
    this.barcode = '',
    this.eanCode = '',
    required this.qty,
    this.mrp = 0,
    required this.sellingPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.gstPercent = 0,
    this.gstAmount = 0,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      "salesDetail_CompId": compId,
      "salesDetail_BranchId": branchId,
      "salesDetail_ProductId": productId,
      "salesDetail_Barcode": barcode,
      "salesDetail_EANCode": eanCode,
      "salesDetail_Qty": qty,
      "salesDetail_MRP": mrp,
      "salesDetail_SellingPrice": sellingPrice,
      "salesDetail_DiscountPercent": discountPercent,
      "salesDetail_DiscountAmount": discountAmount,
      "salesDetail_GSTPercent": gstPercent,
      "salesDetail_GSTAmount": gstAmount,
      "salesDetail_TotalAmount": totalAmount,
    };
  }
}

class SalesEntryUpsertRequest {
  final SalesEntryMasterData masterData;
  final List<SalesEntryDetailData> detailData;

  SalesEntryUpsertRequest({
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

class SalesEntryUpsertResponseData {
  final bool status;
  final String message;
  final int salesMasterId;

  SalesEntryUpsertResponseData({
    required this.status,
    required this.message,
    required this.salesMasterId,
  });

  factory SalesEntryUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return SalesEntryUpsertResponseData(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      salesMasterId: json['salesMaster_Id'] ?? 0,
    );
  }
}

class SalesEntryUpsertResponse {
  final bool status;
  final String message;
  final SalesEntryUpsertResponseData? data;
  final String? error;

  SalesEntryUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory SalesEntryUpsertResponse.fromJson(Map<String, dynamic> json) {
    return SalesEntryUpsertResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SalesEntryUpsertResponseData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}
