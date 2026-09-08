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
  final double prodGSTPercent; 
  final String batchBarcode;
  final String batchEANCode;
  final bool batchIsActive;

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
    this.batchBarcode = '',
    this.batchEANCode = '',
    this.batchIsActive = true,
  });

  factory BatchListItem.fromJson(Map<String, dynamic> json) {
    return BatchListItem(
      batchId: int.tryParse(json['batch_Id']?.toString() ?? '0') ?? 0,
      batchProductId:
          int.tryParse(json['batch_ProductId']?.toString() ?? '0') ?? 0,
      prodName: json['prod_Name']?.toString() ?? '',
      prodCode: json['prod_Code']?.toString() ?? '',
      unitName: json['unit_Name']?.toString() ?? '',
      prodUnitValue: _parseBatchDouble(
        _firstBatchJsonValue(json, const [
          'prod_UnitValue',
          'Prod_UnitValue',
          'prod_unitValue',
          'unit_Value',
          'UnitValue',
        ]),
      ),
      batchCompId: int.tryParse(json['batch_CompId']?.toString() ?? '0') ?? 0,
      compName: json['comp_Name']?.toString() ?? '',
      batchBranchId:
          int.tryParse(json['batch_BranchId']?.toString() ?? '0') ?? 0,
      branchName: json['branch_Name']?.toString() ?? '',
      batchStock:
          double.tryParse(json['batch_Stock']?.toString() ?? '0') ?? 0.0,
      batchAvailableStock:
          double.tryParse(json['batch_AvailableStock']?.toString() ?? '0') ??
          0.0,
      batchLandingPrice:
          double.tryParse(json['batch_LandingPrice']?.toString() ?? '0') ?? 0.0,
      batchPurchasePrice:
          double.tryParse(json['batch_PurchasePrice']?.toString() ?? '0') ??
          0.0,
      batchMRP: double.tryParse(json['batch_MRP']?.toString() ?? '0') ?? 0.0,
      batchSellingPrice:
          double.tryParse(json['batch_SellingPrice']?.toString() ?? '0') ?? 0.0,
      prodGSTPercent: _parseBatchDouble(
        _firstBatchJsonValue(json, const [
          'prod_GSTPercent',
          'Prod_GSTPercent',
          'prod_GstPercent',
          'GSTPercent',
          'gstPercent',
        ]),
      ),
      batchBarcode: json['batch_Barcode']?.toString() ?? '',
      batchEANCode: json['batch_EANCode']?.toString() ?? '',
      batchIsActive: json['batch_IsActive'] == true || json['batch_IsActive'] == 'true',
    );
  }

  String get formattedUnitValue {
    if (prodUnitValue.truncateToDouble() == prodUnitValue) {
      return prodUnitValue.toStringAsFixed(0);
    }
    return prodUnitValue.toStringAsFixed(2);
  }
}

double _parseBatchDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

dynamic _firstBatchJsonValue(Map<String, dynamic> json, List<String> keys) {
  final lowerMap = <String, dynamic>{
    for (final entry in json.entries) entry.key.toLowerCase(): entry.value,
  };
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
    final lower = key.toLowerCase();
    if (lowerMap.containsKey(lower)) return lowerMap[lower];
  }
  return null;
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

class BatchUpsertRequest {
  final int batchId;
  final int batchCompId;
  final int batchBranchId;
  final int batchProductId;
  final String batchBarcode;
  final String batchEANCode;
  final double batchStock;
  final double batchAvailableStock;
  final double batchLandingPrice;
  final double batchPurchasePrice;
  final double batchMRP;
  final double batchSellingPrice;
  final bool batchIsActive;
  final int batchCreatedBy;
  final int batchModifiedBy;

  BatchUpsertRequest({
    this.batchId = 0,
    required this.batchCompId,
    required this.batchBranchId,
    required this.batchProductId,
    this.batchBarcode = '',
    this.batchEANCode = '',
    this.batchStock = 0.0,
    this.batchAvailableStock = 0.0,
    this.batchLandingPrice = 0.0,
    this.batchPurchasePrice = 0.0,
    this.batchMRP = 0.0,
    this.batchSellingPrice = 0.0,
    this.batchIsActive = true,
    this.batchCreatedBy = 0,
    this.batchModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'batch_Id': batchId,
      'batch_CompId': batchCompId,
      'batch_BranchId': batchBranchId,
      'batch_ProductId': batchProductId,
      'batch_Barcode': batchBarcode,
      'batch_EANCode': batchEANCode,
      'batch_Stock': batchStock,
      'batch_AvailableStock': batchAvailableStock,
      'batch_LandingPrice': batchLandingPrice,
      'batch_PurchasePrice': batchPurchasePrice,
      'batch_MRP': batchMRP,
      'batch_SellingPrice': batchSellingPrice,
      'batch_IsActive': batchIsActive,
      'batch_CreatedBy': batchCreatedBy,
      'batch_ModifiedBy': batchModifiedBy,
    };
  }
}

class BatchUpsertResponseData {
  final bool status;
  final String message;
  final int batchId;
  final double oldStock;
  final double oldAvailableStock;
  final double newStock;
  final double newAvailableStock;

  BatchUpsertResponseData({
    required this.status,
    required this.message,
    required this.batchId,
    this.oldStock = 0.0,
    this.oldAvailableStock = 0.0,
    this.newStock = 0.0,
    this.newAvailableStock = 0.0,
  });

  factory BatchUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return BatchUpsertResponseData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      batchId: int.tryParse(json['batch_Id']?.toString() ?? '0') ?? 0,
      oldStock: double.tryParse(json['oldStock']?.toString() ?? '0') ?? 0.0,
      oldAvailableStock: double.tryParse(json['oldAvailableStock']?.toString() ?? '0') ?? 0.0,
      newStock: double.tryParse(json['newStock']?.toString() ?? '0') ?? 0.0,
      newAvailableStock: double.tryParse(json['newAvailableStock']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BatchUpsertResponse {
  final bool status;
  final String message;
  final BatchUpsertResponseData? data;
  final String? error;

  BatchUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory BatchUpsertResponse.fromJson(Map<String, dynamic> json) {
    return BatchUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? BatchUpsertResponseData.fromJson(json['data']) : null,
      error: json['error']?.toString(),
    );
  }
}
