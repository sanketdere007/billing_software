class ProductWiseSalesReturnItem {
  final int productId;
  final String productName;
  final int totalReturnEntries;
  final int totalBatches;
  final DateTime? firstReturnDate;
  final DateTime? lastReturnDate;
  final double totalReturnQty;
  final double totalFreeQty;
  final double totalReturnedUnits;
  final double totalSubTotal;
  final double totalDiscountAmount;
  final double totalTaxAmount;
  final double totalReturnAmount;
  final double returnQtyValue;
  final double returnMRPValue;
  final int totalRecords;
  final int rowNumber;
  final int pageNumber;
  final int pageSize;

  ProductWiseSalesReturnItem({
    required this.productId,
    required this.productName,
    required this.totalReturnEntries,
    required this.totalBatches,
    this.firstReturnDate,
    this.lastReturnDate,
    required this.totalReturnQty,
    required this.totalFreeQty,
    required this.totalReturnedUnits,
    required this.totalSubTotal,
    required this.totalDiscountAmount,
    required this.totalTaxAmount,
    required this.totalReturnAmount,
    required this.returnQtyValue,
    required this.returnMRPValue,
    required this.totalRecords,
    required this.rowNumber,
    required this.pageNumber,
    required this.pageSize,
  });

  factory ProductWiseSalesReturnItem.fromJson(Map<String, dynamic> json) {
    return ProductWiseSalesReturnItem(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      totalReturnEntries: (json['totalReturnEntries'] as num?)?.toInt() ?? 0,
      totalBatches: (json['totalBatches'] as num?)?.toInt() ?? 0,
      firstReturnDate: json['firstReturnDate'] != null
          ? DateTime.tryParse(json['firstReturnDate'].toString())
          : null,
      lastReturnDate: json['lastReturnDate'] != null
          ? DateTime.tryParse(json['lastReturnDate'].toString())
          : null,
      totalReturnQty: (json['totalReturnQty'] as num?)?.toDouble() ?? 0.0,
      totalFreeQty: (json['totalFreeQty'] as num?)?.toDouble() ?? 0.0,
      totalReturnedUnits:
          (json['totalReturnedUnits'] as num?)?.toDouble() ?? 0.0,
      totalSubTotal: (json['totalSubTotal'] as num?)?.toDouble() ?? 0.0,
      totalDiscountAmount:
          (json['totalDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      totalTaxAmount: (json['totalTaxAmount'] as num?)?.toDouble() ?? 0.0,
      totalReturnAmount:
          (json['totalReturnAmount'] as num?)?.toDouble() ?? 0.0,
      returnQtyValue: (json['returnQtyValue'] as num?)?.toDouble() ?? 0.0,
      returnMRPValue: (json['returnMRPValue'] as num?)?.toDouble() ?? 0.0,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductWiseSalesReturnResponse {
  final bool status;
  final String message;
  final List<ProductWiseSalesReturnItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final String error;

  ProductWiseSalesReturnResponse({
    required this.status,
    required this.message,
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.error,
  });

  factory ProductWiseSalesReturnResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final itemsList = (data['items'] as List<dynamic>?) ?? [];

    return ProductWiseSalesReturnResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      items: itemsList
          .map((e) =>
              ProductWiseSalesReturnItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecords: (data['totalRecords'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (data['currentPage'] as num?)?.toInt() ?? 0,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? 0,
      error: json['error']?.toString() ?? '',
    );
  }
}

class ProductWiseSalesReturnDetailItem {
  final int salesReturnMasterId;
  final String salesReturnMasterInvoiceNo;
  final DateTime? salesReturnMasterDate;
  final int salesReturnMasterCompId;
  final int salesReturnMasterBranchId;
  final int salesReturnMasterCustomerId;
  final String customerName;
  final int salesReturnMasterLedgerId;
  final String salesReturnMasterStatus;
  final String salesReturnMasterRemark;
  final int salesReturnDetailProductId;
  final int salesReturnDetailBatchId;
  final int salesReturnDetailUnitId;
  final double salesReturnDetailQty;
  final double salesReturnDetailFreeQty;
  final double salesReturnDetailSellingPrice;
  final double salesReturnDetailMRP;
  final double salesReturnDetailDiscountPercentage;
  final double salesReturnDetailDiscountAmount;
  final double salesReturnDetailTaxPercentage;
  final double salesReturnDetailTaxAmount;
  final double salesReturnDetailSubTotal;
  final double salesReturnDetailTotalAmount;
  final String salesReturnDetailRemark;
  final int rowNumber;

  ProductWiseSalesReturnDetailItem({
    required this.salesReturnMasterId,
    required this.salesReturnMasterInvoiceNo,
    this.salesReturnMasterDate,
    required this.salesReturnMasterCompId,
    required this.salesReturnMasterBranchId,
    required this.salesReturnMasterCustomerId,
    this.customerName = '',
    required this.salesReturnMasterLedgerId,
    required this.salesReturnMasterStatus,
    required this.salesReturnMasterRemark,
    required this.salesReturnDetailProductId,
    required this.salesReturnDetailBatchId,
    required this.salesReturnDetailUnitId,
    required this.salesReturnDetailQty,
    required this.salesReturnDetailFreeQty,
    required this.salesReturnDetailSellingPrice,
    required this.salesReturnDetailMRP,
    required this.salesReturnDetailDiscountPercentage,
    required this.salesReturnDetailDiscountAmount,
    required this.salesReturnDetailTaxPercentage,
    required this.salesReturnDetailTaxAmount,
    required this.salesReturnDetailSubTotal,
    required this.salesReturnDetailTotalAmount,
    required this.salesReturnDetailRemark,
    required this.rowNumber,
  });

  factory ProductWiseSalesReturnDetailItem.fromJson(Map<String, dynamic> json) {
    return ProductWiseSalesReturnDetailItem(
      salesReturnMasterId:
          (json['salesReturnMaster_Id'] as num?)?.toInt() ?? 0,
      salesReturnMasterInvoiceNo:
          json['salesReturnMaster_InvoiceNo']?.toString() ?? '',
      salesReturnMasterDate: json['salesReturnMaster_Date'] != null
          ? DateTime.tryParse(json['salesReturnMaster_Date'].toString())
          : null,
      salesReturnMasterCompId:
          (json['salesReturnMaster_CompId'] as num?)?.toInt() ?? 0,
      salesReturnMasterBranchId:
          (json['salesReturnMaster_BranchId'] as num?)?.toInt() ?? 0,
      salesReturnMasterCustomerId:
          (json['salesReturnMaster_CustomerId'] as num?)?.toInt() ?? 0,
      customerName: json['customerName']?.toString() ??
          json['salesReturnMaster_CustomerName']?.toString() ??
          '',
      salesReturnMasterLedgerId:
          (json['salesReturnMaster_LedgerId'] as num?)?.toInt() ?? 0,
      salesReturnMasterStatus:
          json['salesReturnMaster_Status']?.toString() ?? '',
      salesReturnMasterRemark:
          json['salesReturnMaster_Remark']?.toString() ?? '',
      salesReturnDetailProductId:
          (json['salesReturnDetail_ProductId'] as num?)?.toInt() ?? 0,
      salesReturnDetailBatchId:
          (json['salesReturnDetail_BatchId'] as num?)?.toInt() ?? 0,
      salesReturnDetailUnitId:
          (json['salesReturnDetail_UnitId'] as num?)?.toInt() ?? 0,
      salesReturnDetailQty:
          (json['salesReturnDetail_Qty'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailFreeQty:
          (json['salesReturnDetail_FreeQty'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailSellingPrice:
          (json['salesReturnDetail_SellingPrice'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailMRP:
          (json['salesReturnDetail_MRP'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailDiscountPercentage:
          (json['salesReturnDetail_DiscountPercentage'] as num?)?.toDouble() ??
              0.0,
      salesReturnDetailDiscountAmount:
          (json['salesReturnDetail_DiscountAmount'] as num?)?.toDouble() ??
              0.0,
      salesReturnDetailTaxPercentage:
          (json['salesReturnDetail_TaxPercentage'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailTaxAmount:
          (json['salesReturnDetail_TaxAmount'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailSubTotal:
          (json['salesReturnDetail_SubTotal'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailTotalAmount:
          (json['salesReturnDetail_TotalAmount'] as num?)?.toDouble() ?? 0.0,
      salesReturnDetailRemark:
          json['salesReturnDetail_Remark']?.toString() ?? '',
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductWiseSalesReturnDetailResponse {
  final bool status;
  final String message;
  final List<ProductWiseSalesReturnDetailItem> items;
  final int totalRecords;
  final double totalReturnQty;
  final double totalFreeQty;
  final double totalReturnAmount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final String error;

  ProductWiseSalesReturnDetailResponse({
    required this.status,
    required this.message,
    required this.items,
    required this.totalRecords,
    required this.totalReturnQty,
    required this.totalFreeQty,
    required this.totalReturnAmount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.error,
  });

  factory ProductWiseSalesReturnDetailResponse.fromJson(
      Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final itemsList = (data['items'] as List<dynamic>?) ?? [];

    return ProductWiseSalesReturnDetailResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      items: itemsList
          .map((e) => ProductWiseSalesReturnDetailItem.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      totalRecords: (data['totalRecords'] as num?)?.toInt() ?? 0,
      totalReturnQty: (data['totalReturnQty'] as num?)?.toDouble() ?? 0.0,
      totalFreeQty: (data['totalFreeQty'] as num?)?.toDouble() ?? 0.0,
      totalReturnAmount:
          (data['totalReturnAmount'] as num?)?.toDouble() ?? 0.0,
      currentPage: (data['currentPage'] as num?)?.toInt() ?? 0,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
      error: json['error']?.toString() ?? '',
    );
  }
}
