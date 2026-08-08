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
  final String custAreaName;
  final int custCityId;
  final String custCity;
  final String custCityName;
  final int custStateId;
  final String custState;
  final String custStateName;
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
    String custArea = '',
    String custAreaName = '',
    this.custCityId = 0,
    String custCity = '',
    String custCityName = '',
    this.custStateId = 0,
    String custState = '',
    String custStateName = '',
    this.custPincode = '',
    this.custCountry = 'India',
    this.custBranchId = 0,
    this.custCompId = 0,
    this.custIsActive = true,
    this.custCreatedBy = 0,
    this.custCreatedDate,
    this.custModifiedBy = 0,
    this.custModifiedDate,
  })  : custArea = custArea.isNotEmpty ? custArea : custAreaName,
        custAreaName = custAreaName.isNotEmpty ? custAreaName : custArea,
        custCity = custCity.isNotEmpty ? custCity : custCityName,
        custCityName = custCityName.isNotEmpty ? custCityName : custCity,
        custState = custState.isNotEmpty ? custState : custStateName,
        custStateName = custStateName.isNotEmpty ? custStateName : custState;

  // Backwards compatibility getters
  String get id => custId.toString();
  String get name => custName;
  String get mobile => custMobileNo;
  String? get email => custEmail.isNotEmpty ? custEmail : null;
  String? get gstNumber => custGSTNo.isNotEmpty ? custGSTNo : null;
  String? get address => custAddress.isNotEmpty ? custAddress : null;
  String? get city => custCityName.isNotEmpty ? custCityName : null;
  String? get cityName => custCityName.isNotEmpty ? custCityName : null;
  String? get state => custStateName.isNotEmpty ? custStateName : null;
  String? get stateName => custStateName.isNotEmpty ? custStateName : null;
  String? get areaName => custAreaName.isNotEmpty ? custAreaName : null;
  String? get pincode => custPincode.isNotEmpty ? custPincode : null;
  bool get isActive => custIsActive;

  /// Helper to get a nicely formatted multi-part address string
  String get fullAddress {
    final parts = [
      if (custAddress.trim().isNotEmpty) custAddress.trim(),
      if (custAreaName.trim().isNotEmpty) custAreaName.trim(),
      if (custCityName.trim().isNotEmpty) custCityName.trim(),
      if (custStateName.trim().isNotEmpty) custStateName.trim(),
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
    } else if (json['Cust_Areaid'] != null) {
      parsedCustAreaId = int.tryParse(json['Cust_Areaid'].toString()) ?? 0;
    } else if (json['cust_AreaId'] != null) {
      parsedCustAreaId = int.tryParse(json['cust_AreaId'].toString()) ?? 0;
    } else if (json['Cust_AreaId'] != null) {
      parsedCustAreaId = int.tryParse(json['Cust_AreaId'].toString()) ?? 0;
    } else if (json['custAreaId'] != null) {
      parsedCustAreaId = int.tryParse(json['custAreaId'].toString()) ?? 0;
    } else if (json['custAreaid'] != null) {
      parsedCustAreaId = int.tryParse(json['custAreaid'].toString()) ?? 0;
    } else if (json['area_Id'] != null) {
      parsedCustAreaId = int.tryParse(json['area_Id'].toString()) ?? 0;
    } else if (json['areaId'] != null) {
      parsedCustAreaId = int.tryParse(json['areaId'].toString()) ?? 0;
    }

    // Parse Area Name (Cust_AreaName)
    String parsedCustAreaName = '';
    if (json['Cust_AreaName'] != null && json['Cust_AreaName'].toString().isNotEmpty) {
      parsedCustAreaName = json['Cust_AreaName'].toString();
    } else if (json['cust_AreaName'] != null && json['cust_AreaName'].toString().isNotEmpty) {
      parsedCustAreaName = json['cust_AreaName'].toString();
    } else if (json['custAreaName'] != null && json['custAreaName'].toString().isNotEmpty) {
      parsedCustAreaName = json['custAreaName'].toString();
    } else if (json['AreaName'] != null && json['AreaName'].toString().isNotEmpty) {
      parsedCustAreaName = json['AreaName'].toString();
    } else if (json['areaName'] != null && json['areaName'].toString().isNotEmpty) {
      parsedCustAreaName = json['areaName'].toString();
    } else if (json['area_Name'] != null && json['area_Name'].toString().isNotEmpty) {
      parsedCustAreaName = json['area_Name'].toString();
    } else if (json['Cust_Area'] != null && json['Cust_Area'].toString().isNotEmpty) {
      parsedCustAreaName = json['Cust_Area'].toString();
    } else if (json['cust_Area'] != null && json['cust_Area'].toString().isNotEmpty) {
      parsedCustAreaName = json['cust_Area'].toString();
    } else if (json['custArea'] != null && json['custArea'].toString().isNotEmpty) {
      parsedCustAreaName = json['custArea'].toString();
    } else if (json['area'] != null && json['area'].toString().isNotEmpty) {
      parsedCustAreaName = json['area'].toString();
    }

    // Parse City ID
    int parsedCustCityId = 0;
    if (json['cust_Cityid'] != null) {
      parsedCustCityId = int.tryParse(json['cust_Cityid'].toString()) ?? 0;
    } else if (json['Cust_Cityid'] != null) {
      parsedCustCityId = int.tryParse(json['Cust_Cityid'].toString()) ?? 0;
    } else if (json['cust_CityId'] != null) {
      parsedCustCityId = int.tryParse(json['cust_CityId'].toString()) ?? 0;
    } else if (json['Cust_CityId'] != null) {
      parsedCustCityId = int.tryParse(json['Cust_CityId'].toString()) ?? 0;
    } else if (json['custCityId'] != null) {
      parsedCustCityId = int.tryParse(json['custCityId'].toString()) ?? 0;
    } else if (json['custCityid'] != null) {
      parsedCustCityId = int.tryParse(json['custCityid'].toString()) ?? 0;
    } else if (json['city_Id'] != null) {
      parsedCustCityId = int.tryParse(json['city_Id'].toString()) ?? 0;
    } else if (json['cityId'] != null) {
      parsedCustCityId = int.tryParse(json['cityId'].toString()) ?? 0;
    }

    // Parse City Name (Cust_CityName)
    String parsedCustCityName = '';
    if (json['Cust_CityName'] != null && json['Cust_CityName'].toString().isNotEmpty) {
      parsedCustCityName = json['Cust_CityName'].toString();
    } else if (json['cust_CityName'] != null && json['cust_CityName'].toString().isNotEmpty) {
      parsedCustCityName = json['cust_CityName'].toString();
    } else if (json['custCityName'] != null && json['custCityName'].toString().isNotEmpty) {
      parsedCustCityName = json['custCityName'].toString();
    } else if (json['CityName'] != null && json['CityName'].toString().isNotEmpty) {
      parsedCustCityName = json['CityName'].toString();
    } else if (json['cityName'] != null && json['cityName'].toString().isNotEmpty) {
      parsedCustCityName = json['cityName'].toString();
    } else if (json['city_Name'] != null && json['city_Name'].toString().isNotEmpty) {
      parsedCustCityName = json['city_Name'].toString();
    } else if (json['Cust_City'] != null && json['Cust_City'].toString().isNotEmpty) {
      parsedCustCityName = json['Cust_City'].toString();
    } else if (json['cust_City'] != null && json['cust_City'].toString().isNotEmpty) {
      parsedCustCityName = json['cust_City'].toString();
    } else if (json['custCity'] != null && json['custCity'].toString().isNotEmpty) {
      parsedCustCityName = json['custCity'].toString();
    } else if (json['city'] != null && json['city'].toString().isNotEmpty) {
      parsedCustCityName = json['city'].toString();
    }

    // Parse State ID
    int parsedCustStateId = 0;
    if (json['cust_Stateid'] != null) {
      parsedCustStateId = int.tryParse(json['cust_Stateid'].toString()) ?? 0;
    } else if (json['Cust_Stateid'] != null) {
      parsedCustStateId = int.tryParse(json['Cust_Stateid'].toString()) ?? 0;
    } else if (json['cust_StateId'] != null) {
      parsedCustStateId = int.tryParse(json['cust_StateId'].toString()) ?? 0;
    } else if (json['Cust_StateId'] != null) {
      parsedCustStateId = int.tryParse(json['Cust_StateId'].toString()) ?? 0;
    } else if (json['custStateId'] != null) {
      parsedCustStateId = int.tryParse(json['custStateId'].toString()) ?? 0;
    } else if (json['custStateid'] != null) {
      parsedCustStateId = int.tryParse(json['custStateid'].toString()) ?? 0;
    } else if (json['state_Id'] != null) {
      parsedCustStateId = int.tryParse(json['state_Id'].toString()) ?? 0;
    } else if (json['stateId'] != null) {
      parsedCustStateId = int.tryParse(json['stateId'].toString()) ?? 0;
    }

    // Parse State Name (Cust_StateName)
    String parsedCustStateName = '';
    if (json['Cust_StateName'] != null && json['Cust_StateName'].toString().isNotEmpty) {
      parsedCustStateName = json['Cust_StateName'].toString();
    } else if (json['cust_StateName'] != null && json['cust_StateName'].toString().isNotEmpty) {
      parsedCustStateName = json['cust_StateName'].toString();
    } else if (json['custStateName'] != null && json['custStateName'].toString().isNotEmpty) {
      parsedCustStateName = json['custStateName'].toString();
    } else if (json['StateName'] != null && json['StateName'].toString().isNotEmpty) {
      parsedCustStateName = json['StateName'].toString();
    } else if (json['stateName'] != null && json['stateName'].toString().isNotEmpty) {
      parsedCustStateName = json['stateName'].toString();
    } else if (json['state_Name'] != null && json['state_Name'].toString().isNotEmpty) {
      parsedCustStateName = json['state_Name'].toString();
    } else if (json['Cust_State'] != null && json['Cust_State'].toString().isNotEmpty) {
      parsedCustStateName = json['Cust_State'].toString();
    } else if (json['cust_State'] != null && json['cust_State'].toString().isNotEmpty) {
      parsedCustStateName = json['cust_State'].toString();
    } else if (json['custState'] != null && json['custState'].toString().isNotEmpty) {
      parsedCustStateName = json['custState'].toString();
    } else if (json['state'] != null && json['state'].toString().isNotEmpty) {
      parsedCustStateName = json['state'].toString();
    }

    // Parse Pincode
    String parsedCustPincode = '';
    if (json['cust_Pincode'] != null) {
      parsedCustPincode = json['cust_Pincode'].toString();
    } else if (json['Cust_Pincode'] != null) {
      parsedCustPincode = json['Cust_Pincode'].toString();
    } else if (json['custPincode'] != null) {
      parsedCustPincode = json['custPincode'].toString();
    } else if (json['pincode'] != null) {
      parsedCustPincode = json['pincode'].toString();
    }

    // Parse Country
    String parsedCustCountry = 'India';
    if (json['cust_Country'] != null && json['cust_Country'].toString().isNotEmpty) {
      parsedCustCountry = json['cust_Country'].toString();
    } else if (json['Cust_Country'] != null && json['Cust_Country'].toString().isNotEmpty) {
      parsedCustCountry = json['Cust_Country'].toString();
    } else if (json['custCountry'] != null && json['custCountry'].toString().isNotEmpty) {
      parsedCustCountry = json['custCountry'].toString();
    } else if (json['country'] != null && json['country'].toString().isNotEmpty) {
      parsedCustCountry = json['country'].toString();
    }

    // Parse Branch ID
    int parsedCustBranchId = 0;
    if (json['cust_BranchId'] != null) {
      parsedCustBranchId = int.tryParse(json['cust_BranchId'].toString()) ?? 0;
    } else if (json['Cust_BranchId'] != null) {
      parsedCustBranchId = int.tryParse(json['Cust_BranchId'].toString()) ?? 0;
    } else if (json['custBranchId'] != null) {
      parsedCustBranchId = int.tryParse(json['custBranchId'].toString()) ?? 0;
    } else if (json['branchId'] != null) {
      parsedCustBranchId = int.tryParse(json['branchId'].toString()) ?? 0;
    }

    // Parse Company ID
    int parsedCustCompId = 0;
    if (json['cust_CompId'] != null) {
      parsedCustCompId = int.tryParse(json['cust_CompId'].toString()) ?? 0;
    } else if (json['Cust_CompId'] != null) {
      parsedCustCompId = int.tryParse(json['Cust_CompId'].toString()) ?? 0;
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
    } else if (json['Cust_IsActive'] != null) {
      final val = json['Cust_IsActive'];
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
    } else if (json['Cust_CreatedBy'] != null) {
      parsedCustCreatedBy = int.tryParse(json['Cust_CreatedBy'].toString()) ?? 0;
    } else if (json['custCreatedBy'] != null) {
      parsedCustCreatedBy = int.tryParse(json['custCreatedBy'].toString()) ?? 0;
    }

    // Parse Created Date
    String? parsedCustCreatedDate;
    if (json['cust_CreatedDate'] != null) {
      parsedCustCreatedDate = json['cust_CreatedDate'].toString();
    } else if (json['Cust_CreatedDate'] != null) {
      parsedCustCreatedDate = json['Cust_CreatedDate'].toString();
    } else if (json['custCreatedDate'] != null) {
      parsedCustCreatedDate = json['custCreatedDate'].toString();
    }

    // Parse Modified By
    int parsedCustModifiedBy = 0;
    if (json['cust_ModifiedBy'] != null) {
      parsedCustModifiedBy = int.tryParse(json['cust_ModifiedBy'].toString()) ?? 0;
    } else if (json['Cust_ModifiedBy'] != null) {
      parsedCustModifiedBy = int.tryParse(json['Cust_ModifiedBy'].toString()) ?? 0;
    } else if (json['custModifiedBy'] != null) {
      parsedCustModifiedBy = int.tryParse(json['custModifiedBy'].toString()) ?? 0;
    }

    // Parse Modified Date
    String? parsedCustModifiedDate;
    if (json['cust_ModifiedDate'] != null) {
      parsedCustModifiedDate = json['cust_ModifiedDate'].toString();
    } else if (json['Cust_ModifiedDate'] != null) {
      parsedCustModifiedDate = json['Cust_ModifiedDate'].toString();
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
      custArea: parsedCustAreaName,
      custAreaName: parsedCustAreaName,
      custCityId: parsedCustCityId,
      custCity: parsedCustCityName,
      custCityName: parsedCustCityName,
      custStateId: parsedCustStateId,
      custState: parsedCustStateName,
      custStateName: parsedCustStateName,
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
      'cust_Area': custAreaName,
      'cust_AreaName': custAreaName,
      'Cust_AreaName': custAreaName,
      'cust_Cityid': custCityId,
      'cust_City': custCityName,
      'cust_CityName': custCityName,
      'Cust_CityName': custCityName,
      'cust_Stateid': custStateId,
      'cust_State': custStateName,
      'cust_StateName': custStateName,
      'Cust_StateName': custStateName,
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
    String? custAreaName,
    int? custCityId,
    String? custCity,
    String? custCityName,
    int? custStateId,
    String? custState,
    String? custStateName,
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
    final effectiveArea = custAreaName ?? custArea ?? this.custAreaName;
    final effectiveCity = custCityName ?? custCity ?? this.custCityName;
    final effectiveState = custStateName ?? custState ?? this.custStateName;
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
      custArea: effectiveArea,
      custAreaName: effectiveArea,
      custCityId: custCityId ?? this.custCityId,
      custCity: effectiveCity,
      custCityName: effectiveCity,
      custStateId: custStateId ?? this.custStateId,
      custState: effectiveState,
      custStateName: effectiveState,
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
