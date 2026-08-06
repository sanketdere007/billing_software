class CityListItem {
  final int cityId;
  final String cityName;
  final int? stateId;
  final String stateName;
  final String? stateCode;
  final bool cityIsActive;

  const CityListItem({
    required this.cityId,
    required this.cityName,
    this.stateId,
    required this.stateName,
    this.stateCode,
    this.cityIsActive = true,
  });

  factory CityListItem.fromJson(Map<String, dynamic> json) {
    // Parse City ID
    int parsedCityId = 0;
    if (json['city_Id'] != null) {
      parsedCityId = int.tryParse(json['city_Id'].toString()) ?? 0;
    } else if (json['cityId'] != null) {
      parsedCityId = int.tryParse(json['cityId'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedCityId = int.tryParse(json['id'].toString()) ?? 0;
    }

    // Parse City Name
    String parsedCityName = '';
    if (json['city_Name'] != null) {
      parsedCityName = json['city_Name'].toString();
    } else if (json['cityName'] != null) {
      parsedCityName = json['cityName'].toString();
    } else if (json['name'] != null) {
      parsedCityName = json['name'].toString();
    }

    // Parse State ID if present
    int? parsedStateId;
    if (json['city_StateId'] != null) {
      parsedStateId = int.tryParse(json['city_StateId'].toString());
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

    // Parse State Code
    String? parsedStateCode;
    if (json['state_Code'] != null) {
      parsedStateCode = json['state_Code'].toString();
    } else if (json['stateCode'] != null) {
      parsedStateCode = json['stateCode'].toString();
    }

    // Parse City Active Status
    bool parsedIsActive = true;
    if (json['city_IsActive'] != null) {
      final val = json['city_IsActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    } else if (json['isActive'] != null) {
      final val = json['isActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    }

    return CityListItem(
      cityId: parsedCityId,
      cityName: parsedCityName,
      stateId: parsedStateId,
      stateName: parsedStateName,
      stateCode: parsedStateCode,
      cityIsActive: parsedIsActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city_Id': cityId,
      'city_Name': cityName,
      if (stateId != null) 'city_StateId': stateId,
      'state_Name': stateName,
      if (stateCode != null) 'state_Code': stateCode,
      'city_IsActive': cityIsActive,
    };
  }

  CityListItem copyWith({
    int? cityId,
    String? cityName,
    int? stateId,
    String? stateName,
    String? stateCode,
    bool? cityIsActive,
  }) {
    return CityListItem(
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      stateCode: stateCode ?? this.stateCode,
      cityIsActive: cityIsActive ?? this.cityIsActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityListItem &&
          runtimeType == other.runtimeType &&
          cityId == other.cityId;

  @override
  int get hashCode => cityId.hashCode;

  @override
  String toString() => '$cityName, $stateName';
}

class CityListResponse {
  final bool status;
  final String message;
  final List<CityListItem> data;
  final String? error;

  CityListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory CityListResponse.fromJson(Map<String, dynamic> json) {
    List<CityListItem> citiesList = [];
    if (json['data'] != null && json['data'] is List) {
      citiesList = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => CityListItem.fromJson(item))
          .toList();
    }

    return CityListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: citiesList,
      error: json['error']?.toString(),
    );
  }
}

class CityUpsertRequest {
  final int cityId;
  final int cityStateId;
  final String cityName;
  final bool cityIsActive;
  final int cityCreatedBy;
  final int cityModifiedBy;

  CityUpsertRequest({
    this.cityId = 0,
    required this.cityStateId,
    required this.cityName,
    this.cityIsActive = true,
    this.cityCreatedBy = 0,
    this.cityModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'city_Id': cityId,
      'city_StateId': cityStateId,
      'city_Name': cityName.trim(),
      'city_IsActive': cityIsActive,
      'city_CreatedBy': cityCreatedBy,
      'city_ModifiedBy': cityModifiedBy,
    };
  }

  factory CityUpsertRequest.fromJson(Map<String, dynamic> json) {
    return CityUpsertRequest(
      cityId: int.tryParse(json['city_Id']?.toString() ?? '0') ?? 0,
      cityStateId: int.tryParse(json['city_StateId']?.toString() ?? '0') ?? 0,
      cityName: json['city_Name']?.toString() ?? '',
      cityIsActive: json['city_IsActive'] == true || json['city_IsActive'] == 'true' || json['city_IsActive'] == 1,
      cityCreatedBy: int.tryParse(json['city_CreatedBy']?.toString() ?? '0') ?? 0,
      cityModifiedBy: int.tryParse(json['city_ModifiedBy']?.toString() ?? '0') ?? 0,
    );
  }
}

class CityUpsertResultData {
  final bool status;
  final String message;
  final int cityId;

  CityUpsertResultData({
    required this.status,
    required this.message,
    required this.cityId,
  });

  factory CityUpsertResultData.fromJson(Map<String, dynamic> json) {
    return CityUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      cityId: int.tryParse(json['city_Id']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'city_Id': cityId,
    };
  }
}

class CityUpsertResponse {
  final bool status;
  final String message;
  final CityUpsertResultData? data;
  final String? error;

  CityUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory CityUpsertResponse.fromJson(Map<String, dynamic> json) {
    CityUpsertResultData? dataObj;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataObj = CityUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return CityUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}
