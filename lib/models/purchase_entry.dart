class PurchaseEntryProduct {
  final String id;
  final String productId;
  final String productName;
  final String barcode;
  final double quantity;
  final String unit;
  final double price;
  final double landingPrice;
  final double purchasePrice;
  final double mrp;
  final double sellingPrice;
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
    this.landingPrice = 0.0,
    this.purchasePrice = 0.0,
    this.mrp = 0.0,
    this.sellingPrice = 0.0,
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

class PurchaseMasterViewItem {
  final int purchaseMasterId;
  final int compId;
  final int branchId;
  final int supplierId;
  final int ledgerId;
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
  final String suppName;
  final String branchName;
  final String accLedgerName;
  final String suppMobile;
  final int totalRecords;

  PurchaseMasterViewItem({
    required this.purchaseMasterId,
    required this.compId,
    required this.branchId,
    required this.supplierId,
    required this.ledgerId,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.subTotal,
    required this.discountAmount,
    required this.gstAmount,
    required this.otherCharges,
    required this.netAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    required this.remark,
    required this.suppName,
    required this.branchName,
    required this.accLedgerName,
    required this.suppMobile,
    required this.totalRecords,
  });

  factory PurchaseMasterViewItem.fromJson(Map<String, dynamic> json) {
    return PurchaseMasterViewItem(
      purchaseMasterId: json['purchaseMaster_Id'] ?? 0,
      compId: json['purchaseMaster_CompId'] ?? 0,
      branchId: json['purchaseMaster_BranchId'] ?? 0,
      supplierId: json['purchaseMaster_SupplierId'] ?? 0,
      ledgerId: json['purchaseMaster_LedgerId'] ?? 0,
      invoiceNo: json['purchaseMaster_InvoiceNo'] ?? '',
      invoiceDate: json['purchaseMaster_InvoiceDate'] ?? '',
      subTotal: (json['purchaseMaster_SubTotal'] ?? 0.0).toDouble(),
      discountAmount: (json['purchaseMaster_DiscountAmount'] ?? 0.0).toDouble(),
      gstAmount: (json['purchaseMaster_GSTAmount'] ?? 0.0).toDouble(),
      otherCharges: (json['purchaseMaster_OtherCharges'] ?? 0.0).toDouble(),
      netAmount: (json['purchaseMaster_NetAmount'] ?? 0.0).toDouble(),
      paidAmount: (json['purchaseMaster_PaidAmount'] ?? 0.0).toDouble(),
      balanceAmount: (json['purchaseMaster_BalanceAmount'] ?? 0.0).toDouble(),
      status: json['purchaseMaster_Status'] ?? '',
      remark: json['purchaseMaster_Remark'] ?? '',
      suppName: json['supp_Name'] ?? '',
      branchName: json['branch_Name'] ?? '',
      accLedgerName: json['accLedger_Name'] ?? '',
      suppMobile: json['supp_MobileNo'] ?? json['supp_Mobile'] ?? json['mobileNo'] ?? '',
      totalRecords: json['totalRecords'] ?? 0,
    );
  }
}

class PurchaseMasterViewResponseData {
  final List<PurchaseMasterViewItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  PurchaseMasterViewResponseData({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory PurchaseMasterViewResponseData.fromJson(Map<String, dynamic> json) {
    return PurchaseMasterViewResponseData(
      items: (json['items'] as List?)?.map((e) => PurchaseMasterViewItem.fromJson(e)).toList() ?? [],
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }
}

class PurchaseMasterViewResponse {
  final bool status;
  final String message;
  final PurchaseMasterViewResponseData? data;
  final String? error;

  PurchaseMasterViewResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory PurchaseMasterViewResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseMasterViewResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PurchaseMasterViewResponseData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class PurchaseDetailViewItem {
  final int purchaseDetailId;
  final int purchaseDetailMasterId;
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
  final String prodName;

  PurchaseDetailViewItem({
    required this.purchaseDetailId,
    required this.purchaseDetailMasterId,
    required this.compId,
    required this.branchId,
    required this.productId,
    required this.barcode,
    required this.eanCode,
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
    required this.prodName,
  });

  factory PurchaseDetailViewItem.fromJson(Map<String, dynamic> json) {
    return PurchaseDetailViewItem(
      purchaseDetailId: json['purchaseDetail_Id'] ?? 0,
      purchaseDetailMasterId: json['purchaseDetail_MasterId'] ?? 0,
      compId: json['purchaseDetail_CompId'] ?? 0,
      branchId: json['purchaseDetail_BranchId'] ?? 0,
      productId: json['purchaseDetail_ProductId'] ?? 0,
      barcode: json['purchaseDetail_Barcode'] ?? '',
      eanCode: json['purchaseDetail_EANCode'] ?? '',
      qty: (json['purchaseDetail_Qty'] ?? 0.0).toDouble(),
      landingPrice: (json['purchaseDetail_LandingPrice'] ?? 0.0).toDouble(),
      purchasePrice: (json['purchaseDetail_PurchasePrice'] ?? 0.0).toDouble(),
      mrp: (json['purchaseDetail_MRP'] ?? 0.0).toDouble(),
      sellingPrice: (json['purchaseDetail_SellingPrice'] ?? 0.0).toDouble(),
      discountPercent: (json['purchaseDetail_DiscountPercent'] ?? 0.0).toDouble(),
      discountAmount: (json['purchaseDetail_DiscountAmount'] ?? 0.0).toDouble(),
      gstPercent: (json['purchaseDetail_GSTPercent'] ?? 0.0).toDouble(),
      gstAmount: (json['purchaseDetail_GSTAmount'] ?? 0.0).toDouble(),
      totalAmount: (json['purchaseDetail_TotalAmount'] ?? 0.0).toDouble(),
      prodName: json['prod_Name'] ?? '',
    );
  }
}

class PurchaseDetailViewResponse {
  final bool status;
  final String message;
  final List<PurchaseDetailViewItem> data;
  final String? error;

  PurchaseDetailViewResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory PurchaseDetailViewResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseDetailViewResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)?.map((e) => PurchaseDetailViewItem.fromJson(e)).toList() ?? [],
      error: json['error'],
    );
  }
}
