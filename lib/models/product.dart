/// Product Model representing data structures for:
/// 1] GET `/api/Product/GetAllProducts`
/// 2] POST `/api/Product/InsertOrUpdateProduct`
class ProductListItem {
  final int prodId;
  final int prodCompId;
  final int prodBranchId;
  final String prodCode;
  final String prodName;
  final int prodBrandId;
  final int prodCategoryId;
  final int prodSubCategoryId;
  final int prodUnitId;
  final String prodHSNCode;
  final double prodGSTPercent;
  final double prodUnitValue;
  final bool prodIsActive;
  final int prodCreatedBy;
  final int prodModifiedBy;
  final String prodCompanyName;
  final String prodBranchName;
  final String prodBrandName;
  final String prodCategoryName;
  final String prodSubCategoryName;
  final String prodUnitName;
  final String prodUnitShortName;
  final String? prodCreatedDate;
  final String? prodModifiedDate;
  final String batchBarcode;
  final String batchEANCode;
  final double batchStock;
  final double batchLandingPrice;
  final double batchPurchasePrice;
  final double batchMRP;
  final double batchSellingPrice;

  ProductListItem({
    required this.prodId,
    this.prodCompId = 0,
    this.prodBranchId = 0,
    required this.prodCode,
    required this.prodName,
    this.prodBrandId = 0,
    this.prodCategoryId = 0,
    this.prodSubCategoryId = 0,
    this.prodUnitId = 0,
    this.prodHSNCode = '',
    this.prodGSTPercent = 0.0,
    this.prodUnitValue = 0.0,
    this.prodIsActive = true,
    this.prodCreatedBy = 0,
    this.prodModifiedBy = 0,
    this.prodCompanyName = '',
    this.prodBranchName = '',
    this.prodBrandName = '',
    this.prodCategoryName = '',
    this.prodSubCategoryName = '',
    this.prodUnitName = '',
    this.prodUnitShortName = '',
    this.prodCreatedDate,
    this.prodModifiedDate,
    this.batchBarcode = '',
    this.batchEANCode = '',
    this.batchStock = 0.0,
    this.batchLandingPrice = 0.0,
    this.batchPurchasePrice = 0.0,
    this.batchMRP = 0.0,
    this.batchSellingPrice = 0.0,
  });

  // Backwards compatibility getters if needed, otherwise clean properties
  String get id => prodId.toString();
  String get name => prodName;
  String get code => prodCode;
  bool get isActive => prodIsActive;

  String get formattedUnitValue {
    if (prodUnitValue.truncateToDouble() == prodUnitValue) {
      return prodUnitValue.toStringAsFixed(0);
    }
    return prodUnitValue.toStringAsFixed(2);
  }

  String get unitWithValue {
    final unit = prodUnitName.isNotEmpty
        ? prodUnitName
        : prodUnitShortName;
    if (unit.isEmpty) return formattedUnitValue;
    return '$unit ($formattedUnitValue)';
  }

