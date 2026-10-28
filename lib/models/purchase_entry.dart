class PurchaseEntryProduct {
  final String id;
  final String productId;
  final String productName;
  final String batchNo;
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
    this.batchNo = '',
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
  final double billWiseDiscountPercentage;
  final double billWiseDiscountAmount;

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
    this.billWiseDiscountPercentage = 0.0,
    this.billWiseDiscountAmount = 0.0,
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
      "purchaseMaster_BillWiseDiscountPercentage": billWiseDiscountPercentage,
      "purchaseMaster_BillWiseDiscountAmount": billWiseDiscountAmount,
    };
  }
}

class PurchaseEntryDetailData {
  final int compId;
  final int branchId;
  final int productId;
  final String batchNo;
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
    this.batchNo = '',
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
      "purchaseDetail_BatchNumber": batchNo,
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

class PurchaseEntryPaymentData {
  final int paymentMasterId;
  final int compId;
  final int branchId;
  final int supplierId;
  final int customerId;
  final String paymentNo;
  final String paymentDate;
  final String type;
  final double totalAmount;
  final int invoiceId;
  final String invoiceNo;
  final String invoiceDate;
  final int accountId;
  final double cashAmount;
  final double upiAmount;
  final double chequeAmount;
  final double bankAmount;
  final double cardAmount;
  final double otherAmount;
  final String cashRemark;
  final String upiTransactionNo;
  final String upiReferenceNo;
  final String chequeNo;
  final String? chequeDate;
  final String chequeBankName;
  final String chequeBranchName;
  final String bankTransferType;
  final String bankName;
  final String bankAccountNo;
  final String bankTransactionNo;
  final String bankReferenceNo;
  final String? bankDate;
  final String otherPaymentType;
  final String otherReferenceNo;
  final String? otherDate;
  final String otherRemark;
  final String remark;
  final String status;
  final int createdBy;
  final int modifiedBy;

  PurchaseEntryPaymentData({
    this.paymentMasterId = 0,
    this.compId = 0,
    this.branchId = 0,
    this.supplierId = 0,
    this.customerId = 0,
    this.paymentNo = '',
    required this.paymentDate,
    this.type = 'Purchase',
    this.totalAmount = 0,
    this.invoiceId = 0,
    this.invoiceNo = '',
    required this.invoiceDate,
    this.accountId = 0,
    this.cashAmount = 0,
    this.upiAmount = 0,
    this.chequeAmount = 0,
    this.bankAmount = 0,
    this.cardAmount = 0,
    this.otherAmount = 0,
    this.cashRemark = '',
    this.upiTransactionNo = '',
    this.upiReferenceNo = '',
    this.chequeNo = '',
    this.chequeDate,
    this.chequeBankName = '',
    this.chequeBranchName = '',
    this.bankTransferType = '',
    this.bankName = '',
    this.bankAccountNo = '',
    this.bankTransactionNo = '',
    this.bankReferenceNo = '',
    this.bankDate,
    this.otherPaymentType = '',
    this.otherReferenceNo = '',
    this.otherDate,
    this.otherRemark = '',
    this.remark = '',
    this.status = 'Completed',
    this.createdBy = 0,
    this.modifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      "paymentMaster_Id": paymentMasterId,
      "paymentMaster_CompId": compId,
      "paymentMaster_BranchId": branchId,
      "paymentMaster_SupplierId": supplierId,
      "paymentMaster_CustomerId": customerId,
      "paymentMaster_PaymentNo": paymentNo,
      "paymentMaster_PaymentDate": paymentDate,
      "paymentMaster_Type": type,
      "paymentMaster_TotalAmount": totalAmount,
      "paymentMaster_InvoiceId": invoiceId,
      "paymentMaster_InvoiceNo": invoiceNo,
      "paymentMaster_InvoiceDate": invoiceDate,
      "paymentMaster_AccountId": accountId,
      "paymentMaster_CashAmount": cashAmount,
      "paymentMaster_UPIAmount": upiAmount,
      "paymentMaster_ChequeAmount": chequeAmount,
      "paymentMaster_BankAmount": bankAmount,
      "paymentMaster_CardAmount": cardAmount,
      "paymentMaster_OtherAmount": otherAmount,
      "paymentMaster_CashRemark": cashRemark,
      "paymentMaster_UPITransactionNo": upiTransactionNo,
      "paymentMaster_UPIReferenceNo": upiReferenceNo,
      "paymentMaster_ChequeNo": chequeNo,
      "paymentMaster_ChequeDate": chequeDate,
      "paymentMaster_ChequeBankName": chequeBankName,
      "paymentMaster_ChequeBranchName": chequeBranchName,
      "paymentMaster_BankTransferType": bankTransferType,
      "paymentMaster_BankName": bankName,
      "paymentMaster_BankAccountNo": bankAccountNo,
      "paymentMaster_BankTransactionNo": bankTransactionNo,
      "paymentMaster_BankReferenceNo": bankReferenceNo,
      "paymentMaster_BankDate": bankDate,
      "paymentMaster_OtherPaymentType": otherPaymentType,
      "paymentMaster_OtherReferenceNo": otherReferenceNo,
      "paymentMaster_OtherDate": otherDate,
      "paymentMaster_OtherRemark": otherRemark,
      "paymentMaster_Remark": remark,
      "paymentMaster_Status": status,
      "paymentMaster_CreatedBy": createdBy,
      "paymentMaster_ModifiedBy": modifiedBy,
    };
  }
}

class PurchaseEntryUpsertRequest {
  final PurchaseEntryMasterData masterData;
  final List<PurchaseEntryDetailData> detailData;
  final PurchaseEntryPaymentData? paymentData;

