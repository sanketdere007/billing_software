class OutstandingReceivableInvoiceDetail {
  final int custId;
  final String custCode;
  final String custName;
  final String custMobileNo;
  final int custStateId;
  final String stateName;
  final int custCityId;
  final String cityName;
  final int custAreaId;
  final String areaName;
  final int custRouteId;
  final String routeName;
  final int salesMasterId;
  final String salesMasterInvoiceNo;
  final DateTime? salesMasterInvoiceDate;
  final double billAmount;
  final double paidAmount;
  final double balanceAmount;
  final int daysOutstanding;
  final String rowType;

  OutstandingReceivableInvoiceDetail({
    required this.custId,
    required this.custCode,
    required this.custName,
    required this.custMobileNo,
    required this.custStateId,
    required this.stateName,
    required this.custCityId,
    required this.cityName,
    required this.custAreaId,
    required this.areaName,
    required this.custRouteId,
    required this.routeName,
    required this.salesMasterId,
    required this.salesMasterInvoiceNo,
    this.salesMasterInvoiceDate,
    required this.billAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.daysOutstanding,
    required this.rowType,
  });

  factory OutstandingReceivableInvoiceDetail.fromJson(Map<String, dynamic> json) {
    return OutstandingReceivableInvoiceDetail(
      custId: json['cust_Id'] ?? 0,
      custCode: json['cust_Code'] ?? '',
      custName: json['cust_Name'] ?? '',
      custMobileNo: json['cust_MobileNo'] ?? '',
      custStateId: json['cust_StateId'] ?? 0,
      stateName: json['state_Name'] ?? '',
      custCityId: json['cust_CityId'] ?? 0,
      cityName: json['city_Name'] ?? '',
      custAreaId: json['cust_AreaId'] ?? 0,
      areaName: json['area_Name'] ?? '',
      custRouteId: json['cust_RouteId'] ?? 0,
      routeName: json['route_Name'] ?? '',
      salesMasterId: json['salesMaster_Id'] ?? 0,
      salesMasterInvoiceNo: json['salesMaster_InvoiceNo'] ?? '',
      salesMasterInvoiceDate: json['salesMaster_InvoiceDate'] != null 
          ? DateTime.tryParse(json['salesMaster_InvoiceDate'].toString()) 
          : null,
      billAmount: (json['billAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceAmount: (json['balanceAmount'] ?? 0).toDouble(),
      daysOutstanding: json['daysOutstanding'] ?? 0,
      rowType: json['rowType'] ?? '',
    );
  }
}

class OutstandingReceivablePartyTotal {
  final int custId;
  final String custCode;
  final String custName;
  final int totalInvoices;
  final double totalBillAmount;
  final double totalPaidAmount;
  final double totalBalanceAmount;
  final String rowType;

  OutstandingReceivablePartyTotal({
    required this.custId,
    required this.custCode,
    required this.custName,
    required this.totalInvoices,
    required this.totalBillAmount,
    required this.totalPaidAmount,
    required this.totalBalanceAmount,
    required this.rowType,
  });

  factory OutstandingReceivablePartyTotal.fromJson(Map<String, dynamic> json) {
    return OutstandingReceivablePartyTotal(
      custId: json['cust_Id'] ?? 0,
      custCode: json['cust_Code'] ?? '',
      custName: json['cust_Name'] ?? '',
      totalInvoices: json['totalInvoices'] ?? 0,
      totalBillAmount: (json['totalBillAmount'] ?? 0).toDouble(),
      totalPaidAmount: (json['totalPaidAmount'] ?? 0).toDouble(),
      totalBalanceAmount: (json['totalBalanceAmount'] ?? 0).toDouble(),
      rowType: json['rowType'] ?? '',
    );
  }
}

class OutstandingReceivableGrandTotal {
  final int totalInvoices;
  final int totalCustomers;
  final double grandTotalBillAmount;
  final double grandTotalPaidAmount;
  final double grandTotalBalanceAmount;

  OutstandingReceivableGrandTotal({
    required this.totalInvoices,
    required this.totalCustomers,
    required this.grandTotalBillAmount,
    required this.grandTotalPaidAmount,
    required this.grandTotalBalanceAmount,
  });

  factory OutstandingReceivableGrandTotal.fromJson(Map<String, dynamic> json) {
    return OutstandingReceivableGrandTotal(
      totalInvoices: json['totalInvoices'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
      grandTotalBillAmount: (json['grandTotalBillAmount'] ?? 0).toDouble(),
      grandTotalPaidAmount: (json['grandTotalPaidAmount'] ?? 0).toDouble(),
      grandTotalBalanceAmount: (json['grandTotalBalanceAmount'] ?? 0).toDouble(),
    );
  }
}

class OutstandingReceivableReportData {
  final List<OutstandingReceivableInvoiceDetail> invoiceDetails;
  final List<OutstandingReceivablePartyTotal> partyTotals;
  final OutstandingReceivableGrandTotal? grandTotal;

  OutstandingReceivableReportData({
    required this.invoiceDetails,
    required this.partyTotals,
    this.grandTotal,
  });

  factory OutstandingReceivableReportData.fromJson(Map<String, dynamic> json) {
    var invoices = json['invoiceDetails'] as List? ?? [];
    var totals = json['partyTotals'] as List? ?? [];
    
    return OutstandingReceivableReportData(
      invoiceDetails: invoices.map((e) => OutstandingReceivableInvoiceDetail.fromJson(e)).toList(),
      partyTotals: totals.map((e) => OutstandingReceivablePartyTotal.fromJson(e)).toList(),
      grandTotal: json['grandTotal'] != null 
          ? OutstandingReceivableGrandTotal.fromJson(json['grandTotal']) 
          : null,
    );
  }
}

class OutstandingReceivableReportResponse {
  final bool status;
  final String message;
  final OutstandingReceivableReportData? data;
  final String? error;

  OutstandingReceivableReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory OutstandingReceivableReportResponse.fromJson(Map<String, dynamic> json) {
    return OutstandingReceivableReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? OutstandingReceivableReportData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}