  factory ProductListItem.fromJson(Map<String, dynamic> json) {
    return ProductListItem(
      prodId: _parseInt(json['prod_Id']),
      prodCompId: _parseInt(json['prod_CompId']),
      prodBranchId: _parseInt(json['prod_BranchId']),
      prodCode: json['prod_Code']?.toString() ?? '',
      prodName: json['prod_Name']?.toString() ?? '',
      prodBrandId: _parseInt(json['prod_BrandId']),
      prodCategoryId: _parseInt(json['prod_CategoryId']),
      prodSubCategoryId: _parseInt(json['prod_SubCategoryId']),
      prodUnitId: _parseInt(
        _firstJsonValue(json, const [
          'prod_UnitId',
          'Prod_UnitId',
          'prod_unitId',
          'unit_Id',
          'Unit_Id',
        ]),
      ),
      prodHSNCode: json['prod_HSNCode']?.toString() ?? '',
      prodGSTPercent: _parseDouble(
        _firstJsonValue(json, const [
          'prod_GSTPercent',
          'Prod_GSTPercent',
          'prod_GstPercent',
          'prod_GST',
          'GSTPercent',
        ]),
      ),
      prodUnitValue: _parseDouble(
        _firstJsonValue(json, const [
          'prod_UnitValue',
          'Prod_UnitValue',
          'prod_unitValue',
          'prod_Unitvalue',
          'unit_Value',
          'UnitValue',
        ]),
      ),
      prodIsActive: json['prod_IsActive'] == true ||
          json['prod_IsActive'] == 'true' ||
          json['prod_IsActive'] == 1 ||
          json['prod_IsActive'] == '1',
      prodCreatedBy: int.tryParse(json['prod_CreatedBy']?.toString() ?? '0') ?? 0,
      prodModifiedBy: int.tryParse(json['prod_ModifiedBy']?.toString() ?? '0') ?? 0,
      prodCompanyName: json['prod_CompanyName']?.toString() ?? '',
      prodBranchName: json['prod_BranchName']?.toString() ?? '',
      prodBrandName: json['prod_BrandName']?.toString() ?? '',
      prodCategoryName: json['prod_CategoryName']?.toString() ?? '',
      prodSubCategoryName: json['prod_SubCategoryName']?.toString() ?? '',
      prodUnitName:
          _firstJsonValue(json, const [
            'prod_UnitName',
            'Prod_UnitName',
            'unit_Name',
            'Unit_Name',
          ])?.toString() ??
          '',
      prodUnitShortName:
          _firstJsonValue(json, const [
            'prod_UnitShortName',
            'Prod_UnitShortName',
            'unit_ShortName',
          ])?.toString() ??
          '',
      prodCreatedDate: json['prod_CreatedDate']?.toString(),
      prodModifiedDate: json['prod_ModifiedDate']?.toString(),
      batchBarcode: json['batch_Barcode']?.toString() ?? '',
      batchEANCode: json['batch_EANCode']?.toString() ?? '',
      batchStock: double.tryParse(json['batch_Stock']?.toString() ?? '0') ?? 0.0,
      batchLandingPrice: double.tryParse(json['batch_LandingPrice']?.toString() ?? '0') ?? 0.0,
      batchPurchasePrice: double.tryParse(json['batch_PurchasePrice']?.toString() ?? '0') ?? 0.0,
      batchMRP: double.tryParse(json['batch_MRP']?.toString() ?? '0') ?? 0.0,
      batchSellingPrice: double.tryParse(json['batch_SellingPrice']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prod_Id': prodId,
      'prod_CompId': prodCompId,
      'prod_BranchId': prodBranchId,
      'prod_Code': prodCode,
      'prod_Name': prodName,
      'prod_BrandId': prodBrandId,
      'prod_CategoryId': prodCategoryId,
      'prod_SubCategoryId': prodSubCategoryId,
      'prod_UnitId': prodUnitId,
      'prod_HSNCode': prodHSNCode,
      'prod_GSTPercent': prodGSTPercent,
      'prod_UnitValue': prodUnitValue,
      'prod_IsActive': prodIsActive,
      'prod_CreatedBy': prodCreatedBy,
      'prod_ModifiedBy': prodModifiedBy,
      'prod_CompanyName': prodCompanyName,
      'prod_BranchName': prodBranchName,
      'prod_BrandName': prodBrandName,
      'prod_CategoryName': prodCategoryName,
      'prod_SubCategoryName': prodSubCategoryName,
      'prod_UnitName': prodUnitName,
      'prod_UnitShortName': prodUnitShortName,
      if (prodCreatedDate != null) 'prod_CreatedDate': prodCreatedDate,
      if (prodModifiedDate != null) 'prod_ModifiedDate': prodModifiedDate,
      'batch_Barcode': batchBarcode,
      'batch_EANCode': batchEANCode,
      'batch_Stock': batchStock,
      'batch_LandingPrice': batchLandingPrice,
      'batch_PurchasePrice': batchPurchasePrice,
      'batch_MRP': batchMRP,
      'batch_SellingPrice': batchSellingPrice,
    };
  }

  ProductListItem copyWith({
    int? prodId,
    int? prodCompId,
    int? prodBranchId,
    String? prodCode,
    String? prodName,
    int? prodBrandId,
    int? prodCategoryId,
    int? prodSubCategoryId,
    int? prodUnitId,
    String? prodHSNCode,
    double? prodGSTPercent,
    double? prodUnitValue,
    bool? prodIsActive,
    int? prodCreatedBy,
    int? prodModifiedBy,
    String? prodCompanyName,
    String? prodBranchName,
    String? prodBrandName,
    String? prodCategoryName,
    String? prodSubCategoryName,
    String? prodUnitName,
    String? prodUnitShortName,
    String? prodCreatedDate,
    String? prodModifiedDate,
  }) {
    return ProductListItem(
      prodId: prodId ?? this.prodId,
      prodCompId: prodCompId ?? this.prodCompId,
      prodBranchId: prodBranchId ?? this.prodBranchId,
      prodCode: prodCode ?? this.prodCode,
      prodName: prodName ?? this.prodName,
      prodBrandId: prodBrandId ?? this.prodBrandId,
      prodCategoryId: prodCategoryId ?? this.prodCategoryId,
      prodSubCategoryId: prodSubCategoryId ?? this.prodSubCategoryId,
      prodUnitId: prodUnitId ?? this.prodUnitId,
      prodHSNCode: prodHSNCode ?? this.prodHSNCode,
      prodGSTPercent: prodGSTPercent ?? this.prodGSTPercent,
      prodUnitValue: prodUnitValue ?? this.prodUnitValue,
      prodIsActive: prodIsActive ?? this.prodIsActive,
      prodCreatedBy: prodCreatedBy ?? this.prodCreatedBy,
      prodModifiedBy: prodModifiedBy ?? this.prodModifiedBy,
      prodCompanyName: prodCompanyName ?? this.prodCompanyName,
      prodBranchName: prodBranchName ?? this.prodBranchName,
      prodBrandName: prodBrandName ?? this.prodBrandName,
      prodCategoryName: prodCategoryName ?? this.prodCategoryName,
      prodSubCategoryName: prodSubCategoryName ?? this.prodSubCategoryName,
      prodUnitName: prodUnitName ?? this.prodUnitName,
      prodUnitShortName: prodUnitShortName ?? this.prodUnitShortName,
      prodCreatedDate: prodCreatedDate ?? this.prodCreatedDate,
      prodModifiedDate: prodModifiedDate ?? this.prodModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductListItem &&
          runtimeType == other.runtimeType &&
          prodId == other.prodId;

  @override
  int get hashCode => prodId.hashCode;

  @override
  String toString() => '$prodName ($prodCode)';
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString().split('.').first) ?? 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

dynamic _firstJsonValue(Map<String, dynamic> json, List<String> keys) {
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

/// Typedef for backwards compatibility
typedef Product = ProductListItem;

/// Response model for GET `/api/Product/GetAllProducts`
class ProductListResponse {
  final bool status;
  final String message;
  final List<ProductListItem> data;
  final String? error;

  ProductListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    List<ProductListItem> productList = [];
    if (json['data'] != null && json['data'] is List) {
      productList = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => ProductListItem.fromJson(item))
          .toList();
    }

    return ProductListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: productList,
      error: json['error']?.toString(),
    );
  }
}

class ProductUpsertRequest {
  final int prodId;
  final int prodCompId;
  final int prodBranchId;
  final String prodCode;
  final String prodName;
  final int prodBrandId;
  final int prodCategoryId;
  final int prodSubCategoryId;
  final int prodUnitId;
  final String prodHSNCode;
  final double prodGSTPercent;
  final double prodUnitValue;
  final bool prodIsActive;
  final int prodCreatedBy;
  final int prodModifiedBy;
  final String batchBarcode;
  final String batchEANCode;
  final double batchStock;
  final double batchLandingPrice;
  final double batchPurchasePrice;
  final double batchMRP;
  final double batchSellingPrice;

