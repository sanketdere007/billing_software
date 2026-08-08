/// Model representing Branch records from `/api/Branch/GetAllBranches`
class BranchListItem {
  final int branchId;
  final int branchCompId;
  final String branchCompName;
  final String branchName;
  final String branchContactPerson;
  final String branchMobileNo;
  final String branchAlternateMobileNo;
  final String branchEmail;
  final String branchGSTNo;
  final String branchAddress;
  final String branchArea;
  final String branchCity;
  final String branchState;
  final String branchPincode;
  final String branchCountry;
  final bool branchIsActive;
  final int branchCreatedBy;
  final String? branchCreatedDate;
  final int branchModifiedBy;
  final String? branchModifiedDate;

  // Additional optional field for legacy compatibility
  final String? code;

  BranchListItem({
    required this.branchId,
    required this.branchCompId,
    this.branchCompName = '',
    required this.branchName,
    this.branchContactPerson = '',
    this.branchMobileNo = '',
    this.branchAlternateMobileNo = '',
    this.branchEmail = '',
    this.branchGSTNo = '',
    this.branchAddress = '',
    this.branchArea = '',
    this.branchCity = '',
    this.branchState = '',
    this.branchPincode = '',
    this.branchCountry = 'India',
    this.branchIsActive = true,
    this.branchCreatedBy = 0,
    this.branchCreatedDate,
    this.branchModifiedBy = 0,
    this.branchModifiedDate,
    this.code,
  });

  // Legacy field getters for backwards compatibility
  String get id => branchId.toString();
  String get name => branchName;
  String get companyId => branchCompId.toString();
  String? get gstNumber => branchGSTNo.isNotEmpty ? branchGSTNo : null;
  String? get contactPerson => branchContactPerson.isNotEmpty ? branchContactPerson : null;
  String? get mobileNumber => branchMobileNo.isNotEmpty ? branchMobileNo : null;
  String? get email => branchEmail.isNotEmpty ? branchEmail : null;
  String? get address => branchAddress.isNotEmpty ? branchAddress : null;
  String? get city => branchCity.isNotEmpty ? branchCity : null;
  String? get state => branchState.isNotEmpty ? branchState : null;
  String? get pincode => branchPincode.isNotEmpty ? branchPincode : null;
  bool get isActive => branchIsActive;

