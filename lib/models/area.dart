class AreaListItem {
  final int areaId;
  final String areaName;
  final String areaPincode;
  final int? stateId;
  final String stateName;
  final int? cityId;
  final String cityName;
  final bool areaIsActive;

  const AreaListItem({
    required this.areaId,
    required this.areaName,
    required this.areaPincode,
    this.stateId,
    required this.stateName,
    this.cityId,
    required this.cityName,
    this.areaIsActive = true,
  });

  factory AreaListItem.fromJson(Map<String, dynamic> json) {
    // Parse Area ID
    int parsedAreaId = 0;
    if (json['area_Id'] != null) {
      parsedAreaId = int.tryParse(json['area_Id'].toString()) ?? 0;
    } else if (json['areaId'] != null) {
      parsedAreaId = int.tryParse(json['areaId'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedAreaId = int.tryParse(json['id'].toString()) ?? 0;
    }

    // Parse Area Name
    String parsedAreaName = '';
    if (json['area_Name'] != null) {
      parsedAreaName = json['area_Name'].toString();
    } else if (json['areaName'] != null) {
      parsedAreaName = json['areaName'].toString();
    } else if (json['name'] != null) {
      parsedAreaName = json['name'].toString();
    }

    // Parse Pincode
    String parsedPincode = '';
    if (json['area_Pincode'] != null) {
      parsedPincode = json['area_Pincode'].toString();
    } else if (json['areaPincode'] != null) {
      parsedPincode = json['areaPincode'].toString();
    } else if (json['pincode'] != null) {
      parsedPincode = json['pincode'].toString();
    }

    // Parse State ID
    int? parsedStateId;
    if (json['area_StateId'] != null) {
      parsedStateId = int.tryParse(json['area_StateId'].toString());
    } else if (json['state_Id'] != null) {
      parsedStateId = int.tryParse(json['state_Id'].toString());
    } else if (json['stateId'] != null) {
      parsedStateId = int.tryParse(json['stateId'].toString());
    }

    // Parse State Name
    String parsedStateName = '';
    if (json['state_Name'] != null) {
      parsedStateName = json['state_Name'].toString();
    } else if (json['stateName'] != null) {
      parsedStateName = json['stateName'].toString();
    }

    // Parse City ID
    int? parsedCityId;
    if (json['area_CityId'] != null) {
      parsedCityId = int.tryParse(json['area_CityId'].toString());
    } else if (json['city_Id'] != null) {
      parsedCityId = int.tryParse(json['city_Id'].toString());
    } else if (json['cityId'] != null) {
      parsedCityId = int.tryParse(json['cityId'].toString());
    }

    // Parse City Name
    String parsedCityName = '';
    if (json['city_Name'] != null) {
      parsedCityName = json['city_Name'].toString();
    } else if (json['cityName'] != null) {
      parsedCityName = json['cityName'].toString();
    }

    // Parse Area Active Status
    bool parsedIsActive = true;
    if (json['area_IsActive'] != null) {
      final val = json['area_IsActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    } else if (json['isActive'] != null) {
      final val = json['isActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    }

    return AreaListItem(
      areaId: parsedAreaId,
      areaName: parsedAreaName,
      areaPincode: parsedPincode,
      stateId: parsedStateId,
      stateName: parsedStateName,
      cityId: parsedCityId,
      cityName: parsedCityName,
      areaIsActive: parsedIsActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area_Id': areaId,
      'area_Name': areaName,
      'area_Pincode': areaPincode,
      if (stateId != null) 'area_StateId': stateId,
      'state_Name': stateName,
      if (cityId != null) 'area_CityId': cityId,
      'city_Name': cityName,
      'area_IsActive': areaIsActive,
    };
  }

  AreaListItem copyWith({
    int? areaId,
    String? areaName,
    String? areaPincode,
    int? stateId,
    String? stateName,
    int? cityId,
    String? cityName,
    bool? areaIsActive,
  }) {
    return AreaListItem(
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      areaPincode: areaPincode ?? this.areaPincode,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      areaIsActive: areaIsActive ?? this.areaIsActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AreaListItem &&
          runtimeType == other.runtimeType &&
          areaId == other.areaId;

  @override
  int get hashCode => areaId.hashCode;

  @override
  String toString() => '$areaName, $cityName ($areaPincode)';
}

class AreaListResponse {
  final bool status;
  final String message;
  final List<AreaListItem> data;
  final String? error;

  AreaListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory AreaListResponse.fromJson(Map<String, dynamic> json) {
    List<AreaListItem> areasList = [];
    if (json['data'] != null && json['data'] is List) {
      areasList = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => AreaListItem.fromJson(item))
          .toList();
    }

    return AreaListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: areasList,
      error: json['error']?.toString(),
    );
  }
}

class AreaUpsertRequest {
  final int areaId;
  final int areaStateId;
  final int areaCityId;
  final String areaName;
  final String areaPincode;
  final bool areaIsActive;
  final int areaCreatedBy;
  final int areaModifiedBy;

  AreaUpsertRequest({
    this.areaId = 0,
    required this.areaStateId,
    required this.areaCityId,
    required this.areaName,
    required this.areaPincode,
    this.areaIsActive = true,
    this.areaCreatedBy = 0,
    this.areaModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'area_Id': areaId,
      'area_StateId': areaStateId,
      'area_CityId': areaCityId,
      'area_Name': areaName.trim(),
      'area_Pincode': areaPincode.trim(),
      'area_IsActive': areaIsActive,
      'area_CreatedBy': areaCreatedBy,
      'area_ModifiedBy': areaModifiedBy,
    };
  }

  factory AreaUpsertRequest.fromJson(Map<String, dynamic> json) {
    return AreaUpsertRequest(
      areaId: int.tryParse(json['area_Id']?.toString() ?? '0') ?? 0,
      areaStateId: int.tryParse(json['area_StateId']?.toString() ?? '0') ?? 0,
      areaCityId: int.tryParse(json['area_CityId']?.toString() ?? '0') ?? 0,
      areaName: json['area_Name']?.toString() ?? '',
      areaPincode: json['area_Pincode']?.toString() ?? '',
      areaIsActive: json['area_IsActive'] == true ||
          json['area_IsActive'] == 'true' ||
          json['area_IsActive'] == 1,
      areaCreatedBy: int.tryParse(json['area_CreatedBy']?.toString() ?? '0') ?? 0,
      areaModifiedBy: int.tryParse(json['area_ModifiedBy']?.toString() ?? '0') ?? 0,
    );
  }
}

class AreaUpsertResultData {
  final bool status;
  final String message;
  final int areaId;

  AreaUpsertResultData({
    required this.status,
    required this.message,
    required this.areaId,
  });

  factory AreaUpsertResultData.fromJson(Map<String, dynamic> json) {
    return AreaUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      areaId: int.tryParse(json['area_Id']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'area_Id': areaId,
    };
  }
}

class AreaUpsertResponse {
  final bool status;
  final String message;
  final AreaUpsertResultData? data;
  final String? error;

  AreaUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory AreaUpsertResponse.fromJson(Map<String, dynamic> json) {
    AreaUpsertResultData? dataObj;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataObj =
          AreaUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return AreaUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}
