class BatchListItem {
  final int batchId;
  final int batchProductId;
  final String prodName;
  final String prodCode;
  final String unitName;
  final double prodUnitValue;
  final int batchCompId;
  final String compName;
  final int batchBranchId;
  final String branchName;
  final double batchStock;
  final double batchAvailableStock;
  final double batchLandingPrice;
  final double batchPurchasePrice;
  final double batchMRP;
  final double batchSellingPrice;
  final double prodGSTPercent; // Keep this in case API returns it or we need it

  BatchListItem({
    required this.batchId,
    required this.batchProductId,
    required this.prodName,
    required this.prodCode,
    required this.unitName,
    required this.prodUnitValue,
    required this.batchCompId,
    required this.compName,
    required this.batchBranchId,
    required this.branchName,
    required this.batchStock,
    required this.batchAvailableStock,
    required this.batchLandingPrice,
    required this.batchPurchasePrice,
    required this.batchMRP,
    required this.batchSellingPrice,
    this.prodGSTPercent = 0.0,
  });

  factory BatchListItem.fromJson(Map<String, dynamic> json) {
    return BatchListItem(
      batchId: int.tryParse(json['batch_Id']?.toString() ?? '0') ?? 0,
      batchProductId: int.tryParse(json['batch_ProductId']?.toString() ?? '0') ?? 0,
      prodName: json['prod_Name']?.toString() ?? '',
      prodCode: json['prod_Code']?.toString() ?? '',
      unitName: json['unit_Name']?.toString() ?? '',
      prodUnitValue: double.tryParse(json['prod_UnitValue']?.toString() ?? '0') ?? 0.0,
      batchCompId: int.tryParse(json['batch_CompId']?.toString() ?? '0') ?? 0,
      compName: json['comp_Name']?.toString() ?? '',
      batchBranchId: int.tryParse(json['batch_BranchId']?.toString() ?? '0') ?? 0,
      branchName: json['branch_Name']?.toString() ?? '',
      batchStock: double.tryParse(json['batch_Stock']?.toString() ?? '0') ?? 0.0,
      batchAvailableStock: double.tryParse(json['batch_AvailableStock']?.toString() ?? '0') ?? 0.0,
      batchLandingPrice: double.tryParse(json['batch_LandingPrice']?.toString() ?? '0') ?? 0.0,
      batchPurchasePrice: double.tryParse(json['batch_PurchasePrice']?.toString() ?? '0') ?? 0.0,
      batchMRP: double.tryParse(json['batch_MRP']?.toString() ?? '0') ?? 0.0,
      batchSellingPrice: double.tryParse(json['batch_SellingPrice']?.toString() ?? '0') ?? 0.0,
      prodGSTPercent: double.tryParse(json['prod_GSTPercent']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BatchListResponse {
  final bool status;
  final String message;
  final List<BatchListItem> data;
  final String? error;

  BatchListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory BatchListResponse.fromJson(Map<String, dynamic> json) {
    List<BatchListItem> batchList = [];
    if (json['data'] != null && json['data'] is List) {
      batchList = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => BatchListItem.fromJson(item))
          .toList();
    }

    return BatchListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: batchList,
      error: json['error']?.toString(),
    );
  }
}
