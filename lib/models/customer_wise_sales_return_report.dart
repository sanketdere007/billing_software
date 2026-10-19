class CustomerWiseSalesReturnStatement {
  final int customerId;
  final String customerCode;
  final String customerName;
  final String mobileNo;
  final int returnId;
  final String billNo;
  final DateTime? returnDate;
  final double billAmount;
  final double paidAmount;
  final double balanceAmount;
  final int days;
  final int salesmanId;
  final String rowType;

  CustomerWiseSalesReturnStatement({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.mobileNo,
    required this.returnId,
    required this.billNo,
    this.returnDate,
    required this.billAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.days,
    required this.salesmanId,
    required this.rowType,
  });

  factory CustomerWiseSalesReturnStatement.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateVal = json['returnDate'] ?? json['salesReturnMaster_Date'] ?? json['date'];
    if (dateVal != null) {
      parsedDate = DateTime.tryParse(dateVal.toString());
    }

    return CustomerWiseSalesReturnStatement(
      customerId: _parseInt(json['customerId'] ?? json['custId'] ?? json['cust_Id']),
      customerCode: (json['customerCode'] ?? json['custCode'] ?? json['cust_Code'] ?? '').toString(),
      customerName: (json['customerName'] ?? json['custName'] ?? json['cust_Name'] ?? '').toString(),
      mobileNo: (json['mobileNo'] ?? json['custMobileNo'] ?? json['cust_MobileNo'] ?? '').toString(),
      returnId: _parseInt(json['returnId'] ?? json['salesReturnMasterId'] ?? json['salesReturnMaster_Id'] ?? json['return_Id']),
      billNo: (json['billNo'] ?? json['salesReturnMaster_InvoiceNo'] ?? json['invoiceNo'] ?? '').toString(),
      returnDate: parsedDate,
      billAmount: _parseDouble(json['billAmount'] ?? json['grandTotal'] ?? json['totalAmount']),
      paidAmount: _parseDouble(json['paidAmount']),
      balanceAmount: _parseDouble(json['balanceAmount']),
      days: _parseInt(json['days'] ?? json['daysOutstanding']),
      salesmanId: _parseInt(json['salesmanId'] ?? json['salesman_Id']),
      rowType: (json['rowType'] ?? '').toString(),
    );
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

class CustomerWiseSalesReturnPartyTotal {
  final int customerId;
  final String customerCode;
  final String customerName;
  final int totalReturns;
  final double totalBillAmount;
  final double totalPaidAmount;
  final double totalBalanceAmount;
  final String rowType;

  CustomerWiseSalesReturnPartyTotal({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.totalReturns,
    required this.totalBillAmount,
    required this.totalPaidAmount,
    required this.totalBalanceAmount,
    required this.rowType,
  });

  factory CustomerWiseSalesReturnPartyTotal.fromJson(Map<String, dynamic> json) {
    return CustomerWiseSalesReturnPartyTotal(
      customerId: CustomerWiseSalesReturnStatement._parseInt(
        json['customerId'] ?? json['custId'] ?? json['cust_Id'],
      ),
      customerCode: (json['customerCode'] ?? json['custCode'] ?? json['cust_Code'] ?? '').toString(),
      customerName: (json['customerName'] ?? json['custName'] ?? json['cust_Name'] ?? '').toString(),
      totalReturns: CustomerWiseSalesReturnStatement._parseInt(
        json['totalReturns'] ?? json['totalInvoices'] ?? json['totalCount'],
      ),
      totalBillAmount: CustomerWiseSalesReturnStatement._parseDouble(
        json['totalBillAmount'] ?? json['totalBillAmt'],
      ),
      totalPaidAmount: CustomerWiseSalesReturnStatement._parseDouble(
        json['totalPaidAmount'] ?? json['totalPaidAmt'],
      ),
      totalBalanceAmount: CustomerWiseSalesReturnStatement._parseDouble(
        json['totalBalanceAmount'] ?? json['totalBalanceAmt'],
      ),
      rowType: (json['rowType'] ?? '').toString(),
    );
  }
}

class CustomerWiseSalesReturnGrandTotal {
  final int totalReturns;
  final int totalCustomers;
  final double grandTotalBillAmount;
  final double grandTotalPaidAmount;
  final double grandTotalBalanceAmount;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  CustomerWiseSalesReturnGrandTotal({
    required this.totalReturns,
    required this.totalCustomers,
    required this.grandTotalBillAmount,
    required this.grandTotalPaidAmount,
    required this.grandTotalBalanceAmount,
    this.totalPages = 0,
    this.currentPage = 0,
    this.pageSize = 0,
  });

  factory CustomerWiseSalesReturnGrandTotal.fromJson(Map<String, dynamic> json) {
    return CustomerWiseSalesReturnGrandTotal(
      totalReturns: CustomerWiseSalesReturnStatement._parseInt(
        json['totalReturns'] ?? json['totalInvoices'],
      ),
      totalCustomers: CustomerWiseSalesReturnStatement._parseInt(json['totalCustomers']),
      grandTotalBillAmount: CustomerWiseSalesReturnStatement._parseDouble(
        json['grandTotalBillAmount'] ?? json['grandTotalBillAmt'],
      ),
      grandTotalPaidAmount: CustomerWiseSalesReturnStatement._parseDouble(
        json['grandTotalPaidAmount'] ?? json['grandTotalPaidAmt'],
      ),
      grandTotalBalanceAmount: CustomerWiseSalesReturnStatement._parseDouble(
        json['grandTotalBalanceAmount'] ?? json['grandTotalBalanceAmt'],
      ),
      totalPages: CustomerWiseSalesReturnStatement._parseInt(json['totalPages']),
      currentPage: CustomerWiseSalesReturnStatement._parseInt(json['currentPage']),
      pageSize: CustomerWiseSalesReturnStatement._parseInt(json['pageSize']),
    );
  }
}

class CustomerWiseSalesReturnReportData {
  final List<CustomerWiseSalesReturnStatement> statement;
  final List<CustomerWiseSalesReturnPartyTotal> partyTotals;
  final CustomerWiseSalesReturnGrandTotal? grandTotal;

  CustomerWiseSalesReturnReportData({
    required this.statement,
    required this.partyTotals,
    this.grandTotal,
  });

  factory CustomerWiseSalesReturnReportData.fromJson(Map<String, dynamic> json) {
    final statementList = json['statement'] as List? ?? json['invoiceDetails'] as List? ?? [];
    final totalsList = json['partyTotals'] as List? ?? [];

    return CustomerWiseSalesReturnReportData(
      statement: statementList
          .map((e) => CustomerWiseSalesReturnStatement.fromJson(e as Map<String, dynamic>))
          .toList(),
      partyTotals: totalsList
          .map((e) => CustomerWiseSalesReturnPartyTotal.fromJson(e as Map<String, dynamic>))
          .toList(),
      grandTotal: json['grandTotal'] != null
          ? CustomerWiseSalesReturnGrandTotal.fromJson(json['grandTotal'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CustomerWiseSalesReturnReportResponse {
  final bool status;
  final String message;
  final CustomerWiseSalesReturnReportData? data;
  final String? error;

  CustomerWiseSalesReturnReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory CustomerWiseSalesReturnReportResponse.fromJson(Map<String, dynamic> json) {
    return CustomerWiseSalesReturnReportResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] != null
          ? CustomerWiseSalesReturnReportData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}
