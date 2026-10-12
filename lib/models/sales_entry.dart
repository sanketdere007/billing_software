abstract final class _SalesEntryParser {
  static int asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  static String firstNonEmpty(List<String?> items, {String fallback = ''}) {
    for (final item in items) {
      if (item != null && item.trim().isNotEmpty) {
        return item.trim();
      }
    }
    return fallback;
  }
}

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
  final double creditAmount;
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
  final double billWiseDiscountPercentage;
  final double billWiseDiscountAmount;

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
    this.creditAmount = 0,
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
    this.billWiseDiscountPercentage = 0,
    this.billWiseDiscountAmount = 0,
  });

  factory SalesEntryMasterData.fromRaw(
    Map<String, dynamic> raw, {
    List<SalesEntryDetailData>? details,
  }) {
    final subTotal = _SalesEntryParser.toDouble(
      raw['salesMaster_SubTotal'] ?? raw['subTotal'],
    );
    final totalDisc = _SalesEntryParser.toDouble(
      raw['salesMaster_TotalDiscount'] ?? raw['totalDiscount'],
    );
    final totalTaxable = _SalesEntryParser.toDouble(
      raw['salesMaster_TotalTaxableAmount'] ?? raw['totalTaxableAmount'],
    );
    final totalCGST = _SalesEntryParser.toDouble(
      raw['salesMaster_TotalCGST'] ?? raw['totalCGST'],
    );
    final totalSGST = _SalesEntryParser.toDouble(
      raw['salesMaster_TotalSGST'] ?? raw['totalSGST'],
    );
    final totalIGST = _SalesEntryParser.toDouble(
      raw['salesMaster_TotalIGST'] ?? raw['totalIGST'],
    );
    final grandTotal = _SalesEntryParser.toDouble(
      raw['salesMaster_GrandTotal'] ?? raw['grandTotal'],
    );
    final totalQty = _SalesEntryParser.toDouble(
      raw['salesMaster_TotalQty'] ?? raw['totalQty'],
    );

    return SalesEntryMasterData(
      salesMasterId: _SalesEntryParser.asInt(
        raw['salesMaster_Id'] ?? raw['salesMasterId'] ?? raw['id'],
      ),
      compId: _SalesEntryParser.asInt(
        raw['salesMaster_CompId'] ?? raw['compId'],
      ),
      branchId: _SalesEntryParser.asInt(
        raw['salesMaster_BranchId'] ?? raw['branchId'],
      ),
      customerId: _SalesEntryParser.asInt(
        raw['salesMaster_CustomerId'] ?? raw['customerId'] ?? raw['cust_Id'],
      ),
      ledgerId: _SalesEntryParser.asInt(
        raw['salesMaster_LedgerId'] ?? raw['ledgerId'],
      ),
      invoiceDate:
          raw['salesMaster_InvoiceDate']?.toString() ??
          raw['invoiceDate']?.toString() ??
          DateTime.now().toIso8601String(),
      totalQty: totalQty > 0
          ? totalQty
          : (details?.fold<double>(0, (s, d) => s + d.totalQty) ?? 0),
      subTotal: subTotal > 0
          ? subTotal
          : (details?.fold<double>(0, (s, d) => s + (d.qty * d.rate)) ?? 0),
      totalDiscount: totalDisc > 0
          ? totalDisc
          : (details?.fold<double>(0, (s, d) => s + d.discountAmount) ?? 0),
      totalTaxableAmount: totalTaxable > 0
          ? totalTaxable
          : (details?.fold<double>(0, (s, d) => s + d.taxableAmount) ?? 0),
      totalCGST: totalCGST > 0
          ? totalCGST
          : (details?.fold<double>(0, (s, d) => s + d.cgstAmount) ?? 0),
      totalSGST: totalSGST > 0
          ? totalSGST
          : (details?.fold<double>(0, (s, d) => s + d.sgstAmount) ?? 0),
      totalIGST: totalIGST > 0
          ? totalIGST
          : (details?.fold<double>(0, (s, d) => s + d.igstAmount) ?? 0),
      totalCESS: _SalesEntryParser.toDouble(
        raw['salesMaster_TotalCESS'] ?? raw['totalCESS'],
      ),
      roundOff: _SalesEntryParser.toDouble(
        raw['salesMaster_RoundOff'] ?? raw['roundOff'],
      ),
      grandTotal: grandTotal > 0
          ? grandTotal
          : (details?.fold<double>(0, (s, d) => s + d.totalAmount) ?? 0),
      paidAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_PaidAmount'] ?? raw['paidAmount'],
      ),
      balanceAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_BalanceAmount'] ?? raw['balanceAmount'],
      ),
      cashAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_CashAmount'] ?? raw['cashAmount'],
      ),
      upiAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_UPIAmount'] ?? raw['upiAmount'],
      ),
      cardAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_CardAmount'] ?? raw['cardAmount'],
      ),
      chequeAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_ChequeAmount'] ?? raw['chequeAmount'],
      ),
      bankAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_BankAmount'] ?? raw['bankAmount'],
      ),
      otherAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_OtherAmount'] ?? raw['otherAmount'],
      ),
      creditAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_CreditAmt'] ?? raw['creditAmount'],
      ),
      chequeNo:
          raw['salesMaster_ChequeNo']?.toString() ??
          raw['chequeNo']?.toString() ??
          '',
      chequeDate:
          raw['salesMaster_ChequeDate']?.toString() ??
          raw['chequeDate']?.toString(),
      bankName:
          raw['salesMaster_BankName']?.toString() ??
          raw['bankName']?.toString() ??
          '',
      bankReferenceNo:
          raw['salesMaster_BankReferenceNo']?.toString() ??
          raw['bankReferenceNo']?.toString() ??
          '',
      neftType:
          raw['salesMaster_NEFTType']?.toString() ??
          raw['neftType']?.toString() ??
          '',
      neftReferenceNo:
          raw['salesMaster_NEFTReferenceNo']?.toString() ??
          raw['neftReferenceNo']?.toString() ??
          '',
      otherPaymentType:
          raw['salesMaster_OtherPaymentType']?.toString() ??
          raw['otherPaymentType']?.toString() ??
          '',
      otherReferenceNo:
          raw['salesMaster_OtherReferenceNo']?.toString() ??
          raw['otherReferenceNo']?.toString() ??
          '',
      otherDate:
          raw['salesMaster_OtherDate']?.toString() ??
          raw['otherDate']?.toString(),
      otherRemark:
          raw['salesMaster_OtherRemark']?.toString() ??
          raw['otherRemark']?.toString() ??
          '',
      billingName:
          raw['salesMaster_BillingName']?.toString() ??
          raw['cust_Name']?.toString() ??
          '',
      billingAddress:
          raw['salesMaster_BillingAddress']?.toString() ??
          raw['cust_Address']?.toString() ??
          '',
      billingMobileNo:
          raw['salesMaster_BillingMobileNo']?.toString() ??
          raw['cust_MobileNo']?.toString() ??
          '',
      billingGSTNo:
          raw['salesMaster_BillingGSTNo']?.toString() ??
          raw['cust_GSTNo']?.toString() ??
          '',
      billingStateId: _SalesEntryParser.asInt(
        raw['salesMaster_BillingStateId'],
      ),
      billingCityId: _SalesEntryParser.asInt(raw['salesMaster_BillingCityId']),
      billingAreaId: _SalesEntryParser.asInt(raw['salesMaster_BillingAreaId']),
      shippingName: raw['salesMaster_ShippingName']?.toString() ?? '',
      shippingAddress: raw['salesMaster_ShippingAddress']?.toString() ?? '',
      shippingMobileNo: raw['salesMaster_ShippingMobileNo']?.toString() ?? '',
      shippingGSTNo: raw['salesMaster_ShippingGSTNo']?.toString() ?? '',
      shippingStateId: _SalesEntryParser.asInt(
        raw['salesMaster_ShippingStateId'],
      ),
      shippingCityId: _SalesEntryParser.asInt(
        raw['salesMaster_ShippingCityId'],
      ),
      shippingAreaId: _SalesEntryParser.asInt(
        raw['salesMaster_ShippingAreaId'],
      ),
      remark:
          raw['salesMaster_Remark']?.toString() ??
          raw['remark']?.toString() ??
          '',
      status:
          raw['salesMaster_Status']?.toString() ??
          raw['status']?.toString() ??
          'Completed',
      isActive: raw['salesMaster_IsActive'] != false,
      createdBy: _SalesEntryParser.asInt(
        raw['salesMaster_CreatedBy'] ?? raw['createdBy'],
      ),
      modifiedBy: _SalesEntryParser.asInt(
        raw['salesMaster_ModifiedBy'] ?? raw['modifiedBy'],
      ),
      billWiseDiscountPercentage: _SalesEntryParser.toDouble(
        raw['salesMaster_BillWiseDiscountPercentage'] ??
            raw['billWiseDiscountPercentage'],
      ),
      billWiseDiscountAmount: _SalesEntryParser.toDouble(
        raw['salesMaster_BillWiseDiscountAmount'] ??
            raw['billWiseDiscountAmount'],
      ),
    );
  }

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
      'salesMaster_CreditAmt': creditAmount,
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
      'salesMaster_BillWiseDiscountPercentage': billWiseDiscountPercentage,
      'salesMaster_BillWiseDiscountAmount': billWiseDiscountAmount,
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
  final String batchNumber;
  final String expiry;
  final String unitName;
  final String prodCode;

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
    this.batchNumber = '',
    this.expiry = '',
    this.unitName = '',
    this.prodCode = '',
  }) : totalQty = totalQty ?? (qty + freeQty),
       rate = rate ?? sellingPrice;

  factory SalesEntryDetailData.fromRaw(Map<String, dynamic> raw) {
    final qty = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_Qty'] ??
          raw['salesDetail_Qty'] ??
          raw['qty'] ??
          raw['quantity'],
    );
    final freeQty = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_FreeQty'] ?? raw['freeQty'],
    );
    final rate = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_Rate'] ??
          raw['salesDetail_Rate'] ??
          raw['salesEntryDetail_SellingPrice'] ??
          raw['sellingPrice'] ??
          raw['rate'],
    );
    final sellingPrice = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_SellingPrice'] ?? raw['sellingPrice'] ?? rate,
    );
    final mrp = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_MRP'] ??
          raw['batch_MRP'] ??
          raw['mrp'] ??
          (rate > 0 ? rate : 0),
    );
    final gstPercentage = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_GSTPercentage'] ??
          raw['salesDetail_GSTPercentage'] ??
          raw['gstPercentage'] ??
          raw['gstPer'] ??
          raw['taxPer'],
    );
    final totalTax = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_TotalTaxAmount'] ??
          raw['salesDetail_TotalTaxAmount'] ??
          raw['totalTaxAmount'] ??
          raw['gstAmt'] ??
          raw['taxAmt'],
    );
    final totalAmount = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_TotalAmount'] ??
          raw['salesDetail_TotalAmount'] ??
          raw['totalAmount'] ??
          raw['netAmt'],
    );
    final discAmount = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_DiscountAmount'] ??
          raw['salesDetail_DiscountAmount'] ??
          raw['discountAmount'] ??
          raw['disAmt'],
    );
    final discPercentage = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_DiscountPercentage'] ??
          raw['salesDetail_DiscountPercentage'] ??
          raw['discountPercentage'] ??
          raw['disPer'],
    );
    final taxableAmount = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_TaxableAmount'] ??
          raw['salesDetail_TaxableAmount'] ??
          raw['taxableAmount'] ??
          raw['grossAmt'],
    );

    double cgstAmt = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_CGSTAmount'] ?? raw['cgstAmount'],
    );
    double sgstAmt = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_SGSTAmount'] ?? raw['sgstAmount'],
    );
    double igstAmt = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_IGSTAmount'] ?? raw['igstAmount'],
    );
    double cgstPct = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_CGSTPercentage'] ?? raw['cgstPercentage'],
    );
    double sgstPct = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_SGSTPercentage'] ?? raw['sgstPercentage'],
    );
    double igstPct = _SalesEntryParser.toDouble(
      raw['salesEntryDetail_IGSTPercentage'] ?? raw['igstPercentage'],
    );

    if (cgstAmt == 0 && sgstAmt == 0 && igstAmt == 0 && totalTax > 0) {
      cgstAmt = totalTax / 2;
      sgstAmt = totalTax / 2;
      cgstPct = gstPercentage / 2;
      sgstPct = gstPercentage / 2;
    }

    return SalesEntryDetailData(
      compId: _SalesEntryParser.asInt(
        raw['salesEntryDetail_CompId'] ??
            raw['salesDetail_CompId'] ??
            raw['compId'],
      ),
      branchId: _SalesEntryParser.asInt(
        raw['salesEntryDetail_BranchId'] ??
            raw['salesDetail_BranchId'] ??
            raw['branchId'],
      ),
      productId: _SalesEntryParser.asInt(
        raw['salesEntryDetail_ProductId'] ??
            raw['salesDetail_ProductId'] ??
            raw['productId'] ??
            raw['prod_Id'],
      ),
      batchId: _SalesEntryParser.asInt(
        raw['salesEntryDetail_BatchId'] ??
            raw['salesDetail_BatchId'] ??
            raw['batchId'] ??
            raw['batch_Id'],
      ),
      productName: _SalesEntryParser.firstNonEmpty([
        raw['salesEntryDetail_ProductName']?.toString(),
        raw['salesDetail_ProductName']?.toString(),
        raw['prod_Name']?.toString(),
        raw['productName']?.toString(),
        raw['name']?.toString(),
      ]),
      barcode:
          raw['salesEntryDetail_Barcode']?.toString() ??
          raw['barcode']?.toString() ??
          '',
      eanCode:
          raw['salesEntryDetail_EANCode']?.toString() ??
          raw['eanCode']?.toString() ??
          '',
      hsnCode:
          raw['salesEntryDetail_HSNCode']?.toString() ??
          raw['hsnCode']?.toString() ??
          '',
      unitId: _SalesEntryParser.asInt(
        raw['salesEntryDetail_UnitId'] ?? raw['unitId'],
      ),
      qty: qty,
      freeQty: freeQty,
      totalQty: _SalesEntryParser.toDouble(
        raw['salesEntryDetail_TotalQty'] ?? raw['totalQty'] ?? (qty + freeQty),
      ),
      mrp: mrp,
      sellingPrice: sellingPrice,
      rate: rate,
      discountPercentage: discPercentage,
      discountAmount: discAmount,
      taxableAmount: taxableAmount > 0
          ? taxableAmount
          : ((qty * rate) - discAmount),
      gstPercentage: gstPercentage,
      cgstPercentage: cgstPct,
      sgstPercentage: sgstPct,
      igstPercentage: igstPct,
      cessPercentage: _SalesEntryParser.toDouble(
        raw['salesEntryDetail_CESSPercentage'] ?? raw['cessPercentage'],
      ),
      cgstAmount: cgstAmt,
      sgstAmount: sgstAmt,
      igstAmount: igstAmt,
      cessAmount: _SalesEntryParser.toDouble(
        raw['salesEntryDetail_CESSAmount'] ?? raw['cessAmount'],
      ),
      totalTaxAmount: totalTax,
      totalAmount: totalAmount > 0
          ? totalAmount
          : ((qty * rate) - discAmount + totalTax),
      landingPrice: _SalesEntryParser.toDouble(
        raw['salesEntryDetail_LandingPrice'] ?? raw['landingPrice'],
      ),
      purchasePrice: _SalesEntryParser.toDouble(
        raw['salesEntryDetail_PurchasePrice'] ?? raw['purchasePrice'],
      ),
      remark: raw['salesEntryDetail_Remark']?.toString() ?? '',
      createdBy: _SalesEntryParser.asInt(
        raw['salesDetail_CreatedBy'] ?? raw['createdBy'],
      ),
      modifiedBy: _SalesEntryParser.asInt(
        raw['salesDetail_ModifiedBy'] ?? raw['modifiedBy'],
      ),
      batchNumber:
          raw['batch_Number']?.toString() ??
          raw['batchNumber']?.toString() ??
          raw['batchNo']?.toString() ??
          raw['salesEntryDetail_BatchNumber']?.toString() ??
          '',
      expiry:
          raw['batch_ExpiryDate']?.toString() ??
          raw['batchExpiryDate']?.toString() ??
          raw['expiryDate']?.toString() ??
          '',
      unitName:
          raw['unit_ShortName']?.toString() ??
          raw['unitName']?.toString() ??
          raw['unit']?.toString() ??
          '',
      prodCode:
          raw['prod_Code']?.toString() ?? raw['productCode']?.toString() ?? '',
    );
  }

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

