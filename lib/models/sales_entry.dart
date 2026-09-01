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

/// Request DTO for POST `/api/SalesEntry/InsertOrUpdateSalesEntry` → `masterData`
class SalesEntryMasterData {
  final int salesMasterId;
  final int compId;
  final int branchId;
  final int customerId;
  final int ledgerId;
  final String invoiceDate;
  final double totalQty;
  final double subTotal;
  final double totalDiscount;
  final double totalTaxableAmount;
  final double totalCGST;
  final double totalSGST;
  final double totalIGST;
  final double totalCESS;
  final double roundOff;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final double cashAmount;
  final double upiAmount;
  final double cardAmount;
  final double chequeAmount;
  final double bankAmount;
  final double otherAmount;
  final String chequeNo;
  final String? chequeDate;
  final String bankName;
  final String bankReferenceNo;
  final String neftType;
  final String neftReferenceNo;
  final String otherPaymentType;
  final String otherReferenceNo;
  final String? otherDate;
  final String otherRemark;
  final String billingName;
  final String billingAddress;
  final String billingMobileNo;
  final String billingGSTNo;
  final int billingStateId;
  final int billingCityId;
  final int billingAreaId;
  final String shippingName;
  final String shippingAddress;
  final String shippingMobileNo;
  final String shippingGSTNo;
  final int shippingStateId;
  final int shippingCityId;
  final int shippingAreaId;
  final String remark;
  final String status;
  final bool isActive;
  final int createdBy;
  final int modifiedBy;

  SalesEntryMasterData({
    this.salesMasterId = 0,
    this.compId = 0,
    this.branchId = 0,
    required this.customerId,
    this.ledgerId = 0,
    required this.invoiceDate,
    this.totalQty = 0,
    this.subTotal = 0,
    this.totalDiscount = 0,
    this.totalTaxableAmount = 0,
    this.totalCGST = 0,
    this.totalSGST = 0,
    this.totalIGST = 0,
    this.totalCESS = 0,
    this.roundOff = 0,
    required this.grandTotal,
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.cashAmount = 0,
    this.upiAmount = 0,
    this.cardAmount = 0,
    this.chequeAmount = 0,
    this.bankAmount = 0,
    this.otherAmount = 0,
    this.chequeNo = '',
    this.chequeDate,
    this.bankName = '',
    this.bankReferenceNo = '',
    this.neftType = '',
    this.neftReferenceNo = '',
    this.otherPaymentType = '',
    this.otherReferenceNo = '',
    this.otherDate,
    this.otherRemark = '',
    this.billingName = '',
    this.billingAddress = '',
    this.billingMobileNo = '',
    this.billingGSTNo = '',
    this.billingStateId = 0,
    this.billingCityId = 0,
    this.billingAreaId = 0,
    this.shippingName = '',
    this.shippingAddress = '',
    this.shippingMobileNo = '',
    this.shippingGSTNo = '',
    this.shippingStateId = 0,
    this.shippingCityId = 0,
    this.shippingAreaId = 0,
    this.remark = '',
    this.status = 'Completed',
    this.isActive = true,
    this.createdBy = 0,
    this.modifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'salesMaster_Id': salesMasterId,
      'salesMaster_CompId': compId,
      'salesMaster_BranchId': branchId,
      'salesMaster_CustomerId': customerId,
      'salesMaster_LedgerId': ledgerId,
      'salesMaster_InvoiceDate': invoiceDate,
      'salesMaster_TotalQty': totalQty,
      'salesMaster_SubTotal': subTotal,
      'salesMaster_TotalDiscount': totalDiscount,
      'salesMaster_TotalTaxableAmount': totalTaxableAmount,
      'salesMaster_TotalCGST': totalCGST,
      'salesMaster_TotalSGST': totalSGST,
      'salesMaster_TotalIGST': totalIGST,
      'salesMaster_TotalCESS': totalCESS,
      'salesMaster_RoundOff': roundOff,
      'salesMaster_GrandTotal': grandTotal,
      'salesMaster_PaidAmount': paidAmount,
      'salesMaster_BalanceAmount': balanceAmount,
      'salesMaster_CashAmount': cashAmount,
      'salesMaster_UPIAmount': upiAmount,
      'salesMaster_CardAmount': cardAmount,
      'salesMaster_ChequeAmount': chequeAmount,
      'salesMaster_BankAmount': bankAmount,
      'salesMaster_OtherAmount': otherAmount,
      'salesMaster_ChequeNo': chequeNo,
      'salesMaster_ChequeDate': chequeDate,
      'salesMaster_BankName': bankName,
      'salesMaster_BankReferenceNo': bankReferenceNo,
      'salesMaster_NEFTType': neftType,
      'salesMaster_NEFTReferenceNo': neftReferenceNo,
      'salesMaster_OtherPaymentType': otherPaymentType,
      'salesMaster_OtherReferenceNo': otherReferenceNo,
      'salesMaster_OtherDate': otherDate,
      'salesMaster_OtherRemark': otherRemark,
      'salesMaster_BillingName': billingName,
      'salesMaster_BillingAddress': billingAddress,
      'salesMaster_BillingMobileNo': billingMobileNo,
      'salesMaster_BillingGSTNo': billingGSTNo,
      'salesMaster_BillingStateId': billingStateId,
      'salesMaster_BillingCityId': billingCityId,
      'salesMaster_BillingAreaId': billingAreaId,
      'salesMaster_ShippingName': shippingName,
      'salesMaster_ShippingAddress': shippingAddress,
      'salesMaster_ShippingMobileNo': shippingMobileNo,
      'salesMaster_ShippingGSTNo': shippingGSTNo,
      'salesMaster_ShippingStateId': shippingStateId,
      'salesMaster_ShippingCityId': shippingCityId,
      'salesMaster_ShippingAreaId': shippingAreaId,
      'salesMaster_Remark': remark,
      'salesMaster_Status': status,
      'salesMaster_IsActive': isActive,
      'salesMaster_CreatedBy': createdBy,
      'salesMaster_ModifiedBy': modifiedBy,
    };
  }
}

