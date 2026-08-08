/// Model representing Company records from `/api/Company/GetAllCompanies`
class CompanyListItem {
  final int compId;
  final String compName;
  final String compContactPerson;
  final String compMobileNo;
  final String compAlternateMobileNo;
  final String compEmail;
  final String compWebsite;
  final String compGSTNo;
  final String compPANNo;
  final String compAddress;
  final String compArea;
  final String compCity;
  final String compState;
  final String compPincode;
  final String compCountry;
  final String compLogo;
  final bool compIsActive;
  final int compCreatedBy;
  final String? compCreatedDate;
  final int compModifiedBy;
  final String? compModifiedDate;

  // Additional optional fields for backwards compatibility with legacy UI
  final String? code;
  final String? financialYear;
  final String? currency;

  CompanyListItem({
    required this.compId,
    required this.compName,
    this.compContactPerson = '',
    this.compMobileNo = '',
    this.compAlternateMobileNo = '',
    this.compEmail = '',
    this.compWebsite = '',
    this.compGSTNo = '',
    this.compPANNo = '',
    this.compAddress = '',
    this.compArea = '',
    this.compCity = '',
    this.compState = '',
    this.compPincode = '',
    this.compCountry = 'India',
    this.compLogo = '',
    this.compIsActive = true,
    this.compCreatedBy = 0,
    this.compCreatedDate,
    this.compModifiedBy = 0,
    this.compModifiedDate,
    this.code,
    this.financialYear,
    this.currency,
  });

  // Legacy field getters for compatibility with existing views
  String get id => compId.toString();
  String get name => compName;
  String? get gstNumber => compGSTNo.isNotEmpty ? compGSTNo : null;
  String? get panNumber => compPANNo.isNotEmpty ? compPANNo : null;
  String? get email => compEmail.isNotEmpty ? compEmail : null;
  String? get mobileNumber => compMobileNo.isNotEmpty ? compMobileNo : null;
  String? get website => compWebsite.isNotEmpty ? compWebsite : null;
  String? get address => compAddress.isNotEmpty ? compAddress : null;
  String? get city => compCity.isNotEmpty ? compCity : null;
  String? get state => compState.isNotEmpty ? compState : null;
  String? get pincode => compPincode.isNotEmpty ? compPincode : null;
  String? get companyLogo => compLogo.isNotEmpty ? compLogo : null;
  bool get isActive => compIsActive;