  ProductUpsertRequest({
    this.prodId = 0,
    this.prodCompId = 1,
    this.prodBranchId = 1,
    this.prodCode = '',
    required this.prodName,
    this.prodBrandId = 0,
    this.prodCategoryId = 0,
    this.prodSubCategoryId = 0,
    this.prodUnitId = 0,
    this.prodHSNCode = '',
    this.prodGSTPercent = 0.0,
    this.prodUnitValue = 0.0,
    this.prodIsActive = true,
    this.prodCreatedBy = 0,
    this.prodModifiedBy = 0,
    this.batchBarcode = '',
    this.batchEANCode = '',
    this.batchStock = 0.0,
    this.batchLandingPrice = 0.0,
    this.batchPurchasePrice = 0.0,
    this.batchMRP = 0.0,
    this.batchSellingPrice = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'prod_Id': prodId,
      'prod_CompId': prodCompId,
      'prod_BranchId': prodBranchId,
      'prod_Code': prodCode.trim(),
      'prod_Name': prodName.trim(),
      'prod_BrandId': prodBrandId,
      'prod_CategoryId': prodCategoryId,
      'prod_SubCategoryId': prodSubCategoryId,
      'prod_UnitId': prodUnitId,
      'prod_HSNCode': prodHSNCode.trim(),
      'prod_GSTPercent': prodGSTPercent,
      'prod_UnitValue': prodUnitValue,
      'prod_IsActive': prodIsActive,
      'prod_CreatedBy': prodCreatedBy,
      'prod_ModifiedBy': prodModifiedBy,
      'batch_Barcode': batchBarcode.trim(),
      'batch_EANCode': batchEANCode.trim(),
      'batch_Stock': batchStock,
      'batch_LandingPrice': batchLandingPrice,
      'batch_PurchasePrice': batchPurchasePrice,
      'batch_MRP': batchMRP,
      'batch_SellingPrice': batchSellingPrice,
    };
  }
}

/// Data payload of POST `/api/Product/InsertOrUpdateProduct` response
class ProductUpsertResultData {
  final bool status;
  final String message;
  final int prodId;

  ProductUpsertResultData({
    required this.status,
    required this.message,
    required this.prodId,
  });

  factory ProductUpsertResultData.fromJson(Map<String, dynamic> json) {
    return ProductUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      prodId: int.tryParse(json['prod_Id']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Full response model for POST `/api/Product/InsertOrUpdateProduct`
class ProductUpsertResponse {
  final bool status;
  final String message;
  final ProductUpsertResultData? data;
  final String? error;

  ProductUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory ProductUpsertResponse.fromJson(Map<String, dynamic> json) {
    ProductUpsertResultData? resultData;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      resultData = ProductUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return ProductUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: resultData,
      error: json['error']?.toString(),
    );
  }
}
