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
  });

  // Backwards compatibility getters if needed, otherwise clean properties
  String get id => prodId.toString();
  String get name => prodName;
  String get code => prodCode;
  bool get isActive => prodIsActive;

  factory ProductListItem.fromJson(Map<String, dynamic> json) {
    return ProductListItem(
      prodId: int.tryParse(json['prod_Id']?.toString() ?? '0') ?? 0,
      prodCompId: int.tryParse(json['prod_CompId']?.toString() ?? '0') ?? 0,
      prodBranchId: int.tryParse(json['prod_BranchId']?.toString() ?? '0') ?? 0,
      prodCode: json['prod_Code']?.toString() ?? '',
      prodName: json['prod_Name']?.toString() ?? '',
      prodBrandId: int.tryParse(json['prod_BrandId']?.toString() ?? '0') ?? 0,
      prodCategoryId: int.tryParse(json['prod_CategoryId']?.toString() ?? '0') ?? 0,
      prodSubCategoryId: int.tryParse(json['prod_SubCategoryId']?.toString() ?? '0') ?? 0,
      prodUnitId: int.tryParse(json['prod_UnitId']?.toString() ?? '0') ?? 0,
      prodHSNCode: json['prod_HSNCode']?.toString() ?? '',
      prodGSTPercent: double.tryParse(json['prod_GSTPercent']?.toString() ?? '0') ?? 0.0,
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
      prodUnitName: json['prod_UnitName']?.toString() ?? '',
      prodUnitShortName: json['prod_UnitShortName']?.toString() ?? '',
      prodCreatedDate: json['prod_CreatedDate']?.toString(),
      prodModifiedDate: json['prod_ModifiedDate']?.toString(),
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
  final bool prodIsActive;
  final int prodCreatedBy;
  final int prodModifiedBy;

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
    this.prodIsActive = true,
    this.prodCreatedBy = 0,
    this.prodModifiedBy = 0,
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
      'prod_IsActive': prodIsActive,
      'prod_CreatedBy': prodCreatedBy,
      'prod_ModifiedBy': prodModifiedBy,
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