  /// Factory constructor to parse JSON response from `/api/Company/GetAllCompanies`
  factory CompanyListItem.fromJson(Map<String, dynamic> json) {
    int parsedCompId = 0;
    if (json['comp_Id'] != null) {
      parsedCompId = int.tryParse(json['comp_Id'].toString()) ?? 0;
    } else if (json['compId'] != null) {
      parsedCompId = int.tryParse(json['compId'].toString()) ?? 0;
    } else if (json['Comp_Id'] != null) {
      parsedCompId = int.tryParse(json['Comp_Id'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedCompId = int.tryParse(json['id'].toString()) ?? 0;
    }

    bool parsedIsActive = true;
    final rawActive = json['comp_IsActive'] ?? json['compIsActive'] ?? json['Comp_IsActive'] ?? json['isActive'];
    if (rawActive != null) {
      if (rawActive is bool) {
        parsedIsActive = rawActive;
      } else if (rawActive is num) {
        parsedIsActive = rawActive == 1;
      } else if (rawActive is String) {
        parsedIsActive = rawActive.toLowerCase() == 'true' || rawActive == '1';
      }
    }

    int parsedCreatedBy = 0;
    if (json['comp_CreatedBy'] != null) {
      parsedCreatedBy = int.tryParse(json['comp_CreatedBy'].toString()) ?? 0;
    }

    int parsedModifiedBy = 0;
    if (json['comp_ModifiedBy'] != null) {
      parsedModifiedBy = int.tryParse(json['comp_ModifiedBy'].toString()) ?? 0;
    }

    return CompanyListItem(
      compId: parsedCompId,
      compName: (json['comp_Name'] ?? json['compName'] ?? json['Comp_Name'] ?? json['name'] ?? '').toString().trim(),
      compContactPerson: (json['comp_ContactPerson'] ?? json['compContactPerson'] ?? json['Comp_ContactPerson'] ?? '').toString().trim(),
      compMobileNo: (json['comp_MobileNo'] ?? json['compMobileNo'] ?? json['Comp_MobileNo'] ?? json['mobileNumber'] ?? '').toString().trim(),
      compAlternateMobileNo: (json['comp_AlternateMobileNo'] ?? json['compAlternateMobileNo'] ?? json['Comp_AlternateMobileNo'] ?? '').toString().trim(),
      compEmail: (json['comp_Email'] ?? json['compEmail'] ?? json['Comp_Email'] ?? json['email'] ?? '').toString().trim(),
      compWebsite: (json['comp_Website'] ?? json['compWebsite'] ?? json['Comp_Website'] ?? json['website'] ?? '').toString().trim(),
      compGSTNo: (json['comp_GSTNo'] ?? json['compGSTNo'] ?? json['Comp_GSTNo'] ?? json['gstNumber'] ?? '').toString().trim(),
      compPANNo: (json['comp_PANNo'] ?? json['compPANNo'] ?? json['Comp_PANNo'] ?? json['panNumber'] ?? '').toString().trim(),
      compAddress: (json['comp_Address'] ?? json['compAddress'] ?? json['Comp_Address'] ?? json['address'] ?? '').toString().trim(),
      compArea: (json['comp_Area'] ?? json['compArea'] ?? json['Comp_Area'] ?? '').toString().trim(),
      compCity: (json['comp_City'] ?? json['compCity'] ?? json['Comp_City'] ?? json['city'] ?? '').toString().trim(),
      compState: (json['comp_State'] ?? json['compState'] ?? json['Comp_State'] ?? json['state'] ?? '').toString().trim(),
      compPincode: (json['comp_Pincode'] ?? json['compPincode'] ?? json['Comp_Pincode'] ?? json['pincode'] ?? '').toString().trim(),
      compCountry: (json['comp_Country'] ?? json['compCountry'] ?? json['Comp_Country'] ?? json['country'] ?? 'India').toString().trim(),
      compLogo: (json['comp_Logo'] ?? json['compLogo'] ?? json['Comp_Logo'] ?? json['companyLogo'] ?? '').toString().trim(),
      compIsActive: parsedIsActive,
      compCreatedBy: parsedCreatedBy,
      compCreatedDate: json['comp_CreatedDate']?.toString(),
      compModifiedBy: parsedModifiedBy,
      compModifiedDate: json['comp_ModifiedDate']?.toString(),
      code: json['code']?.toString(),
      financialYear: json['financialYear']?.toString(),
      currency: json['currency']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comp_Id': compId,
      'comp_Name': compName,
      'comp_ContactPerson': compContactPerson,
      'comp_MobileNo': compMobileNo,
      'comp_AlternateMobileNo': compAlternateMobileNo,
      'comp_Email': compEmail,
      'comp_Website': compWebsite,
      'comp_GSTNo': compGSTNo,
      'comp_PANNo': compPANNo,
      'comp_Address': compAddress,
      'comp_Area': compArea,
      'comp_City': compCity,
      'comp_State': compState,
      'comp_Pincode': compPincode,
      'comp_Country': compCountry,
      'comp_Logo': compLogo,
      'comp_IsActive': compIsActive,
      'comp_CreatedBy': compCreatedBy,
      'comp_CreatedDate': compCreatedDate,
      'comp_ModifiedBy': compModifiedBy,
      'comp_ModifiedDate': compModifiedDate,
    };
  }

  CompanyListItem copyWith({
    int? compId,
    String? compName,
    String? compContactPerson,
    String? compMobileNo,
    String? compAlternateMobileNo,
    String? compEmail,
    String? compWebsite,
    String? compGSTNo,
    String? compPANNo,
    String? compAddress,
    String? compArea,
    String? compCity,
    String? compState,
    String? compPincode,
    String? compCountry,
    String? compLogo,
    bool? compIsActive,
    int? compCreatedBy,
    String? compCreatedDate,
    int? compModifiedBy,
    String? compModifiedDate,
    String? code,
    String? financialYear,
    String? currency,
  }) {
    return CompanyListItem(
      compId: compId ?? this.compId,
      compName: compName ?? this.compName,
      compContactPerson: compContactPerson ?? this.compContactPerson,
      compMobileNo: compMobileNo ?? this.compMobileNo,
      compAlternateMobileNo: compAlternateMobileNo ?? this.compAlternateMobileNo,
      compEmail: compEmail ?? this.compEmail,
      compWebsite: compWebsite ?? this.compWebsite,
      compGSTNo: compGSTNo ?? this.compGSTNo,
      compPANNo: compPANNo ?? this.compPANNo,
      compAddress: compAddress ?? this.compAddress,
      compArea: compArea ?? this.compArea,
      compCity: compCity ?? this.compCity,
      compState: compState ?? this.compState,
      compPincode: compPincode ?? this.compPincode,
      compCountry: compCountry ?? this.compCountry,
      compLogo: compLogo ?? this.compLogo,
      compIsActive: compIsActive ?? this.compIsActive,
      compCreatedBy: compCreatedBy ?? this.compCreatedBy,
      compCreatedDate: compCreatedDate ?? this.compCreatedDate,
      compModifiedBy: compModifiedBy ?? this.compModifiedBy,
      compModifiedDate: compModifiedDate ?? this.compModifiedDate,
      code: code ?? this.code,
      financialYear: financialYear ?? this.financialYear,
      currency: currency ?? this.currency,
    );
  }
}

/// Response wrapper for `/api/Company/GetAllCompanies`
class CompanyListResponse {
  final bool status;
  final String message;
  final List<CompanyListItem> data;
  final String? error;

  CompanyListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory CompanyListResponse.fromJson(Map<String, dynamic> json) {
    List<CompanyListItem> items = [];
    if (json['data'] != null && json['data'] is List) {
      items = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => CompanyListItem.fromJson(e))
          .toList();
    }

    return CompanyListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: items,
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'error': error,
    };
  }
}