class SalesEntryReceiptMasterData {
  final int receiptMasterId;
  final int compId;
  final int branchId;
  final String receiptDate;
  final int customerId;
  final int ledgerId;
  final double totalAmount;
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
  final String remark;
  final String status;
  final bool isActive;
  final int createdBy;
  final int modifiedBy;

  SalesEntryReceiptMasterData({
    this.receiptMasterId = 0,
    this.compId = 0,
    this.branchId = 0,
    required this.receiptDate,
    required this.customerId,
    this.ledgerId = 0,
    this.totalAmount = 0,
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
    this.remark = '',
    this.status = '',
    this.isActive = true,
    this.createdBy = 0,
    this.modifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiptMaster_Id': receiptMasterId,
      'receiptMaster_CompId': compId,
      'receiptMaster_BranchId': branchId,
      'receiptMaster_ReceiptDate': receiptDate,
      'receiptMaster_CustomerId': customerId,
      'receiptMaster_LedgerId': ledgerId,
      'receiptMaster_TotalAmount': totalAmount,
      'receiptMaster_CashAmount': cashAmount,
      'receiptMaster_UPIAmount': upiAmount,
      'receiptMaster_CardAmount': cardAmount,
      'receiptMaster_ChequeAmount': chequeAmount,
      'receiptMaster_BankAmount': bankAmount,
      'receiptMaster_OtherAmount': otherAmount,
      'receiptMaster_ChequeNo': chequeNo,
      'receiptMaster_ChequeDate': chequeDate,
      'receiptMaster_BankName': bankName,
      'receiptMaster_BankReferenceNo': bankReferenceNo,
      'receiptMaster_NEFTType': neftType,
      'receiptMaster_NEFTReferenceNo': neftReferenceNo,
      'receiptMaster_OtherPaymentType': otherPaymentType,
      'receiptMaster_OtherReferenceNo': otherReferenceNo,
      'receiptMaster_OtherDate': otherDate,
      'receiptMaster_OtherRemark': otherRemark,
      'receiptMaster_Remark': remark,
      'receiptMaster_Status': status,
      'receiptMaster_IsActive': isActive,
      'receiptMaster_CreatedBy': createdBy,
      'receiptMaster_ModifiedBy': modifiedBy,
    };
  }
}

