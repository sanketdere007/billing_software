class CustomerOutstandingReportItem {
  final int customerId;
  final String custCode;
  final String custName;
  final String custMobileNo;
  final double totalInvoiceAmount;
  final double totalPaidAmount;
  final double totalOutstanding;

  CustomerOutstandingReportItem({
    required this.customerId,
    required this.custCode,
    required this.custName,
    required this.custMobileNo,
    required this.totalInvoiceAmount,
    required this.totalPaidAmount,
    required this.totalOutstanding,
  });

  factory CustomerOutstandingReportItem.fromJson(Map<String, dynamic> json) {
    return CustomerOutstandingReportItem(
      customerId: json['customerId'] ?? 0,
      custCode: json['cust_Code'] ?? '',
      custName: json['cust_Name'] ?? '',
      custMobileNo: json['cust_MobileNo'] ?? '',
      totalInvoiceAmount: (json['totalInvoiceAmount'] ?? 0).toDouble(),
      totalPaidAmount: (json['totalPaidAmount'] ?? 0).toDouble(),
      totalOutstanding: (json['totalOutstanding'] ?? 0).toDouble(),
    );
  }
}

class CustomerOutstandingReportData {
  final List<CustomerOutstandingReportItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  CustomerOutstandingReportData({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory CustomerOutstandingReportData.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return CustomerOutstandingReportData(
      items: itemsList.map((e) => CustomerOutstandingReportItem.fromJson(e)).toList(),
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }
}

class CustomerOutstandingReportResponse {
  final bool status;
  final String message;
  final CustomerOutstandingReportData? data;
  final String? error;

  CustomerOutstandingReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory CustomerOutstandingReportResponse.fromJson(Map<String, dynamic> json) {
    return CustomerOutstandingReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CustomerOutstandingReportData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}
