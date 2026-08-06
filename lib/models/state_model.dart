class StateModel {
  final int stateId;
  final String stateName;
  final String? stateCode;
  final bool stateIsActive;
  final int? countryId;

  const StateModel({
    required this.stateId,
    required this.stateName,
    this.stateCode,
    this.stateIsActive = true,
    this.countryId,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    // Parse State ID
    int parsedId = 0;
    if (json['state_Id'] != null) {
      parsedId = int.tryParse(json['state_Id'].toString()) ?? 0;
    } else if (json['stateId'] != null) {
      parsedId = int.tryParse(json['stateId'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    // Parse State Name
    String parsedName = '';
    if (json['state_Name'] != null) {
      parsedName = json['state_Name'].toString();
    } else if (json['stateName'] != null) {
      parsedName = json['stateName'].toString();
    } else if (json['name'] != null) {
      parsedName = json['name'].toString();
    }

    // Parse State Code
    String? parsedCode;
    if (json['state_Code'] != null) {
      parsedCode = json['state_Code'].toString();
    } else if (json['stateCode'] != null) {
      parsedCode = json['stateCode'].toString();
    } else if (json['code'] != null) {
      parsedCode = json['code'].toString();
    }

    // Parse Active Status
    bool parsedIsActive = true;
    if (json['state_IsActive'] != null) {
      final val = json['state_IsActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    } else if (json['isActive'] != null) {
      final val = json['isActive'];
      parsedIsActive = val == true || val == 'true' || val == 1 || val == '1';
    }

    // Parse Country ID
    int? parsedCountryId;
    if (json['country_Id'] != null) {
      parsedCountryId = int.tryParse(json['country_Id'].toString());
    } else if (json['countryId'] != null) {
      parsedCountryId = int.tryParse(json['countryId'].toString());
    }

    return StateModel(
      stateId: parsedId,
      stateName: parsedName,
      stateCode: parsedCode,
      stateIsActive: parsedIsActive,
      countryId: parsedCountryId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state_Id': stateId,
      'state_Name': stateName,
      if (stateCode != null) 'state_Code': stateCode,
      'state_IsActive': stateIsActive,
      if (countryId != null) 'country_Id': countryId,
    };
  }

  StateModel copyWith({
    int? stateId,
    String? stateName,
    String? stateCode,
    bool? stateIsActive,
    int? countryId,
  }) {
    return StateModel(
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      stateCode: stateCode ?? this.stateCode,
      stateIsActive: stateIsActive ?? this.stateIsActive,
      countryId: countryId ?? this.countryId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel &&
          runtimeType == other.runtimeType &&
          stateId == other.stateId;

  @override
  int get hashCode => stateId.hashCode;

  @override
  String toString() =>
      stateCode != null && stateCode!.isNotEmpty
          ? '$stateName ($stateCode)'
          : stateName;
}

class StateListResponse {
  final bool status;
  final String message;
  final List<StateModel> data;
  final String? error;

  StateListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory StateListResponse.fromJson(Map<String, dynamic> json) {
    List<StateModel> statesList = [];
    if (json['data'] != null && json['data'] is List) {
      statesList = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => StateModel.fromJson(item))
          .toList();
    }

    return StateListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: statesList,
      error: json['error']?.toString(),
    );
  }
}

/// Typedef for consistency with other master model naming conventions
typedef StateListItem = StateModel;