class SalesEntryReceiptDetailData {
  final int compId;
  final int branchId;
  final int customerId;
  final int ledgerId;
  final int salesMasterId;
  final double invoiceAmount;
  final double pendingAmount;
  final double receivedAmount;
  final double remainingAmount;
  final String remark;
  final int createdBy;
  final int modifiedBy;

  SalesEntryReceiptDetailData({
    this.compId = 0,
    this.branchId = 0,
    required this.customerId,
    this.ledgerId = 0,
    this.salesMasterId = 0,
    this.invoiceAmount = 0,
    this.pendingAmount = 0,
    this.receivedAmount = 0,
    this.remainingAmount = 0,
    this.remark = '',
    this.createdBy = 0,
    this.modifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiptDetail_CompId': compId,
      'receiptDetail_BranchId': branchId,
      'receiptDetail_CustomerId': customerId,
      'receiptDetail_LedgerId': ledgerId,
      'receiptDetail_SalesMasterId': salesMasterId,
      'receiptDetail_InvoiceAmount': invoiceAmount,
      'receiptDetail_PendingAmount': pendingAmount,
      'receiptDetail_ReceivedAmount': receivedAmount,
      'receiptDetail_RemainingAmount': remainingAmount,
      'receiptDetail_Remark': remark,
      'receiptDetail_CreatedBy': createdBy,
      'receiptDetail_ModifiedBy': modifiedBy,
    };
  }
}

