class CustomerWiseSalesReportRequest {
  final int compId;
  final int branchId;
  final String fromDate;
  final String toDate;
  final int? customerId;
  final String searchText;
  final bool onlyOutstanding;
  final int pageNumber;
  final int pageSize;

  CustomerWiseSalesReportRequest({
    required this.compId,
    required this.branchId,
    required this.fromDate,
    required this.toDate,
    this.customerId,
    this.searchText = '',
    this.onlyOutstanding = false,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  Map<String, String> toQueryParameters() {
    final queryParams = <String, String>{
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'FromDate': fromDate,
      'ToDate': toDate,
      'SearchText': searchText,
      'OnlyOutstanding': onlyOutstanding.toString(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    if (customerId != null && customerId! > 0) {
      queryParams['CustomerId'] = customerId.toString();
    }

    return queryParams;
  }
}

class CustomerWiseSalesReportResponse {
  final bool status;
  final String message;
  final CustomerWiseSalesDataObj? data;
  final String? error;

  CustomerWiseSalesReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory CustomerWiseSalesReportResponse.fromJson(Map<String, dynamic> json) {
    return CustomerWiseSalesReportResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? CustomerWiseSalesDataObj.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}

class CustomerWiseSalesDataObj {
  final List<CustomerWiseSalesReportItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  CustomerWiseSalesDataObj({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory CustomerWiseSalesDataObj.fromJson(Map<String, dynamic> json) {
    return CustomerWiseSalesDataObj(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CustomerWiseSalesReportItem.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomerWiseSalesReportItem {
  final int srNo;
  final int compId;
  final int branchId;
  final int customerId;
  final int ledgerId;
  final String customerName;
  final String mobileNo;
  final String billingAddress;
  final String gstNo;
  final int totalInvoices;
  final double totalQty;
  final double subTotal;
  final double itemDiscount;
  final double billWiseDiscount;
  final double totalCGST;
  final double totalSGST;
  final double totalIGST;
  final double totalCESS;
  final double totalRoundOff;
  final double totalSales;
  final double totalReceived;
  final double totalOutstanding;
  final DateTime? salesMasterInvoiceDate;
  final DateTime? firstSaleDate;
  final DateTime? lastSaleDate;

  CustomerWiseSalesReportItem({
    required this.srNo,
    required this.compId,
    required this.branchId,
    required this.customerId,
    required this.ledgerId,
    required this.customerName,
    required this.mobileNo,
    required this.billingAddress,
    required this.gstNo,
    required this.totalInvoices,
    required this.totalQty,
    required this.subTotal,
    required this.itemDiscount,
    required this.billWiseDiscount,
    required this.totalCGST,
    required this.totalSGST,
    required this.totalIGST,
    required this.totalCESS,
    required this.totalRoundOff,
    required this.totalSales,
    required this.totalReceived,
    required this.totalOutstanding,
    this.salesMasterInvoiceDate,
    this.firstSaleDate,
    this.lastSaleDate,
  });

  factory CustomerWiseSalesReportItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return CustomerWiseSalesReportItem(
      srNo: (json['srNo'] ?? json['SrNo'] as num?)?.toInt() ?? 0,
      compId: (json['compId'] ?? json['CompId'] as num?)?.toInt() ?? 0,
      branchId: (json['branchId'] ?? json['BranchId'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] ?? json['CustomerId'] as num?)?.toInt() ?? 0,
      ledgerId: (json['ledgerId'] ?? json['LedgerId'] as num?)?.toInt() ?? 0,
      customerName:
          (json['customerName'] ?? json['CustomerName'])?.toString() ?? '',
      mobileNo: (json['mobileNo'] ?? json['MobileNo'])?.toString() ?? '',
      billingAddress:
          (json['billingAddress'] ?? json['BillingAddress'])?.toString() ?? '',
      gstNo: (json['gstNo'] ?? json['GstNo'])?.toString() ?? '',
      totalInvoices:
          (json['totalInvoices'] ?? json['TotalInvoices'] as num?)?.toInt() ?? 0,
      totalQty:
          (json['totalQty'] ?? json['TotalQty'] as num?)?.toDouble() ?? 0.0,
      subTotal:
          (json['subTotal'] ?? json['SubTotal'] as num?)?.toDouble() ?? 0.0,
      itemDiscount:
          (json['itemDiscount'] ?? json['ItemDiscount'] as num?)?.toDouble() ?? 0.0,
      billWiseDiscount: (json['billWiseDiscount'] ?? json['BillWiseDiscount']
              as num?)
          ?.toDouble() ??
          0.0,
      totalCGST:
          (json['totalCGST'] ?? json['TotalCGST'] as num?)?.toDouble() ?? 0.0,
      totalSGST:
          (json['totalSGST'] ?? json['TotalSGST'] as num?)?.toDouble() ?? 0.0,
      totalIGST:
          (json['totalIGST'] ?? json['TotalIGST'] as num?)?.toDouble() ?? 0.0,
      totalCESS:
          (json['totalCESS'] ?? json['TotalCESS'] as num?)?.toDouble() ?? 0.0,
      totalRoundOff:
          (json['totalRoundOff'] ?? json['TotalRoundOff'] as num?)?.toDouble() ??
              0.0,
      totalSales:
          (json['totalSales'] ?? json['TotalSales'] as num?)?.toDouble() ?? 0.0,
      totalReceived:
          (json['totalReceived'] ?? json['TotalReceived'] as num?)?.toDouble() ??
              0.0,
      totalOutstanding: (json['totalOutstanding'] ?? json['TotalOutstanding']
              as num?)
          ?.toDouble() ??
          0.0,
      salesMasterInvoiceDate: parseDate(
        json['salesMaster_InvoiceDate'] ??
            json['SalesMaster_InvoiceDate'] ??
            json['salesMasterInvoiceDate'],
      ),
      firstSaleDate: parseDate(json['firstSaleDate'] ?? json['FirstSaleDate']),
      lastSaleDate: parseDate(json['lastSaleDate'] ?? json['LastSaleDate']),
    );
  }
}
