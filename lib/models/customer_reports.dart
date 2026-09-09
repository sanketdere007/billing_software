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

class CustomerListReportItem {
  final int custId;
  final String custCode;
  final String custName;
  final String custCompanyName;
  final String custMobileNo;
  final String custAlternateMobileNo;
  final String custEmail;
  final String custGSTNo;
  final String custPANNo;
  final String custAddress;
  final int custAreaId;
  final int custCityId;
  final int custStateId;
  final String custPincode;
  final String custCountry;
  final int custBranchId;
  final int custCompId;
  final int custRouteId;
  final int custCowCount;
  final int custBuffaloCount;
  final int custBullCount;
  final int custGoatCount;
  final bool custIsActive;
  final String custAreaName;
  final String custCityName;
  final String custStateName;
  final String routeName;
  final String branchName;
  final String compName;

  CustomerListReportItem({
    required this.custId,
    required this.custCode,
    required this.custName,
    required this.custCompanyName,
    required this.custMobileNo,
    required this.custAlternateMobileNo,
    required this.custEmail,
    required this.custGSTNo,
    required this.custPANNo,
    required this.custAddress,
    required this.custAreaId,
    required this.custCityId,
    required this.custStateId,
    required this.custPincode,
    required this.custCountry,
    required this.custBranchId,
    required this.custCompId,
    required this.custRouteId,
    required this.custCowCount,
    required this.custBuffaloCount,
    required this.custBullCount,
    required this.custGoatCount,
    required this.custIsActive,
    required this.custAreaName,
    required this.custCityName,
    required this.custStateName,
    required this.routeName,
    required this.branchName,
    required this.compName,
  });

  factory CustomerListReportItem.fromJson(Map<String, dynamic> json) {
    return CustomerListReportItem(
      custId: json['cust_Id'] ?? 0,
      custCode: json['cust_Code'] ?? '',
      custName: json['cust_Name'] ?? '',
      custCompanyName: json['cust_CompanyName'] ?? '',
      custMobileNo: json['cust_MobileNo'] ?? '',
      custAlternateMobileNo: json['cust_AlternateMobileNo'] ?? '',
      custEmail: json['cust_Email'] ?? '',
      custGSTNo: json['cust_GSTNo'] ?? '',
      custPANNo: json['cust_PANNo'] ?? '',
      custAddress: json['cust_Address'] ?? '',
      custAreaId: json['cust_AreaId'] ?? 0,
      custCityId: json['cust_CityId'] ?? 0,
      custStateId: json['cust_StateId'] ?? 0,
      custPincode: json['cust_Pincode'] ?? '',
      custCountry: json['cust_Country'] ?? '',
      custBranchId: json['cust_BranchId'] ?? 0,
      custCompId: json['cust_CompId'] ?? 0,
      custRouteId: json['cust_RouteId'] ?? 0,
      custCowCount: json['cust_CowCount'] ?? 0,
      custBuffaloCount: json['cust_BuffaloCount'] ?? 0,
      custBullCount: json['cust_BullCount'] ?? 0,
      custGoatCount: json['cust_GoatCount'] ?? 0,
      custIsActive: json['cust_IsActive'] ?? false,
      custAreaName: json['cust_AreaName'] ?? '',
      custCityName: json['cust_CityName'] ?? '',
      custStateName: json['cust_StateName'] ?? '',
      routeName: json['route_Name'] ?? '',
      branchName: json['branch_Name'] ?? '',
      compName: json['comp_Name'] ?? '',
    );
  }
}

class CustomerListReportResponse {
  final bool status;
  final String message;
  final List<CustomerListReportItem> data;
  final String? error;

  CustomerListReportResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory CustomerListReportResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return CustomerListReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: dataList.map((e) => CustomerListReportItem.fromJson(e)).toList(),
      error: json['error'],
    );
  }
}