class SalesEntryUpsertRequest {
  final SalesEntryMasterData masterData;
  final List<SalesEntryDetailData> detailData;
  final SalesEntryReceiptMasterData? receiptMasterData;
  final List<SalesEntryReceiptDetailData>? receiptDetailData;

  SalesEntryUpsertRequest({
    required this.masterData,
    required this.detailData,
    this.receiptMasterData,
    this.receiptDetailData,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "masterData": masterData.toJson(),
      "detailData": detailData.map((e) => e.toJson()).toList(),
    };

    if (receiptMasterData != null) {
      map["receiptMasterData"] = receiptMasterData!.toJson();
    }

    if (receiptDetailData != null) {
      map["receiptDetailData"] = receiptDetailData!
          .map((e) => e.toJson())
          .toList();
    }

    return map;
  }
}

class SalesEntryUpsertResponseData {
  final bool status;
  final String message;
  final int salesMasterId;
  final String salesMasterInvoiceNo;
  final int receiptMasterId;
  final String receiptMasterReceiptNo;

  SalesEntryUpsertResponseData({
    required this.status,
    required this.message,
    required this.salesMasterId,
    this.salesMasterInvoiceNo = '',
    this.receiptMasterId = 0,
    this.receiptMasterReceiptNo = '',
  });

