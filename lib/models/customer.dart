/// Customer Model representing data structures for:
/// 1] GET `/api/Customer/GetAllCustomers`
/// 2] GET `/api/Customer/GetCustomerById/{Cust_Id}`
/// 3] POST `/api/Customer/InsertorUpdateCustomer`
class CustomerListItem {
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
  final String custArea;
  final int custCityId;
  final String custCity;
  final int custStateId;
  final String custState;
  final String custPincode;
  final String custCountry;
  final int custBranchId;
  final int custCompId;
  final bool custIsActive;
  final int custCreatedBy;
  final String? custCreatedDate;
  final int custModifiedBy;
  final String? custModifiedDate;

  CustomerListItem({
    required this.custId,
    required this.custCode,
    required this.custName,
    this.custCompanyName = '',
    required this.custMobileNo,
    this.custAlternateMobileNo = '',
    this.custEmail = '',
    this.custGSTNo = '',
    this.custPANNo = '',
    this.custAddress = '',
    this.custAreaId = 0,
    this.custArea = '',
    this.custCityId = 0,
    this.custCity = '',
    this.custStateId = 0,
    this.custState = '',
    this.custPincode = '',
    this.custCountry = 'India',
    this.custBranchId = 0,
    this.custCompId = 0,
    this.custIsActive = true,
    this.custCreatedBy = 0,
    this.custCreatedDate,
    this.custModifiedBy = 0,
    this.custModifiedDate,
  });

  // Backwards compatibility getters
  String get id => custId.toString();
  String get name => custName;
  String get mobile => custMobileNo;
  String? get email => custEmail.isNotEmpty ? custEmail : null;
  String? get gstNumber => custGSTNo.isNotEmpty ? custGSTNo : null;
  String? get address => custAddress.isNotEmpty ? custAddress : null;
  String? get city => custCity.isNotEmpty ? custCity : null;
  String? get state => custState.isNotEmpty ? custState : null;
  String? get pincode => custPincode.isNotEmpty ? custPincode : null;
  bool get isActive => custIsActive;

  /// Helper to get a nicely formatted multi-part address string
  String get fullAddress {
    final parts = [
      if (custAddress.trim().isNotEmpty) custAddress.trim(),
      if (custArea.trim().isNotEmpty) custArea.trim(),
      if (custCity.trim().isNotEmpty) custCity.trim(),
      if (custState.trim().isNotEmpty) custState.trim(),
      if (custPincode.trim().isNotEmpty) custPincode.trim(),
      if (custCountry.trim().isNotEmpty && custCountry.trim() != 'India') custCountry.trim(),
    ];
    return parts.join(', ');
  }