  /// Factory constructor to parse JSON response from `/api/Branch/GetAllBranches`
  factory BranchListItem.fromJson(Map<String, dynamic> json) {
    int parsedBranchId = 0;
    if (json['branch_Id'] != null) {
      parsedBranchId = int.tryParse(json['branch_Id'].toString()) ?? 0;
    } else if (json['branchId'] != null) {
      parsedBranchId = int.tryParse(json['branchId'].toString()) ?? 0;
    } else if (json['Branch_Id'] != null) {
      parsedBranchId = int.tryParse(json['Branch_Id'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedBranchId = int.tryParse(json['id'].toString()) ?? 0;
    }

    int parsedCompId = 0;
    if (json['branch_CompId'] != null) {
      parsedCompId = int.tryParse(json['branch_CompId'].toString()) ?? 0;
    } else if (json['branchCompId'] != null) {
      parsedCompId = int.tryParse(json['branchCompId'].toString()) ?? 0;
    } else if (json['Branch_CompId'] != null) {
      parsedCompId = int.tryParse(json['Branch_CompId'].toString()) ?? 0;
    } else if (json['compId'] != null) {
      parsedCompId = int.tryParse(json['compId'].toString()) ?? 0;
    } else if (json['companyId'] != null) {
      parsedCompId = int.tryParse(json['companyId'].toString()) ?? 0;
    }

    bool parsedIsActive = true;
    final rawActive = json['branch_IsActive'] ?? json['branchIsActive'] ?? json['Branch_IsActive'] ?? json['isActive'];
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
    if (json['branch_CreatedBy'] != null) {
      parsedCreatedBy = int.tryParse(json['branch_CreatedBy'].toString()) ?? 0;
    }

    int parsedModifiedBy = 0;
    if (json['branch_ModifiedBy'] != null) {
      parsedModifiedBy = int.tryParse(json['branch_ModifiedBy'].toString()) ?? 0;
    }

    return BranchListItem(
      branchId: parsedBranchId,
      branchCompId: parsedCompId,
      branchCompName: (json['branch_CompName'] ?? json['branchCompName'] ?? json['Branch_CompName'] ?? '').toString().trim(),
      branchName: (json['branch_Name'] ?? json['branchName'] ?? json['Branch_Name'] ?? json['name'] ?? '').toString().trim(),
      branchContactPerson: (json['branch_ContactPerson'] ?? json['branchContactPerson'] ?? json['Branch_ContactPerson'] ?? json['contactPerson'] ?? '').toString().trim(),
      branchMobileNo: (json['branch_MobileNo'] ?? json['branchMobileNo'] ?? json['Branch_MobileNo'] ?? json['mobileNumber'] ?? '').toString().trim(),
      branchAlternateMobileNo: (json['branch_AlternateMobileNo'] ?? json['branchAlternateMobileNo'] ?? json['Branch_AlternateMobileNo'] ?? '').toString().trim(),
      branchEmail: (json['branch_Email'] ?? json['branchEmail'] ?? json['Branch_Email'] ?? json['email'] ?? '').toString().trim(),
      branchGSTNo: (json['branch_GSTNo'] ?? json['branchGSTNo'] ?? json['Branch_GSTNo'] ?? json['gstNumber'] ?? '').toString().trim(),
      branchAddress: (json['branch_Address'] ?? json['branchAddress'] ?? json['Branch_Address'] ?? json['address'] ?? '').toString().trim(),
      branchArea: (json['branch_Area'] ?? json['branchArea'] ?? json['Branch_Area'] ?? '').toString().trim(),
      branchCity: (json['branch_City'] ?? json['branchCity'] ?? json['Branch_City'] ?? json['city'] ?? '').toString().trim(),
      branchState: (json['branch_State'] ?? json['branchState'] ?? json['Branch_State'] ?? json['state'] ?? '').toString().trim(),
      branchPincode: (json['branch_Pincode'] ?? json['branchPincode'] ?? json['Branch_Pincode'] ?? json['pincode'] ?? '').toString().trim(),
      branchCountry: (json['branch_Country'] ?? json['branchCountry'] ?? json['Branch_Country'] ?? json['country'] ?? 'India').toString().trim(),
      branchIsActive: parsedIsActive,
      branchCreatedBy: parsedCreatedBy,
      branchCreatedDate: json['branch_CreatedDate']?.toString(),
      branchModifiedBy: parsedModifiedBy,
      branchModifiedDate: json['branch_ModifiedDate']?.toString(),
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branch_Id': branchId,
      'branch_CompId': branchCompId,
      'branch_CompName': branchCompName,
      'branch_Name': branchName,
      'branch_ContactPerson': branchContactPerson,
      'branch_MobileNo': branchMobileNo,
      'branch_AlternateMobileNo': branchAlternateMobileNo,
      'branch_Email': branchEmail,
      'branch_GSTNo': branchGSTNo,
      'branch_Address': branchAddress,
      'branch_Area': branchArea,
      'branch_City': branchCity,
      'branch_State': branchState,
      'branch_Pincode': branchPincode,
      'branch_Country': branchCountry,
      'branch_IsActive': branchIsActive,
      'branch_CreatedBy': branchCreatedBy,
      'branch_CreatedDate': branchCreatedDate,
      'branch_ModifiedBy': branchModifiedBy,
      'branch_ModifiedDate': branchModifiedDate,
    };
  }

  BranchListItem copyWith({
    int? branchId,
    int? branchCompId,
    String? branchCompName,
    String? branchName,
    String? branchContactPerson,
    String? branchMobileNo,
    String? branchAlternateMobileNo,
    String? branchEmail,
    String? branchGSTNo,
    String? branchAddress,
    String? branchArea,
    String? branchCity,
    String? branchState,
    String? branchPincode,
    String? branchCountry,
    bool? branchIsActive,
    int? branchCreatedBy,
    String? branchCreatedDate,
    int? branchModifiedBy,
    String? branchModifiedDate,
    String? code,
  }) {
    return BranchListItem(
      branchId: branchId ?? this.branchId,
      branchCompId: branchCompId ?? this.branchCompId,
      branchCompName: branchCompName ?? this.branchCompName,
      branchName: branchName ?? this.branchName,
      branchContactPerson: branchContactPerson ?? this.branchContactPerson,
      branchMobileNo: branchMobileNo ?? this.branchMobileNo,
      branchAlternateMobileNo: branchAlternateMobileNo ?? this.branchAlternateMobileNo,
      branchEmail: branchEmail ?? this.branchEmail,
      branchGSTNo: branchGSTNo ?? this.branchGSTNo,
      branchAddress: branchAddress ?? this.branchAddress,
      branchArea: branchArea ?? this.branchArea,
      branchCity: branchCity ?? this.branchCity,
      branchState: branchState ?? this.branchState,
      branchPincode: branchPincode ?? this.branchPincode,
      branchCountry: branchCountry ?? this.branchCountry,
      branchIsActive: branchIsActive ?? this.branchIsActive,
      branchCreatedBy: branchCreatedBy ?? this.branchCreatedBy,
      branchCreatedDate: branchCreatedDate ?? this.branchCreatedDate,
      branchModifiedBy: branchModifiedBy ?? this.branchModifiedBy,
      branchModifiedDate: branchModifiedDate ?? this.branchModifiedDate,
      code: code ?? this.code,
    );
  }
}

/// Response wrapper for `/api/Branch/GetAllBranches`
class BranchListResponse {
  final bool status;
  final String message;
  final List<BranchListItem> data;
  final String? error;

  BranchListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory BranchListResponse.fromJson(Map<String, dynamic> json) {
    List<BranchListItem> items = [];
    if (json['data'] != null && json['data'] is List) {
      items = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => BranchListItem.fromJson(e))
          .toList();
    }

    return BranchListResponse(
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
class Branch extends BranchListItem {
  Branch({
    required String id,
    required String name,
    String? code,
    required String companyId,
    String? gstNumber,
    String? contactPerson,
    String? mobileNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    bool isActive = true,
  }) : super(
          branchId: int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          branchCompId: int.tryParse(companyId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          branchName: name,
          code: code,
          branchGSTNo: gstNumber ?? '',
          branchContactPerson: contactPerson ?? '',
          branchMobileNo: mobileNumber ?? '',
          branchEmail: email ?? '',
          branchAddress: address ?? '',
          branchCity: city ?? '',
          branchState: state ?? '',
          branchPincode: pincode ?? '',
          branchIsActive: isActive,
        );

  factory Branch.fromListItem(BranchListItem item) {
    return Branch(
      id: item.branchId.toString(),
      name: item.branchName,
      code: item.code,
      companyId: item.branchCompId.toString(),
      gstNumber: item.branchGSTNo,
      contactPerson: item.branchContactPerson,
      mobileNumber: item.branchMobileNo,
      email: item.branchEmail,
      address: item.branchAddress,
      city: item.branchCity,
      state: item.branchState,
      pincode: item.branchPincode,
      isActive: item.branchIsActive,
    );
  }
}
