class ProductWiseSalesItem {
  final int productId;
  final String productName;
  final String hsnCode;
  final double totalQty;
  final double totalFreeQty;
  final double totalOverallQty;
  final double totalTaxableAmount;
  final double totalTaxAmount;
  final double totalAmount;
  final int totalInvoices;
  final int totalRecords;
  final int pageNumber;
  final int pageSize;

  ProductWiseSalesItem({
    required this.productId,
    required this.productName,
    required this.hsnCode,
    required this.totalQty,
    required this.totalFreeQty,
    required this.totalOverallQty,
    required this.totalTaxableAmount,
    required this.totalTaxAmount,
    required this.totalAmount,
    required this.totalInvoices,
    required this.totalRecords,
    required this.pageNumber,
    required this.pageSize,
  });

  factory ProductWiseSalesItem.fromJson(Map<String, dynamic> json) {
    return ProductWiseSalesItem(
      productId: json['productId'] as int? ?? 0,
      productName: json['productName']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString() ?? '',
      totalQty: (json['totalQty'] as num?)?.toDouble() ?? 0.0,
      totalFreeQty: (json['totalFreeQty'] as num?)?.toDouble() ?? 0.0,
      totalOverallQty: (json['totalOverallQty'] as num?)?.toDouble() ?? 0.0,
      totalTaxableAmount: (json['totalTaxableAmount'] as num?)?.toDouble() ?? 0.0,
      totalTaxAmount: (json['totalTaxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: json['totalInvoices'] as int? ?? 0,
      totalRecords: json['totalRecords'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 0,
    );
  }
}

class ProductWiseSalesResponse {
  final bool status;
  final String message;
  final List<ProductWiseSalesItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final String error;

  ProductWiseSalesResponse({
    required this.status,
    required this.message,
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.error,
  });

  factory ProductWiseSalesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    
    return ProductWiseSalesResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      items: itemsList.map((e) => ProductWiseSalesItem.fromJson(e as Map<String, dynamic>)).toList(),
      totalRecords: data['totalRecords'] as int? ?? 0,
      totalPages: data['totalPages'] as int? ?? 0,
      currentPage: data['currentPage'] as int? ?? 0,
      pageSize: data['pageSize'] as int? ?? 0,
      error: json['error']?.toString() ?? '',
    );
  }
}

class ProductWiseCustomerPurchaseItem {
  final int customerId;
  final String customerName;
  final String customerMobile;
  final DateTime? purchaseDate;
  final int salesMasterId;
  final double qty;
  final double freeQty;
  final double totalQty;
  final double rate;
  final double amount;
  final int totalRecords;
  final int pageNumber;
  final int pageSize;

  ProductWiseCustomerPurchaseItem({
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    this.purchaseDate,
    required this.salesMasterId,
    required this.qty,
    required this.freeQty,
    required this.totalQty,
    required this.rate,
    required this.amount,
    required this.totalRecords,
    required this.pageNumber,
    required this.pageSize,
  });

  factory ProductWiseCustomerPurchaseItem.fromJson(Map<String, dynamic> json) {
    return ProductWiseCustomerPurchaseItem(
      customerId: json['customerId'] as int? ?? 0,
      customerName: json['customerName']?.toString() ?? '',
      customerMobile: json['customerMobile']?.toString() ?? '',
      purchaseDate: json['purchaseDate'] != null ? DateTime.tryParse(json['purchaseDate'].toString()) : null,
      salesMasterId: json['salesMasterId'] as int? ?? 0,
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      freeQty: (json['freeQty'] as num?)?.toDouble() ?? 0.0,
      totalQty: (json['totalQty'] as num?)?.toDouble() ?? 0.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      totalRecords: json['totalRecords'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 0,
    );
  }
}

class ProductWiseCustomerPurchaseResponse {
  final bool status;
  final String message;
  final List<ProductWiseCustomerPurchaseItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final String error;

  ProductWiseCustomerPurchaseResponse({
    required this.status,
    required this.message,
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.error,
  });

  factory ProductWiseCustomerPurchaseResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    
    return ProductWiseCustomerPurchaseResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      items: itemsList.map((e) => ProductWiseCustomerPurchaseItem.fromJson(e as Map<String, dynamic>)).toList(),
      totalRecords: data['totalRecords'] as int? ?? 0,
      totalPages: data['totalPages'] as int? ?? 0,
      currentPage: data['currentPage'] as int? ?? 0,
      pageSize: data['pageSize'] as int? ?? 0,
      error: json['error']?.toString() ?? '',
    );
  }
}