  factory CustomerListItem.fromJson(Map<String, dynamic> json) {
    // Parse Customer ID
    int parsedCustId = 0;
    if (json['cust_Id'] != null) {
      parsedCustId = int.tryParse(json['cust_Id'].toString()) ?? 0;
    } else if (json['custId'] != null) {
      parsedCustId = int.tryParse(json['custId'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedCustId = int.tryParse(json['id'].toString()) ?? 0;
    }

    // Parse Customer Code
    String parsedCustCode = '';
    if (json['cust_Code'] != null) {
      parsedCustCode = json['cust_Code'].toString();
    } else if (json['custCode'] != null) {
      parsedCustCode = json['custCode'].toString();
    } else if (json['code'] != null) {
      parsedCustCode = json['code'].toString();
    }

    // Parse Customer Name
    String parsedCustName = '';
    if (json['cust_Name'] != null) {
      parsedCustName = json['cust_Name'].toString();
    } else if (json['custName'] != null) {
      parsedCustName = json['custName'].toString();
    } else if (json['name'] != null) {
      parsedCustName = json['name'].toString();
    }

    // Parse Company Name
    String parsedCustCompanyName = '';
    if (json['cust_CompanyName'] != null) {
      parsedCustCompanyName = json['cust_CompanyName'].toString();
    } else if (json['custCompanyName'] != null) {
      parsedCustCompanyName = json['custCompanyName'].toString();
    } else if (json['companyName'] != null) {
      parsedCustCompanyName = json['companyName'].toString();
    }

    // Parse Mobile Number
    String parsedCustMobileNo = '';
    if (json['cust_MobileNo'] != null) {
      parsedCustMobileNo = json['cust_MobileNo'].toString();
    } else if (json['custMobileNo'] != null) {
      parsedCustMobileNo = json['custMobileNo'].toString();
    } else if (json['mobile'] != null) {
      parsedCustMobileNo = json['mobile'].toString();
    }

    // Parse Alternate Mobile Number
    String parsedCustAlternateMobileNo = '';
    if (json['cust_AlternateMobileNo'] != null) {
      parsedCustAlternateMobileNo = json['cust_AlternateMobileNo'].toString();
    } else if (json['custAlternateMobileNo'] != null) {
      parsedCustAlternateMobileNo = json['custAlternateMobileNo'].toString();
    } else if (json['alternateMobile'] != null) {
      parsedCustAlternateMobileNo = json['alternateMobile'].toString();
    }

    // Parse Email
    String parsedCustEmail = '';
    if (json['cust_Email'] != null) {
      parsedCustEmail = json['cust_Email'].toString();
    } else if (json['custEmail'] != null) {
      parsedCustEmail = json['custEmail'].toString();
    } else if (json['email'] != null) {
      parsedCustEmail = json['email'].toString();
    }

    // Parse GST No
    String parsedCustGSTNo = '';
    if (json['cust_GSTNo'] != null) {
      parsedCustGSTNo = json['cust_GSTNo'].toString();
    } else if (json['custGSTNo'] != null) {
      parsedCustGSTNo = json['custGSTNo'].toString();
    } else if (json['gstNumber'] != null) {
      parsedCustGSTNo = json['gstNumber'].toString();
    }

    // Parse PAN No
    String parsedCustPANNo = '';
    if (json['cust_PANNo'] != null) {
      parsedCustPANNo = json['cust_PANNo'].toString();
    } else if (json['custPANNo'] != null) {
      parsedCustPANNo = json['custPANNo'].toString();
    } else if (json['panNumber'] != null) {
      parsedCustPANNo = json['panNumber'].toString();
    }

    // Parse Address
    String parsedCustAddress = '';
    if (json['cust_Address'] != null) {
      parsedCustAddress = json['cust_Address'].toString();
    } else if (json['custAddress'] != null) {
      parsedCustAddress = json['custAddress'].toString();
    } else if (json['address'] != null) {
      parsedCustAddress = json['address'].toString();
    }

    // Parse Area ID
    int parsedCustAreaId = 0;
    if (json['cust_Areaid'] != null) {
      parsedCustAreaId = int.tryParse(json['cust_Areaid'].toString()) ?? 0;
    } else if (json['cust_AreaId'] != null) {
      parsedCustAreaId = int.tryParse(json['cust_AreaId'].toString()) ?? 0;
    } else if (json['custAreaId'] != null) {
      parsedCustAreaId = int.tryParse(json['custAreaId'].toString()) ?? 0;
    } else if (json['custAreaid'] != null) {
      parsedCustAreaId = int.tryParse(json['custAreaid'].toString()) ?? 0;
    } else if (json['area_Id'] != null) {
      parsedCustAreaId = int.tryParse(json['area_Id'].toString()) ?? 0;
    } else if (json['areaId'] != null) {
      parsedCustAreaId = int.tryParse(json['areaId'].toString()) ?? 0;
    }

    // Parse Area Name
    String parsedCustArea = '';
    if (json['cust_Area'] != null) {
      parsedCustArea = json['cust_Area'].toString();
    } else if (json['custArea'] != null) {
      parsedCustArea = json['custArea'].toString();
    } else if (json['area_Name'] != null) {
      parsedCustArea = json['area_Name'].toString();
    } else if (json['area'] != null) {
      parsedCustArea = json['area'].toString();
    }

    // Parse City ID
    int parsedCustCityId = 0;
    if (json['cust_Cityid'] != null) {
      parsedCustCityId = int.tryParse(json['cust_Cityid'].toString()) ?? 0;
    } else if (json['cust_CityId'] != null) {
      parsedCustCityId = int.tryParse(json['cust_CityId'].toString()) ?? 0;
    } else if (json['custCityId'] != null) {
      parsedCustCityId = int.tryParse(json['custCityId'].toString()) ?? 0;
    } else if (json['custCityid'] != null) {
      parsedCustCityId = int.tryParse(json['custCityid'].toString()) ?? 0;
    } else if (json['city_Id'] != null) {
      parsedCustCityId = int.tryParse(json['city_Id'].toString()) ?? 0;
    } else if (json['cityId'] != null) {
      parsedCustCityId = int.tryParse(json['cityId'].toString()) ?? 0;
    }

    // Parse City Name
    String parsedCustCity = '';
    if (json['cust_City'] != null) {
      parsedCustCity = json['cust_City'].toString();
    } else if (json['custCity'] != null) {
      parsedCustCity = json['custCity'].toString();
    } else if (json['city_Name'] != null) {
      parsedCustCity = json['city_Name'].toString();
    } else if (json['city'] != null) {
      parsedCustCity = json['city'].toString();
    }

    // Parse State ID
    int parsedCustStateId = 0;
    if (json['cust_Stateid'] != null) {
      parsedCustStateId = int.tryParse(json['cust_Stateid'].toString()) ?? 0;
    } else if (json['cust_StateId'] != null) {
      parsedCustStateId = int.tryParse(json['cust_StateId'].toString()) ?? 0;
    } else if (json['custStateId'] != null) {
      parsedCustStateId = int.tryParse(json['custStateId'].toString()) ?? 0;
    } else if (json['custStateid'] != null) {
      parsedCustStateId = int.tryParse(json['custStateid'].toString()) ?? 0;
    } else if (json['state_Id'] != null) {
      parsedCustStateId = int.tryParse(json['state_Id'].toString()) ?? 0;
    } else if (json['stateId'] != null) {
      parsedCustStateId = int.tryParse(json['stateId'].toString()) ?? 0;
    }

    // Parse State Name
    String parsedCustState = '';
    if (json['cust_State'] != null) {
      parsedCustState = json['cust_State'].toString();
    } else if (json['custState'] != null) {
      parsedCustState = json['custState'].toString();
    } else if (json['state_Name'] != null) {
      parsedCustState = json['state_Name'].toString();
    } else if (json['state'] != null) {
      parsedCustState = json['state'].toString();
    }

    // Parse Pincode
    String parsedCustPincode = '';
    if (json['cust_Pincode'] != null) {
      parsedCustPincode = json['cust_Pincode'].toString();
    } else if (json['custPincode'] != null) {
      parsedCustPincode = json['custPincode'].toString();
    } else if (json['pincode'] != null) {
      parsedCustPincode = json['pincode'].toString();
    }

    // Parse Country
    String parsedCustCountry = 'India';
    if (json['cust_Country'] != null && json['cust_Country'].toString().isNotEmpty) {
      parsedCustCountry = json['cust_Country'].toString();
    } else if (json['custCountry'] != null && json['custCountry'].toString().isNotEmpty) {
      parsedCustCountry = json['custCountry'].toString();
    } else if (json['country'] != null && json['country'].toString().isNotEmpty) {
      parsedCustCountry = json['country'].toString();
    }

    // Parse Branch ID
    int parsedCustBranchId = 0;
    if (json['cust_BranchId'] != null) {
      parsedCustBranchId = int.tryParse(json['cust_BranchId'].toString()) ?? 0;
    } else if (json['custBranchId'] != null) {
      parsedCustBranchId = int.tryParse(json['custBranchId'].toString()) ?? 0;
    } else if (json['branchId'] != null) {
      parsedCustBranchId = int.tryParse(json['branchId'].toString()) ?? 0;
    }

    // Parse Company ID
    int parsedCustCompId = 0;
    if (json['cust_CompId'] != null) {
      parsedCustCompId = int.tryParse(json['cust_CompId'].toString()) ?? 0;
    } else if (json['custCompId'] != null) {
      parsedCustCompId = int.tryParse(json['custCompId'].toString()) ?? 0;
    } else if (json['compId'] != null) {
      parsedCustCompId = int.tryParse(json['compId'].toString()) ?? 0;
    }

    // Parse Active Status
    bool parsedIsActive = true;
    if (json['cust_IsActive'] != null) {
      final val = json['cust_IsActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    } else if (json['custIsActive'] != null) {
      final val = json['custIsActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    } else if (json['isActive'] != null) {
      final val = json['isActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    }

    // Parse Created By
    int parsedCustCreatedBy = 0;
    if (json['cust_CreatedBy'] != null) {
      parsedCustCreatedBy = int.tryParse(json['cust_CreatedBy'].toString()) ?? 0;
    } else if (json['custCreatedBy'] != null) {
      parsedCustCreatedBy = int.tryParse(json['custCreatedBy'].toString()) ?? 0;
    }

    // Parse Created Date
    String? parsedCustCreatedDate;
    if (json['cust_CreatedDate'] != null) {
      parsedCustCreatedDate = json['cust_CreatedDate'].toString();
    } else if (json['custCreatedDate'] != null) {
      parsedCustCreatedDate = json['custCreatedDate'].toString();
    }

    // Parse Modified By
    int parsedCustModifiedBy = 0;
    if (json['cust_ModifiedBy'] != null) {
      parsedCustModifiedBy = int.tryParse(json['cust_ModifiedBy'].toString()) ?? 0;
    } else if (json['custModifiedBy'] != null) {
      parsedCustModifiedBy = int.tryParse(json['custModifiedBy'].toString()) ?? 0;
    }

    // Parse Modified Date
    String? parsedCustModifiedDate;
    if (json['cust_ModifiedDate'] != null) {
      parsedCustModifiedDate = json['cust_ModifiedDate'].toString();
    } else if (json['custModifiedDate'] != null) {
      parsedCustModifiedDate = json['custModifiedDate'].toString();
    }

    return CustomerListItem(
      custId: parsedCustId,
      custCode: parsedCustCode,
      custName: parsedCustName,
      custCompanyName: parsedCustCompanyName,
      custMobileNo: parsedCustMobileNo,
      custAlternateMobileNo: parsedCustAlternateMobileNo,
      custEmail: parsedCustEmail,
      custGSTNo: parsedCustGSTNo,
      custPANNo: parsedCustPANNo,
      custAddress: parsedCustAddress,
      custAreaId: parsedCustAreaId,
      custArea: parsedCustArea,
      custCityId: parsedCustCityId,
      custCity: parsedCustCity,
      custStateId: parsedCustStateId,
      custState: parsedCustState,
      custPincode: parsedCustPincode,
      custCountry: parsedCustCountry,
      custBranchId: parsedCustBranchId,
      custCompId: parsedCustCompId,
      custIsActive: parsedIsActive,
      custCreatedBy: parsedCustCreatedBy,
      custCreatedDate: parsedCustCreatedDate,
      custModifiedBy: parsedCustModifiedBy,
      custModifiedDate: parsedCustModifiedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cust_Id': custId,
      'cust_Code': custCode,
      'cust_Name': custName,
      'cust_CompanyName': custCompanyName,
      'cust_MobileNo': custMobileNo,
      'cust_AlternateMobileNo': custAlternateMobileNo,
      'cust_Email': custEmail,
      'cust_GSTNo': custGSTNo,
      'cust_PANNo': custPANNo,
      'cust_Address': custAddress,
      'cust_Areaid': custAreaId,
      'cust_Area': custArea,
      'cust_Cityid': custCityId,
      'cust_City': custCity,
      'cust_Stateid': custStateId,
      'cust_State': custState,
      'cust_Pincode': custPincode,
      'cust_Country': custCountry,
      'cust_BranchId': custBranchId,
      'cust_CompId': custCompId,
      'cust_IsActive': custIsActive,
      'cust_CreatedBy': custCreatedBy,
      if (custCreatedDate != null) 'cust_CreatedDate': custCreatedDate,
      'cust_ModifiedBy': custModifiedBy,
      if (custModifiedDate != null) 'cust_ModifiedDate': custModifiedDate,
    };
  }

  CustomerListItem copyWith({
    int? custId,
    String? custCode,
    String? custName,
    String? custCompanyName,
    String? custMobileNo,
    String? custAlternateMobileNo,
    String? custEmail,
    String? custGSTNo,
    String? custPANNo,
    String? custAddress,
    int? custAreaId,
    String? custArea,
    int? custCityId,
    String? custCity,
    int? custStateId,
    String? custState,
    String? custPincode,
    String? custCountry,
    int? custBranchId,
    int? custCompId,
    bool? custIsActive,
    int? custCreatedBy,
    String? custCreatedDate,
    int? custModifiedBy,
    String? custModifiedDate,
  }) {
    return CustomerListItem(
      custId: custId ?? this.custId,
      custCode: custCode ?? this.custCode,
      custName: custName ?? this.custName,
      custCompanyName: custCompanyName ?? this.custCompanyName,
      custMobileNo: custMobileNo ?? this.custMobileNo,
      custAlternateMobileNo: custAlternateMobileNo ?? this.custAlternateMobileNo,
      custEmail: custEmail ?? this.custEmail,
      custGSTNo: custGSTNo ?? this.custGSTNo,
      custPANNo: custPANNo ?? this.custPANNo,
      custAddress: custAddress ?? this.custAddress,
      custAreaId: custAreaId ?? this.custAreaId,
      custArea: custArea ?? this.custArea,
      custCityId: custCityId ?? this.custCityId,
      custCity: custCity ?? this.custCity,
      custStateId: custStateId ?? this.custStateId,
      custState: custState ?? this.custState,
      custPincode: custPincode ?? this.custPincode,
      custCountry: custCountry ?? this.custCountry,
      custBranchId: custBranchId ?? this.custBranchId,
      custCompId: custCompId ?? this.custCompId,
      custIsActive: custIsActive ?? this.custIsActive,
      custCreatedBy: custCreatedBy ?? this.custCreatedBy,
      custCreatedDate: custCreatedDate ?? this.custCreatedDate,
      custModifiedBy: custModifiedBy ?? this.custModifiedBy,
      custModifiedDate: custModifiedDate ?? this.custModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerListItem &&
          runtimeType == other.runtimeType &&
          custId == other.custId;

  @override
  int get hashCode => custId.hashCode;

  @override
  String toString() => '$custName ($custMobileNo) - $custCity';
}

/// Typedef for backwards compatibility with previous local `Customer` model
typedef Customer = CustomerListItem;

/// Response model for GET `/api/Customer/GetAllCustomers`
class CustomerListResponse {
  final bool status;
  final String message;
  final List<CustomerListItem> data;
  final String? error;

  CustomerListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    List<CustomerListItem> customersList = [];
    if (json['data'] != null && json['data'] is List) {
      customersList = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => CustomerListItem.fromJson(item))
          .toList();
    }

    return CustomerListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: customersList,
      error: json['error']?.toString(),
    );
  }
}

/// Response model for GET `/api/Customer/GetCustomerById/{Cust_Id}`
class CustomerDetailResponse {
  final bool status;
  final String message;
  final CustomerListItem? data;
  final String? error;

  CustomerDetailResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory CustomerDetailResponse.fromJson(Map<String, dynamic> json) {
    CustomerListItem? customerData;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      customerData = CustomerListItem.fromJson(json['data'] as Map<String, dynamic>);
    }

    return CustomerDetailResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: customerData,
      error: json['error']?.toString(),
    );
  }
}

/// Request model for POST `/api/Customer/InsertorUpdateCustomer`
class CustomerUpsertRequest {
  final int custId;
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
  final bool custIsActive;
  final int custCreatedBy;
  final int custModifiedBy;

  CustomerUpsertRequest({
    this.custId = 0,
    required this.custName,
    this.custCompanyName = '',
    required this.custMobileNo,
    this.custAlternateMobileNo = '',
    this.custEmail = '',
    this.custGSTNo = '',
    this.custPANNo = '',
    this.custAddress = '',
    this.custAreaId = 0,
    this.custCityId = 0,
    this.custStateId = 0,
    this.custPincode = '',
    this.custCountry = 'India',
    this.custBranchId = 1,
    this.custCompId = 1,
    this.custIsActive = true,
    this.custCreatedBy = 0,
    this.custModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'cust_Id': custId,
      'cust_Name': custName.trim(),
      'cust_CompanyName': custCompanyName.trim(),
      'cust_MobileNo': custMobileNo.trim(),
      'cust_AlternateMobileNo': custAlternateMobileNo.trim(),
      'cust_Email': custEmail.trim(),
      'cust_GSTNo': custGSTNo.trim().toUpperCase(),
      'cust_PANNo': custPANNo.trim().toUpperCase(),
      'cust_Address': custAddress.trim(),
      'cust_Areaid': custAreaId,
      'cust_Cityid': custCityId,
      'cust_Stateid': custStateId,
      'cust_Pincode': custPincode.trim(),
      'cust_Country': custCountry.trim().isEmpty ? 'India' : custCountry.trim(),
      'cust_BranchId': custBranchId,
      'cust_CompId': custCompId,
      'cust_IsActive': custIsActive,
      'cust_CreatedBy': custCreatedBy,
      'cust_ModifiedBy': custModifiedBy,
    };
  }

  factory CustomerUpsertRequest.fromJson(Map<String, dynamic> json) {
    return CustomerUpsertRequest(
      custId: int.tryParse(json['cust_Id']?.toString() ?? '0') ?? 0,
      custName: json['cust_Name']?.toString() ?? '',
      custCompanyName: json['cust_CompanyName']?.toString() ?? '',
      custMobileNo: json['cust_MobileNo']?.toString() ?? '',
      custAlternateMobileNo: json['cust_AlternateMobileNo']?.toString() ?? '',
      custEmail: json['cust_Email']?.toString() ?? '',
      custGSTNo: json['cust_GSTNo']?.toString() ?? '',
      custPANNo: json['cust_PANNo']?.toString() ?? '',
      custAddress: json['cust_Address']?.toString() ?? '',
      custAreaId: int.tryParse(
            (json['cust_Areaid'] ??
                    json['cust_AreaId'] ??
                    json['custAreaId'] ??
                    json['custAreaid'] ??
                    json['area_Id'] ??
                    json['areaId'])
                ?.toString() ??
                '0',
          ) ??
          0,
      custCityId: int.tryParse(
            (json['cust_Cityid'] ??
                    json['cust_CityId'] ??
                    json['custCityId'] ??
                    json['custCityid'] ??
                    json['city_Id'] ??
                    json['cityId'])
                ?.toString() ??
                '0',
          ) ??
          0,
      custStateId: int.tryParse(
            (json['cust_Stateid'] ??
                    json['cust_StateId'] ??
                    json['custStateId'] ??
                    json['custStateid'] ??
                    json['state_Id'] ??
                    json['stateId'])
                ?.toString() ??
                '0',
          ) ??
          0,
      custPincode: json['cust_Pincode']?.toString() ?? '',
      custCountry: json['cust_Country']?.toString() ?? 'India',
      custBranchId: int.tryParse(json['cust_BranchId']?.toString() ?? '1') ?? 1,
      custCompId: int.tryParse(json['cust_CompId']?.toString() ?? '1') ?? 1,
      custIsActive: json['cust_IsActive'] == true ||
          json['cust_IsActive'] == 'true' ||
          json['cust_IsActive'] == 1 ||
          json['cust_IsActive'] == '1',
      custCreatedBy: int.tryParse(json['cust_CreatedBy']?.toString() ?? '0') ?? 0,
      custModifiedBy: int.tryParse(json['cust_ModifiedBy']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Data payload of POST `/api/Customer/InsertorUpdateCustomer` response
class CustomerUpsertResultData {
  final bool status;
  final String message;
  final int custId;
  final String custCode;

  CustomerUpsertResultData({
    required this.status,
    required this.message,
    required this.custId,
    required this.custCode,
  });

  factory CustomerUpsertResultData.fromJson(Map<String, dynamic> json) {
    return CustomerUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      custId: int.tryParse(json['cust_Id']?.toString() ?? '0') ?? 0,
      custCode: json['cust_Code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'cust_Id': custId,
      'cust_Code': custCode,
    };
  }
}

/// Full response model for POST `/api/Customer/InsertorUpdateCustomer`
class CustomerUpsertResponse {
  final bool status;
  final String message;
  final CustomerUpsertResultData? data;
  final String? error;

  CustomerUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory CustomerUpsertResponse.fromJson(Map<String, dynamic> json) {
    CustomerUpsertResultData? dataObj;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataObj = CustomerUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return CustomerUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}
