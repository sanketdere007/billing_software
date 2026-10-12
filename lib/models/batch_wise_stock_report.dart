class BatchWiseStockItem {
  final int batchId;
  final int batchCompId;
  final int batchBranchId;
  final int batchProductId;
  final String prodName;
  final double prodUnitValue;
  final String unitShortName;
  final String batchBarcode;
  final String batchEanCode;
  final String batchNumber;
  final double batchStock;
  final double batchAvailableStock;
  final double batchLandingPrice;
  final double batchPurchasePrice;
  final double batchMrp;
  final double batchSellingPrice;
  final int totalRecords;

  BatchWiseStockItem({
    required this.batchId,
    required this.batchCompId,
    required this.batchBranchId,
    required this.batchProductId,
    required this.prodName,
    required this.prodUnitValue,
    required this.unitShortName,
    required this.batchBarcode,
    required this.batchEanCode,
    required this.batchNumber,
    required this.batchStock,
    required this.batchAvailableStock,
    required this.batchLandingPrice,
    required this.batchPurchasePrice,
    required this.batchMrp,
    required this.batchSellingPrice,
    required this.totalRecords,
  });

  factory BatchWiseStockItem.fromJson(Map<String, dynamic> json) {
    return BatchWiseStockItem(
      batchId: int.tryParse(json['batch_Id']?.toString() ?? '0') ?? 0,
      batchCompId: int.tryParse(json['batch_CompId']?.toString() ?? '0') ?? 0,
      batchBranchId: int.tryParse(json['batch_BranchId']?.toString() ?? '0') ?? 0,
      batchProductId: int.tryParse(json['batch_ProductId']?.toString() ?? '0') ?? 0,
      prodName: json['prod_Name']?.toString() ?? '',
      prodUnitValue: double.tryParse(json['prod_UnitValue']?.toString() ?? '0') ?? 0.0,
      unitShortName: json['unit_ShortName']?.toString() ?? '',
      batchBarcode: json['batch_Barcode']?.toString() ?? '',
      batchEanCode: json['batch_EANCode']?.toString() ?? '',
      batchNumber: json['batch_Number']?.toString() ?? '',
      batchStock: double.tryParse(json['batch_Stock']?.toString() ?? '0') ?? 0.0,
      batchAvailableStock: double.tryParse(json['batch_AvailableStock']?.toString() ?? '0') ?? 0.0,
      batchLandingPrice: double.tryParse(json['batch_LandingPrice']?.toString() ?? '0') ?? 0.0,
      batchPurchasePrice: double.tryParse(json['batch_PurchasePrice']?.toString() ?? '0') ?? 0.0,
      batchMrp: double.tryParse(json['batch_MRP']?.toString() ?? '0') ?? 0.0,
      batchSellingPrice: double.tryParse(json['batch_SellingPrice']?.toString() ?? '0') ?? 0.0,
      totalRecords: int.tryParse(json['totalRecords']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_Id': batchId,
      'batch_CompId': batchCompId,
      'batch_BranchId': batchBranchId,
      'batch_ProductId': batchProductId,
      'prod_Name': prodName,
      'prod_UnitValue': prodUnitValue,
      'unit_ShortName': unitShortName,
      'batch_Barcode': batchBarcode,
      'batch_EANCode': batchEanCode,
      'batch_Number': batchNumber,
      'batch_Stock': batchStock,
      'batch_AvailableStock': batchAvailableStock,
      'batch_LandingPrice': batchLandingPrice,
      'batch_PurchasePrice': batchPurchasePrice,
      'batch_MRP': batchMrp,
      'batch_SellingPrice': batchSellingPrice,
      'totalRecords': totalRecords,
    };
  }
}

class BatchWiseStockData {
  final List<BatchWiseStockItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  BatchWiseStockData({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory BatchWiseStockData.fromJson(Map<String, dynamic> json) {
    return BatchWiseStockData(
      items: (json['items'] as List?)
              ?.map((e) => BatchWiseStockItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRecords: int.tryParse(json['totalRecords']?.toString() ?? '0') ?? 0,
      totalPages: int.tryParse(json['totalPages']?.toString() ?? '0') ?? 0,
      currentPage: int.tryParse(json['currentPage']?.toString() ?? '0') ?? 0,
      pageSize: int.tryParse(json['pageSize']?.toString() ?? '0') ?? 0,
    );
  }
}

class BatchWiseStockReportResponse {
  final bool status;
  final String message;
  final BatchWiseStockData? data;
  final String? error;

  BatchWiseStockReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory BatchWiseStockReportResponse.fromJson(Map<String, dynamic> json) {
    return BatchWiseStockReportResponse(
      status: json['status'] == true || json['status'] == 1 || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? BatchWiseStockData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}