/// Compatibility class for existing screens
class Company extends CompanyListItem {
  Company({
    required String id,
    required String name,
    String? code,
    String? gstNumber,
    String? panNumber,
    String? email,
    String? mobileNumber,
    String? website,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? companyLogo,
    String? financialYear,
    String? currency,
    bool isActive = true,
  }) : super(
          compId: int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          compName: name,
          code: code,
          compGSTNo: gstNumber ?? '',
          compPANNo: panNumber ?? '',
          compEmail: email ?? '',
          compMobileNo: mobileNumber ?? '',
          compWebsite: website ?? '',
          compAddress: address ?? '',
          compCity: city ?? '',
          compState: state ?? '',
          compPincode: pincode ?? '',
          compLogo: companyLogo ?? '',
          financialYear: financialYear,
          currency: currency,
          compIsActive: isActive,
        );

  factory Company.fromListItem(CompanyListItem item) {
    return Company(
      id: item.compId.toString(),
      name: item.compName,
      code: item.code,
      gstNumber: item.compGSTNo,
      panNumber: item.compPANNo,
      email: item.compEmail,
      mobileNumber: item.compMobileNo,
      website: item.compWebsite,
      address: item.compAddress,
      city: item.compCity,
      state: item.compState,
      pincode: item.compPincode,
      companyLogo: item.compLogo,
      financialYear: item.financialYear,
      currency: item.currency,
      isActive: item.compIsActive,
    );
  }
}
