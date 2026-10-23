/// Model for Low Stock Report (`/api/Report/LowStockReport`)
class LowStockItem {
  final int batchCompId;
  final int batchBranchId;
  final int batchProductId;
  final String productName;
  final String unitShortName;
  final double unitValue;
  final double totalStock;
  final double availableStock;
  final double stockShortage;
  final int batchCount;
  final int totalRecords;

  LowStockItem({
    required this.batchCompId,
    required this.batchBranchId,
    required this.batchProductId,
    required this.productName,
    required this.unitShortName,
    required this.unitValue,
    required this.totalStock,
    required this.availableStock,
    required this.stockShortage,
    required this.batchCount,
    required this.totalRecords,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      batchCompId: (json['batch_CompId'] as num?)?.toInt() ?? 0,
      batchBranchId: (json['batch_BranchId'] as num?)?.toInt() ?? 0,
      batchProductId: (json['batch_ProductId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      unitShortName: json['unitShortName']?.toString() ?? '',
      unitValue: (json['unitValue'] as num?)?.toDouble() ?? 0.0,
      totalStock: (json['totalStock'] as num?)?.toDouble() ?? 0.0,
      availableStock: (json['availableStock'] as num?)?.toDouble() ?? 0.0,
      stockShortage: (json['stockShortage'] as num?)?.toDouble() ?? 0.0,
      batchCount: (json['batchCount'] as num?)?.toInt() ?? 0,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_CompId': batchCompId,
      'batch_BranchId': batchBranchId,
      'batch_ProductId': batchProductId,
      'productName': productName,
      'unitShortName': unitShortName,
      'unitValue': unitValue,
      'totalStock': totalStock,
      'availableStock': availableStock,
      'stockShortage': stockShortage,
      'batchCount': batchCount,
      'totalRecords': totalRecords,
    };
  }
}

class LowStockReportData {
  final List<LowStockItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  LowStockReportData({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory LowStockReportData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return LowStockReportData(
      items: rawItems
          .map((e) => LowStockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    );
  }
}

class LowStockReportResponse {
  final bool status;
  final String message;
  final LowStockReportData? data;
  final String? error;

  LowStockReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory LowStockReportResponse.fromJson(Map<String, dynamic> json) {
    return LowStockReportResponse(
      status: json['status'] == true ||
          json['status'] == 1 ||
          json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? LowStockReportData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}

class LowStockReportRequest {
  final int compId;
  final int branchId;
  final double? lowStockQty;
  final int? productId;
  final String? search;
  final int pageNumber;
  final int pageSize;

  LowStockReportRequest({
    required this.compId,
    required this.branchId,
    this.lowStockQty,
    this.productId,
    this.search,
    this.pageNumber = 1,
    this.pageSize = 30,
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    if (lowStockQty != null) {
      params['LowStockQty'] = lowStockQty.toString();
    }
    if (productId != null && productId! > 0) {
      params['ProductId'] = productId.toString();
    }
    if (search != null && search!.trim().isNotEmpty) {
      params['Search'] = search!.trim();
    }

    return params;
  }
}
