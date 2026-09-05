class CurrentStock {
  final int compId;
  final int branchId;
  final int productId;
  final String productName;
  final int unitId;
  final double unitValue;
  final String unitName;
  final String unitShortName;
  final int brandId;
  final String brandName;
  final int categoryId;
  final String categoryName;
  final int subCategoryId;
  final String subCategoryName;
  final double stock;
  final double availableStock;
  final double landingPrice;
  final double purchasePrice;
  final double mrp;
  final double sellingPrice;
  final bool isActive;
  final DateTime? createdDate;
  final DateTime? modifiedDate;

  CurrentStock({
    required this.compId,
    required this.branchId,
    required this.productId,
    this.productName = '',
    required this.unitId,
    required this.unitValue,
    required this.unitName,
    required this.unitShortName,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.stock,
    required this.availableStock,
    required this.landingPrice,
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    required this.isActive,
    this.createdDate,
    this.modifiedDate,
  });

  factory CurrentStock.fromJson(Map<String, dynamic> json) {
    return CurrentStock(
      compId: int.tryParse(json['batch_CompId']?.toString() ?? '0') ?? 0,
      branchId: int.tryParse(json['batch_BranchId']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['batch_ProductId']?.toString() ?? '0') ?? 0,
      productName: json['prod_Name']?.toString() ?? json['productName']?.toString() ?? json['ProductName']?.toString() ?? '',
      unitId: int.tryParse(json['prod_UnitId']?.toString() ?? '0') ?? 0,
      unitValue: double.tryParse(json['prod_UnitValue']?.toString() ?? '0') ?? 0.0,
      unitName: json['unitName']?.toString() ?? '',
      unitShortName: json['unitShortName']?.toString() ?? '',
      brandId: int.tryParse(json['prod_BrandId']?.toString() ?? '0') ?? 0,
      brandName: json['brandName']?.toString() ?? '',
      categoryId: int.tryParse(json['prod_CategoryId']?.toString() ?? '0') ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      subCategoryId: int.tryParse(json['prod_SubCategoryId']?.toString() ?? '0') ?? 0,
      subCategoryName: json['subCategoryName']?.toString() ?? '',
      stock: double.tryParse(json['batch_Stock']?.toString() ?? '0') ?? 0.0,
      availableStock: double.tryParse(json['batch_AvailableStock']?.toString() ?? '0') ?? 0.0,
      landingPrice: double.tryParse(json['batch_LandingPrice']?.toString() ?? '0') ?? 0.0,
      purchasePrice: double.tryParse(json['batch_PurchasePrice']?.toString() ?? '0') ?? 0.0,
      mrp: double.tryParse(json['batch_MRP']?.toString() ?? '0') ?? 0.0,
      sellingPrice: double.tryParse(json['batch_SellingPrice']?.toString() ?? '0') ?? 0.0,
      isActive: json['batch_IsActive'] == 1 || json['batch_IsActive'] == true || json['batch_IsActive'] == '1',
      createdDate: json['batch_CreatedDate'] != null ? DateTime.tryParse(json['batch_CreatedDate']) : null,
      modifiedDate: json['batch_ModifiedDate'] != null ? DateTime.tryParse(json['batch_ModifiedDate']) : null,
    );
  }
}

class CurrentStockResponse {
  final bool status;
  final String message;
  final List<CurrentStock> data;
  final String? error;

  CurrentStockResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory CurrentStockResponse.fromJson(Map<String, dynamic> json) {
    List<CurrentStock> list = [];
    if (json['data'] != null && json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => CurrentStock.fromJson(item))
          .toList();
    }

    return CurrentStockResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: list,
      error: json['error']?.toString(),
    );
  }
}
