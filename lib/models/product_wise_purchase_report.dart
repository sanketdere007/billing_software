class ProductWisePurchaseItem {
  final int productId;
  final String productName;
  final double totalPurchaseQty;
  final int totalInvoices;
  final int totalPurchaseLines;
  final double totalDiscount;
  final double totalGST;
  final double totalPurchaseAmount;
  final DateTime? firstPurchaseDate;
  final DateTime? lastPurchaseDate;
  final int totalRecords;

  ProductWisePurchaseItem({
    required this.productId,
    required this.productName,
    required this.totalPurchaseQty,
    required this.totalInvoices,
    required this.totalPurchaseLines,
    required this.totalDiscount,
    required this.totalGST,
    required this.totalPurchaseAmount,
    this.firstPurchaseDate,
    this.lastPurchaseDate,
    required this.totalRecords,
  });

  factory ProductWisePurchaseItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return ProductWisePurchaseItem(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      totalPurchaseQty: (json['totalPurchaseQty'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      totalPurchaseLines: (json['totalPurchaseLines'] as num?)?.toInt() ?? 0,
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0.0,
      totalGST: (json['totalGST'] as num?)?.toDouble() ?? 0.0,
      totalPurchaseAmount:
          (json['totalPurchaseAmount'] as num?)?.toDouble() ?? 0.0,
      firstPurchaseDate: parseDate(json['firstPurchaseDate']),
      lastPurchaseDate: parseDate(json['lastPurchaseDate']),
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'totalPurchaseQty': totalPurchaseQty,
      'totalInvoices': totalInvoices,
      'totalPurchaseLines': totalPurchaseLines,
      'totalDiscount': totalDiscount,
      'totalGST': totalGST,
      'totalPurchaseAmount': totalPurchaseAmount,
      'firstPurchaseDate': firstPurchaseDate?.toIso8601String(),
      'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
      'totalRecords': totalRecords,
    };
  }
}

class ProductWisePurchaseData {
  final List<ProductWisePurchaseItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  ProductWisePurchaseData({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory ProductWisePurchaseData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ProductWisePurchaseData(
      items: rawItems
          .map((e) =>
              ProductWisePurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductWisePurchaseReportResponse {
  final bool status;
  final String message;
  final ProductWisePurchaseData? data;
  final String? error;

  ProductWisePurchaseReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory ProductWisePurchaseReportResponse.fromJson(Map<String, dynamic> json) {
    return ProductWisePurchaseReportResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? ProductWisePurchaseData.fromJson(
              json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}

class ProductWisePurchaseReportRequest {
  final int compId;
  final int branchId;
  final DateTime fromDate;
  final DateTime toDate;
  final int? productId;
  final int? supplierId;
  final String search;
  final int pageNumber;
  final int pageSize;

  ProductWisePurchaseReportRequest({
    required this.compId,
    required this.branchId,
    required this.fromDate,
    required this.toDate,
    this.productId,
    this.supplierId,
    this.search = '',
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  Map<String, String> toQueryParameters() {
    final fromDateApi = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
      0,
      0,
      0,
    );
    final toDateApi = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
      23,
      59,
      59,
      999,
    );

    final params = <String, String>{
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'FromDate': fromDateApi.toIso8601String(),
      'ToDate': toDateApi.toIso8601String(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    if (productId != null && productId! > 0) {
      params['ProductId'] = productId.toString();
    }
    if (supplierId != null && supplierId! > 0) {
      params['SupplierId'] = supplierId.toString();
    }
    if (search.trim().isNotEmpty) {
      params['Search'] = search.trim();
    }

    return params;
  }
}
