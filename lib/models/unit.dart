class UnitListItem {
  final int unitId;
  final String unitName;
  final String unitShortName;
  final bool unitIsActive;
  final int unitCreatedBy;
  final int unitModifiedBy;
  final DateTime? unitCreatedDate;
  final DateTime? unitModifiedDate;

  const UnitListItem({
    required this.unitId,
    required this.unitName,
    required this.unitShortName,
    this.unitIsActive = true,
    required this.unitCreatedBy,
    required this.unitModifiedBy,
    this.unitCreatedDate,
    this.unitModifiedDate,
  });

  factory UnitListItem.fromJson(Map<String, dynamic> json) {
    return UnitListItem(
      unitId: int.tryParse(json['unit_Id']?.toString() ?? '0') ?? 0,
      unitName: json['unit_Name']?.toString() ?? '',
      unitShortName: json['unit_ShortName']?.toString() ?? '',
      unitIsActive: json['unit_IsActive'] == true || json['unit_IsActive'] == 'true' || json['unit_IsActive'] == 1,
      unitCreatedBy: int.tryParse(json['unit_CreatedBy']?.toString() ?? '0') ?? 0,
      unitModifiedBy: int.tryParse(json['unit_ModifiedBy']?.toString() ?? '0') ?? 0,
      unitCreatedDate: json['unit_CreatedDate'] != null ? DateTime.tryParse(json['unit_CreatedDate'].toString()) : null,
      unitModifiedDate: json['unit_ModifiedDate'] != null ? DateTime.tryParse(json['unit_ModifiedDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_Id': unitId,
      'unit_Name': unitName,
      'unit_ShortName': unitShortName,
      'unit_IsActive': unitIsActive,
      'unit_CreatedBy': unitCreatedBy,
      'unit_ModifiedBy': unitModifiedBy,
      if (unitCreatedDate != null) 'unit_CreatedDate': unitCreatedDate?.toIso8601String(),
      if (unitModifiedDate != null) 'unit_ModifiedDate': unitModifiedDate?.toIso8601String(),
    };
  }

  UnitListItem copyWith({
    int? unitId,
    String? unitName,
    String? unitShortName,
    bool? unitIsActive,
    int? unitCreatedBy,
    int? unitModifiedBy,
    DateTime? unitCreatedDate,
    DateTime? unitModifiedDate,
  }) {
    return UnitListItem(
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      unitShortName: unitShortName ?? this.unitShortName,
      unitIsActive: unitIsActive ?? this.unitIsActive,
      unitCreatedBy: unitCreatedBy ?? this.unitCreatedBy,
      unitModifiedBy: unitModifiedBy ?? this.unitModifiedBy,
      unitCreatedDate: unitCreatedDate ?? this.unitCreatedDate,
      unitModifiedDate: unitModifiedDate ?? this.unitModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitListItem &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId;

  @override
  int get hashCode => unitId.hashCode;

  @override
  String toString() => unitName;
}

class UnitListResponse {
  final bool status;
  final String message;
  final List<UnitListItem> data;
  final String? error;

  UnitListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory UnitListResponse.fromJson(Map<String, dynamic> json) {
    List<UnitListItem> list = [];
    if (json['data'] != null && json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => UnitListItem.fromJson(item))
          .toList();
    }

    return UnitListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: list,
      error: json['error']?.toString(),
    );
  }
}

class UnitUpsertRequest {
  final int unitId;
  final String unitName;
  final String unitShortName;
  final bool unitIsActive;
  final int unitCreatedBy;
  final int unitModifiedBy;

  UnitUpsertRequest({
    this.unitId = 0,
    required this.unitName,
    this.unitShortName = '',
    this.unitIsActive = true,
    this.unitCreatedBy = 0,
    this.unitModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'unit_Id': unitId,
      'unit_Name': unitName.trim(),
      'unit_ShortName': unitShortName.trim(),
      'unit_IsActive': unitIsActive,
      'unit_CreatedBy': unitCreatedBy,
      'unit_ModifiedBy': unitModifiedBy,
    };
  }
}

class UnitUpsertResultData {
  final bool status;
  final String message;
  final int unitId;

  UnitUpsertResultData({
    required this.status,
    required this.message,
    required this.unitId,
  });

  factory UnitUpsertResultData.fromJson(Map<String, dynamic> json) {
    return UnitUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      unitId: int.tryParse(json['unit_Id']?.toString() ?? '0') ?? 0,
    );
  }
}

class UnitUpsertResponse {
  final bool status;
  final String message;
  final UnitUpsertResultData? data;
  final String? error;

  UnitUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory UnitUpsertResponse.fromJson(Map<String, dynamic> json) {
    UnitUpsertResultData? dataObj;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataObj = UnitUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return UnitUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}