/// Request DTO for POST `/api/SalesEntry/InsertOrUpdateSalesEntry` → `detailData[]`
class SalesEntryDetailData {
  final int compId;
  final int branchId;
  final int productId;
  final int batchId;
  final String productName;
  final String barcode;
  final String eanCode;
  final String hsnCode;
  final int unitId;
  final double qty;
  final double freeQty;
  final double totalQty;
  final double mrp;
  final double sellingPrice;
  final double rate;
  final double discountPercentage;
  final double discountAmount;
  final double taxableAmount;
  final double gstPercentage;
  final double cgstPercentage;
  final double sgstPercentage;
  final double igstPercentage;
  final double cessPercentage;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalTaxAmount;
  final double totalAmount;
  final double landingPrice;
  final double purchasePrice;
  final String remark;
  final int createdBy;
  final int modifiedBy;

  SalesEntryDetailData({
    this.compId = 0,
    this.branchId = 0,
    required this.productId,
    this.batchId = 0,
    this.productName = '',
    this.barcode = '',
    this.eanCode = '',
    this.hsnCode = '',
    this.unitId = 0,
    required this.qty,
    this.freeQty = 0,
    double? totalQty,
    this.mrp = 0,
    required this.sellingPrice,
    double? rate,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.gstPercentage = 0,
    this.cgstPercentage = 0,
    this.sgstPercentage = 0,
    this.igstPercentage = 0,
    this.cessPercentage = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    this.totalTaxAmount = 0,
    required this.totalAmount,
    this.landingPrice = 0,
    this.purchasePrice = 0,
    this.remark = '',
    this.createdBy = 0,
    this.modifiedBy = 0,
  }) : totalQty = totalQty ?? (qty + freeQty),
       rate = rate ?? sellingPrice;

  Map<String, dynamic> toJson() {
    return {
      'salesEntryDetail_CompId': compId,
      'salesEntryDetail_BranchId': branchId,
      'salesEntryDetail_ProductId': productId,
      'salesEntryDetail_BatchId': batchId,
      'salesEntryDetail_ProductName': productName,
      'salesEntryDetail_Barcode': barcode,
      'salesEntryDetail_EANCode': eanCode,
      'salesEntryDetail_HSNCode': hsnCode,
      'salesEntryDetail_UnitId': unitId,
      'salesEntryDetail_Qty': qty,
      'salesEntryDetail_FreeQty': freeQty,
      'salesEntryDetail_TotalQty': totalQty,
      'salesEntryDetail_MRP': mrp,
      'salesEntryDetail_SellingPrice': sellingPrice,
      'salesEntryDetail_Rate': rate,
      'salesEntryDetail_DiscountPercentage': discountPercentage,
      'salesEntryDetail_DiscountAmount': discountAmount,
      'salesEntryDetail_TaxableAmount': taxableAmount,
      'salesEntryDetail_GSTPercentage': gstPercentage,
      'salesEntryDetail_CGSTPercentage': cgstPercentage,
      'salesEntryDetail_SGSTPercentage': sgstPercentage,
      'salesEntryDetail_IGSTPercentage': igstPercentage,
      'salesEntryDetail_CESSPercentage': cessPercentage,
      'salesEntryDetail_CGSTAmount': cgstAmount,
      'salesEntryDetail_SGSTAmount': sgstAmount,
      'salesEntryDetail_IGSTAmount': igstAmount,
      'salesEntryDetail_CESSAmount': cessAmount,
      'salesEntryDetail_TotalTaxAmount': totalTaxAmount,
      'salesEntryDetail_TotalAmount': totalAmount,
      'salesEntryDetail_LandingPrice': landingPrice,
      'salesEntryDetail_PurchasePrice': purchasePrice,
      'salesEntryDetail_Remark': remark,
      'salesDetail_CreatedBy': createdBy,
      'salesDetail_ModifiedBy': modifiedBy,
    };
  }
}

class SalesEntryUpsertRequest {
  final SalesEntryMasterData masterData;
  final List<SalesEntryDetailData> detailData;

  SalesEntryUpsertRequest({required this.masterData, required this.detailData});

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
  final String salesMasterInvoiceNo;

  SalesEntryUpsertResponseData({
    required this.status,
    required this.message,
    required this.salesMasterId,
    this.salesMasterInvoiceNo = '',
  });

  factory SalesEntryUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return SalesEntryUpsertResponseData(
      status:
          json['status'] == true ||
          json['status'] == 'true' ||
          json['status'] == 1,
      message: json['message']?.toString() ?? '',
      salesMasterId: _asInt(json['salesMaster_Id']),
      salesMasterInvoiceNo: json['salesMaster_InvoiceNo']?.toString() ?? '',
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
    SalesEntryUpsertResponseData? data;
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      data = SalesEntryUpsertResponseData.fromJson(rawData);
    }

    return SalesEntryUpsertResponse(
      status:
          json['status'] == true ||
          json['status'] == 'true' ||
          json['status'] == 1,
      message: json['message']?.toString() ?? '',
      data: data,
      error: json['error']?.toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
