class SupplierListItem {
  final int suppId;
  final String suppCode;
  final String suppName;
  final String suppCompanyName;
  final String suppMobileNo;
  final String suppAlternateMobileNo;
  final String suppEmail;
  final String suppGSTNo;
  final String suppPANNo;
  final String suppAddress;
  final int suppAreaId;
  final int suppCityId;
  final int suppStateId;
  final String suppPincode;
  final String suppCountry;
  final String suppPaymentTerms;
  final double suppCreditLimit;
  final int suppCreditDays;
  final bool suppIsActive;
  final int suppCreatedBy;
  final DateTime? suppCreatedDate;
  final int suppModifiedBy;
  final DateTime? suppModifiedDate;
  final int suppCompId;
  final int suppBranchId;
  final int suppLedgerId;
  
  final String? suppAreaName;
  final String? suppCityName;
  final String? suppStateName;
  final String? suppCompanyDisplayName;
  final String? suppBranchName;

  SupplierListItem({
    required this.suppId,
    required this.suppCode,
    required this.suppName,
    required this.suppCompanyName,
    required this.suppMobileNo,
    required this.suppAlternateMobileNo,
    required this.suppEmail,
    required this.suppGSTNo,
    required this.suppPANNo,
    required this.suppAddress,
    required this.suppAreaId,
    required this.suppCityId,
    required this.suppStateId,
    required this.suppPincode,
    required this.suppCountry,
    required this.suppPaymentTerms,
    required this.suppCreditLimit,
    required this.suppCreditDays,
    required this.suppIsActive,
    required this.suppCreatedBy,
    this.suppCreatedDate,
    required this.suppModifiedBy,
    this.suppModifiedDate,
    required this.suppCompId,
    required this.suppBranchId,
    this.suppLedgerId = 0,
    this.suppAreaName,
    this.suppCityName,
    this.suppStateName,
    this.suppCompanyDisplayName,
    this.suppBranchName,
  });

  factory SupplierListItem.fromJson(Map<String, dynamic> json) {
    return SupplierListItem(
      suppId: json['supp_Id'] ?? 0,
      suppCode: json['supp_Code'] ?? '',
      suppName: json['supp_Name'] ?? '',
      suppCompanyName: json['supp_CompanyName'] ?? '',
      suppMobileNo: json['supp_MobileNo'] ?? '',
      suppAlternateMobileNo: json['supp_AlternateMobileNo'] ?? '',
      suppEmail: json['supp_Email'] ?? '',
      suppGSTNo: json['supp_GSTNo'] ?? '',
      suppPANNo: json['supp_PANNo'] ?? '',
      suppAddress: json['supp_Address'] ?? '',
      suppAreaId: json['supp_AreaId'] ?? 0,
      suppCityId: json['supp_CityId'] ?? 0,
      suppStateId: json['supp_StateId'] ?? 0,
      suppPincode: json['supp_Pincode'] ?? '',
      suppCountry: json['supp_Country'] ?? '',
      suppPaymentTerms: json['supp_PaymentTerms'] ?? '',
      suppCreditLimit: (json['supp_CreditLimit'] ?? 0).toDouble(),
      suppCreditDays: json['supp_CreditDays'] ?? 0,
      suppIsActive: json['supp_IsActive'] ?? true,
      suppCreatedBy: json['supp_CreatedBy'] ?? 0,
      suppCreatedDate: json['supp_CreatedDate'] != null
          ? DateTime.tryParse(json['supp_CreatedDate'])
          : null,
      suppModifiedBy: json['supp_ModifiedBy'] ?? 0,
      suppModifiedDate: json['supp_ModifiedDate'] != null
          ? DateTime.tryParse(json['supp_ModifiedDate'])
          : null,
      suppCompId: json['supp_CompId'] ?? 0,
      suppBranchId: json['supp_BranchId'] ?? 0,
      suppLedgerId: int.tryParse((json['Supp_LeadgerId'] ?? json['supp_LeadgerId'] ?? json['suppLeadgerId'] ?? json['Supp_LedgerId'] ?? json['supp_LedgerId'] ?? json['suppLedgerId'] ?? '0').toString()) ?? 0,
      suppAreaName: json['supp_AreaName'],
      suppCityName: json['supp_CityName'],
      suppStateName: json['supp_StateName'],
      suppCompanyDisplayName: json['supp_CompanyDisplayName'],
      suppBranchName: json['supp_BranchName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supp_Id': suppId,
      'supp_Code': suppCode,
      'supp_Name': suppName,
      'supp_CompanyName': suppCompanyName,
      'supp_MobileNo': suppMobileNo,
      'supp_AlternateMobileNo': suppAlternateMobileNo,
      'supp_Email': suppEmail,
      'supp_GSTNo': suppGSTNo,
      'supp_PANNo': suppPANNo,
      'supp_Address': suppAddress,
      'supp_AreaId': suppAreaId,
      'supp_CityId': suppCityId,
      'supp_StateId': suppStateId,
      'supp_Pincode': suppPincode,
      'supp_Country': suppCountry,
      'supp_PaymentTerms': suppPaymentTerms,
      'supp_CreditLimit': suppCreditLimit,
      'supp_CreditDays': suppCreditDays,
      'supp_IsActive': suppIsActive,
      'supp_CreatedBy': suppCreatedBy,
      'supp_CreatedDate': suppCreatedDate?.toIso8601String(),
      'supp_ModifiedBy': suppModifiedBy,
      'supp_ModifiedDate': suppModifiedDate?.toIso8601String(),
      'supp_CompId': suppCompId,
      'supp_BranchId': suppBranchId,
      'Supp_LeadgerId': suppLedgerId,
      'supp_AreaName': suppAreaName,
      'supp_CityName': suppCityName,
      'supp_StateName': suppStateName,
      'supp_CompanyDisplayName': suppCompanyDisplayName,
      'supp_BranchName': suppBranchName,
    };
  }
}

class SupplierListResponse {
  final bool status;
  final String message;
  final List<SupplierListItem> data;
  final String? error;

  SupplierListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory SupplierListResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return SupplierListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: dataList.map((e) => SupplierListItem.fromJson(e)).toList(),
      error: json['error'],
    );
  }
}

class SupplierUpsertRequest {
  final int suppId;
  final String suppCode;
  final String suppName;
  final String suppCompanyName;
  final String suppMobileNo;
  final String suppAlternateMobileNo;
  final String suppEmail;
  final String suppGSTNo;
  final String suppPANNo;
  final String suppAddress;
  final int suppAreaId;
  final int suppCityId;
  final int suppStateId;
  final String suppPincode;
  final String suppCountry;
  final String suppPaymentTerms;
  final double suppCreditLimit;
  final int suppCreditDays;
  final bool suppIsActive;
  final int suppCreatedBy;
  final int suppModifiedBy;
  final int suppCompId;
  final int suppBranchId;

  SupplierUpsertRequest({
    required this.suppId,
    required this.suppCode,
    required this.suppName,
    required this.suppCompanyName,
    required this.suppMobileNo,
    required this.suppAlternateMobileNo,
    required this.suppEmail,
    required this.suppGSTNo,
    required this.suppPANNo,
    required this.suppAddress,
    required this.suppAreaId,
    required this.suppCityId,
    required this.suppStateId,
    required this.suppPincode,
    required this.suppCountry,
    required this.suppPaymentTerms,
    required this.suppCreditLimit,
    required this.suppCreditDays,
    required this.suppIsActive,
    required this.suppCreatedBy,
    required this.suppModifiedBy,
    required this.suppCompId,
    required this.suppBranchId,
  });

  Map<String, dynamic> toJson() {
    return {
      'supp_Id': suppId,
      'supp_Code': suppCode,
      'supp_Name': suppName,
      'supp_CompanyName': suppCompanyName,
      'supp_MobileNo': suppMobileNo,
      'supp_AlternateMobileNo': suppAlternateMobileNo,
      'supp_Email': suppEmail,
      'supp_GSTNo': suppGSTNo,
      'supp_PANNo': suppPANNo,
      'supp_Address': suppAddress,
      'supp_AreaId': suppAreaId,
      'supp_CityId': suppCityId,
      'supp_StateId': suppStateId,
      'supp_Pincode': suppPincode,
      'supp_Country': suppCountry,
      'supp_PaymentTerms': suppPaymentTerms,
      'supp_CreditLimit': suppCreditLimit,
      'supp_CreditDays': suppCreditDays,
      'supp_IsActive': suppIsActive,
      'supp_CreatedBy': suppCreatedBy,
      'supp_ModifiedBy': suppModifiedBy,
      'supp_CompId': suppCompId,
      'supp_BranchId': suppBranchId,
    };
  }
}

class SupplierUpsertResponseData {
  final bool status;
  final String message;
  final int suppId;

  SupplierUpsertResponseData({
    required this.status,
    required this.message,
    required this.suppId,
  });

  factory SupplierUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return SupplierUpsertResponseData(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      suppId: json['supp_Id'] ?? 0,
    );
  }
}

class SupplierUpsertResponse {
  final bool status;
  final String message;
  final SupplierUpsertResponseData? data;
  final String? error;

  SupplierUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory SupplierUpsertResponse.fromJson(Map<String, dynamic> json) {
    return SupplierUpsertResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SupplierUpsertResponseData.fromJson(json['data'])
          : null,
      error: json['error'],
    );
  }
}