  factory SalesEntryUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return SalesEntryUpsertResponseData(
      status:
          json['status'] == true ||
          json['status'] == 'true' ||
          json['status'] == 1,
      message: json['message']?.toString() ?? '',
      salesMasterId: _SalesEntryParser.asInt(json['salesMaster_Id']),
      salesMasterInvoiceNo: json['salesMaster_InvoiceNo']?.toString() ?? '',
      receiptMasterId: _SalesEntryParser.asInt(json['receiptMaster_Id']),
      receiptMasterReceiptNo: json['receiptMaster_ReceiptNo']?.toString() ?? '',
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

// --- Get Models ---
class SalesMasterListResponse {
  final bool status;
  final String message;
  final SalesMasterDataList? data;
  final String? error;

  SalesMasterListResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory SalesMasterListResponse.fromJson(Map<String, dynamic> json) {
    return SalesMasterListResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? SalesMasterDataList.fromJson(json['data'])
          : null,
      error: json['error']?.toString(),
    );
  }
}

class SalesMasterDataList {
  final List<SalesMasterData> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  SalesMasterDataList({
    required this.items,
    this.totalRecords = 0,
    this.totalPages = 0,
    this.currentPage = 0,
    this.pageSize = 0,
  });

  factory SalesMasterDataList.fromJson(Map<String, dynamic> json) {
    return SalesMasterDataList(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => SalesMasterData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRecords: _SalesEntryParser.asInt(json['totalRecords']),
      totalPages: _SalesEntryParser.asInt(json['totalPages']),
      currentPage: _SalesEntryParser.asInt(json['currentPage']),
      pageSize: _SalesEntryParser.asInt(json['pageSize']),
    );
  }
}

class SalesMasterData {
  final Map<String, dynamic> raw;