  PurchaseEntryUpsertRequest({
    required this.masterData,
    required this.detailData,
    this.paymentData,
  });

  Map<String, dynamic> toJson() {
    final map = {
      "masterData": masterData.toJson(),
      "detailData": detailData.map((e) => e.toJson()).toList(),
    };
    if (paymentData != null) {
      map["paymentData"] = paymentData!.toJson();
    }
    return map;
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
      purchaseMasterId: json['purchaseMaster_Id'] ?? json['purchaseMasterId'] ?? 0,
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
  final double billWiseDiscountPercentage;
  final double billWiseDiscountAmount;
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
    required this.billWiseDiscountPercentage,
    required this.billWiseDiscountAmount,
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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory PurchaseMasterViewItem.fromJson(Map<String, dynamic> json) {
    return PurchaseMasterViewItem(
      purchaseMasterId: _parseInt(json['purchaseMaster_Id'] ?? json['purchaseMasterId'] ?? json['id']),
      compId: _parseInt(json['purchaseMaster_CompId'] ?? json['compId']),
      branchId: _parseInt(json['purchaseMaster_BranchId'] ?? json['branchId']),
      supplierId: _parseInt(json['purchaseMaster_SupplierId'] ?? json['supplierId']),
      ledgerId: _parseInt(json['purchaseMaster_LedgerId'] ?? json['ledgerId']),
      invoiceNo: (json['purchaseMaster_InvoiceNo'] ?? json['invoiceNo'] ?? '').toString(),
      invoiceDate: (json['purchaseMaster_InvoiceDate'] ?? json['invoiceDate'] ?? '').toString(),
      subTotal: _parseDouble(json['purchaseMaster_SubTotal'] ?? json['subTotal']),
      discountAmount: _parseDouble(json['purchaseMaster_DiscountAmount'] ?? json['discountAmount']),
      billWiseDiscountPercentage: _parseDouble(json['purchaseMaster_BillWiseDiscountPercentage'] ?? json['billWiseDiscountPercentage']),
      billWiseDiscountAmount: _parseDouble(json['purchaseMaster_BillWiseDiscountAmount'] ?? json['billWiseDiscountAmount']),
      gstAmount: _parseDouble(json['purchaseMaster_GSTAmount'] ?? json['gstAmount']),
      otherCharges: _parseDouble(json['purchaseMaster_OtherCharges'] ?? json['otherCharges']),
      netAmount: _parseDouble(json['purchaseMaster_NetAmount'] ?? json['netAmount']),
      paidAmount: _parseDouble(json['purchaseMaster_PaidAmount'] ?? json['paidAmount']),
      balanceAmount: _parseDouble(json['purchaseMaster_BalanceAmount'] ?? json['balanceAmount']),
      status: (json['purchaseMaster_Status'] ?? json['status'] ?? '').toString(),
      remark: (json['purchaseMaster_Remark'] ?? json['remark'] ?? '').toString(),
      suppName: (json['supp_Name'] ?? json['supplierName'] ?? json['suppName'] ?? json['ledgerName'] ?? '').toString(),
      branchName: (json['branch_Name'] ?? json['branchName'] ?? '').toString(),
      accLedgerName: (json['accLedger_Name'] ?? json['accLedgerName'] ?? '').toString(),
      suppMobile: (json['supp_MobileNo'] ?? json['supp_Mobile'] ?? json['supplierMobile'] ?? json['mobileNo'] ?? '').toString(),
      totalRecords: _parseInt(json['totalRecords'] ?? json['total_records']),
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
      items: (json['items'] as List?)?.map((e) => PurchaseMasterViewItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      totalRecords: json['totalRecords'] ?? json['total_records'] ?? 0,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
      currentPage: json['currentPage'] ?? json['current_page'] ?? json['page'] ?? 0,
      pageSize: json['pageSize'] ?? json['page_size'] ?? 0,
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
    PurchaseMasterViewResponseData? dataObj;
    if (json['data'] is Map<String, dynamic>) {
      dataObj = PurchaseMasterViewResponseData.fromJson(json['data'] as Map<String, dynamic>);
    } else if (json['data'] is List) {
      final list = (json['data'] as List)
          .map((e) => PurchaseMasterViewItem.fromJson(e as Map<String, dynamic>))
          .toList();
      dataObj = PurchaseMasterViewResponseData(
        items: list,
        totalRecords: json['totalRecords'] ?? list.length,
        totalPages: 1,
        currentPage: 1,
        pageSize: list.length,
      );
    } else if (json['items'] is List) {
      dataObj = PurchaseMasterViewResponseData.fromJson(json);
    }
    return PurchaseMasterViewResponse(
      status: json['status'] ?? true,
      message: (json['message'] ?? '').toString(),
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}

class PurchaseDetailViewItem {
  final int purchaseDetailId;
  final int purchaseDetailMasterId;
  final int compId;
  final int branchId;
  final int productId;
  final String batchNo;
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
    required this.batchNo,
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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory PurchaseDetailViewItem.fromJson(Map<String, dynamic> json) {
    return PurchaseDetailViewItem(
      purchaseDetailId: _parseInt(json['purchaseDetail_Id'] ?? json['purchaseDetailId'] ?? json['id']),
      purchaseDetailMasterId: _parseInt(json['purchaseDetail_MasterId'] ?? json['purchaseDetailMasterId'] ?? json['masterId']),
      compId: _parseInt(json['purchaseDetail_CompId'] ?? json['compId']),
      branchId: _parseInt(json['purchaseDetail_BranchId'] ?? json['branchId']),
      productId: _parseInt(json['purchaseDetail_ProductId'] ?? json['productId']),
      batchNo: (json['purchaseDetail_BatchNumber'] ?? json['batchNo'] ?? json['batchNumber'] ?? '').toString(),
      barcode: (json['purchaseDetail_Barcode'] ?? json['barcode'] ?? '').toString(),
      eanCode: (json['purchaseDetail_EANCode'] ?? json['eanCode'] ?? '').toString(),
      qty: _parseDouble(json['purchaseDetail_Qty'] ?? json['qty']),
      landingPrice: _parseDouble(json['purchaseDetail_LandingPrice'] ?? json['landingPrice']),
      purchasePrice: _parseDouble(json['purchaseDetail_PurchasePrice'] ?? json['purchasePrice']),
      mrp: _parseDouble(json['purchaseDetail_MRP'] ?? json['mrp']),
      sellingPrice: _parseDouble(json['purchaseDetail_SellingPrice'] ?? json['sellingPrice']),
      discountPercent: _parseDouble(json['purchaseDetail_DiscountPercent'] ?? json['discountPercent']),
      discountAmount: _parseDouble(json['purchaseDetail_DiscountAmount'] ?? json['discountAmount']),
      gstPercent: _parseDouble(json['purchaseDetail_GSTPercent'] ?? json['gstPercent']),
      gstAmount: _parseDouble(json['purchaseDetail_GSTAmount'] ?? json['gstAmount']),
      totalAmount: _parseDouble(json['purchaseDetail_TotalAmount'] ?? json['totalAmount']),
      prodName: (json['prod_Name'] ?? json['productName'] ?? json['prodName'] ?? '').toString(),
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
    List<PurchaseDetailViewItem> items = [];
    if (json['data'] is List) {
      items = (json['data'] as List)
          .map((e) => PurchaseDetailViewItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['items'] is List) {
      items = (json['items'] as List)
          .map((e) => PurchaseDetailViewItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return PurchaseDetailViewResponse(
      status: json['status'] ?? true,
      message: (json['message'] ?? '').toString(),
      data: items,
      error: json['error']?.toString(),
    );
  }
}