  SalesMasterData(this.raw);

  factory SalesMasterData.fromJson(Map<String, dynamic> json) {
    return SalesMasterData(json);
  }
}

class SalesDetailListResponse {
  final bool status;
  final String message;
  final List<SalesDetailData> data;
  final String? error;

  SalesDetailListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory SalesDetailListResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> items = [];
    final rawData = json['data'];
    if (rawData is List) {
      items = rawData;
    } else if (rawData is Map<String, dynamic>) {
      if (rawData['details'] is List) {
        items = rawData['details'];
      } else if (rawData['salesDetails'] is List) {
        items = rawData['salesDetails'];
      } else if (rawData['invoiceDetails'] is List) {
        items = rawData['invoiceDetails'];
      } else if (rawData['items'] is List) {
        items = rawData['items'];
      } else {
        items = [rawData];
      }
    } else if (json['items'] is List) {
      items = json['items'];
    }

    return SalesDetailListResponse(
      status:
          json['status'] == true ||
          json['status'] == 'true' ||
          json['status'] == 1,
      message: json['message']?.toString() ?? '',
      data: items
          .whereType<Map>()
          .map((e) => SalesDetailData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      error: json['error']?.toString(),
    );
  }
}

class SalesDetailData {
  final Map<String, dynamic> raw;

  SalesDetailData(this.raw);

  factory SalesDetailData.fromJson(Map<String, dynamic> json) {
    return SalesDetailData(json);
  }
}
