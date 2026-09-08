class RouteListItem {
  final int routeId;
  final int routeCompId;
  final int routeBranchId;
  final String routeName;
  final String routeDescription;
  final bool routeIsActive;
  final int routeCreatedBy;
  final int routeModifiedBy;
  final String? routeCreatedDate;
  final String? routeModifiedDate;

  RouteListItem({
    required this.routeId,
    this.routeCompId = 0,
    this.routeBranchId = 0,
    required this.routeName,
    this.routeDescription = '',
    this.routeIsActive = true,
    this.routeCreatedBy = 0,
    this.routeModifiedBy = 0,
    this.routeCreatedDate,
    this.routeModifiedDate,
  });

  String get id => routeId.toString();
  String get name => routeName;
  bool get isActive => routeIsActive;

  factory RouteListItem.fromJson(Map<String, dynamic> json) {
    return RouteListItem(
      routeId: _parseInt(json['route_Id']),
      routeCompId: _parseInt(json['route_CompId']),
      routeBranchId: _parseInt(json['route_BranchId']),
      routeName: json['route_Name']?.toString() ?? '',
      routeDescription: json['route_Description']?.toString() ?? '',
      routeIsActive: json['route_IsActive'] == true ||
          json['route_IsActive'] == 'true' ||
          json['route_IsActive'] == 1 ||
          json['route_IsActive'] == '1',
      routeCreatedBy: int.tryParse(json['route_CreatedBy']?.toString() ?? '0') ?? 0,
      routeModifiedBy: int.tryParse(json['route_ModifiedBy']?.toString() ?? '0') ?? 0,
      routeCreatedDate: json['route_CreatedDate']?.toString(),
      routeModifiedDate: json['route_ModifiedDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_Id': routeId,
      'route_CompId': routeCompId,
      'route_BranchId': routeBranchId,
      'route_Name': routeName,
      'route_Description': routeDescription,
      'route_IsActive': routeIsActive,
      'route_CreatedBy': routeCreatedBy,
      'route_ModifiedBy': routeModifiedBy,
      if (routeCreatedDate != null) 'route_CreatedDate': routeCreatedDate,
      if (routeModifiedDate != null) 'route_ModifiedDate': routeModifiedDate,
    };
  }

  RouteListItem copyWith({
    int? routeId,
    int? routeCompId,
    int? routeBranchId,
    String? routeName,
    String? routeDescription,
    bool? routeIsActive,
    int? routeCreatedBy,
    int? routeModifiedBy,
    String? routeCreatedDate,
    String? routeModifiedDate,
  }) {
    return RouteListItem(
      routeId: routeId ?? this.routeId,
      routeCompId: routeCompId ?? this.routeCompId,
      routeBranchId: routeBranchId ?? this.routeBranchId,
      routeName: routeName ?? this.routeName,
      routeDescription: routeDescription ?? this.routeDescription,
      routeIsActive: routeIsActive ?? this.routeIsActive,
      routeCreatedBy: routeCreatedBy ?? this.routeCreatedBy,
      routeModifiedBy: routeModifiedBy ?? this.routeModifiedBy,
      routeCreatedDate: routeCreatedDate ?? this.routeCreatedDate,
      routeModifiedDate: routeModifiedDate ?? this.routeModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteListItem &&
          runtimeType == other.runtimeType &&
          routeId == other.routeId;

  @override
  int get hashCode => routeId.hashCode;

  @override
  String toString() => routeName;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString().split('.').first) ?? 0;
}

class RouteListResponse {
  final bool status;
  final String message;
  final List<RouteListItem> data;
  final String? error;

  RouteListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory RouteListResponse.fromJson(Map<String, dynamic> json) {
    List<RouteListItem> routeList = [];
    if (json['data'] != null && json['data'] is List) {
      routeList = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => RouteListItem.fromJson(item))
          .toList();
    }

    return RouteListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: routeList,
      error: json['error']?.toString(),
    );
  }
}

class RouteUpsertRequest {
  final int routeId;
  final int routeCompId;
  final int routeBranchId;
  final String routeName;
  final String routeDescription;
  final bool routeIsActive;
  final int routeCreatedBy;
  final int routeModifiedBy;

  RouteUpsertRequest({
    this.routeId = 0,
    this.routeCompId = 0,
    this.routeBranchId = 0,
    required this.routeName,
    this.routeDescription = '',
    this.routeIsActive = true,
    this.routeCreatedBy = 0,
    this.routeModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'route_Id': routeId,
      'route_CompId': routeCompId,
      'route_BranchId': routeBranchId,
      'route_Name': routeName.trim(),
      'route_Description': routeDescription.trim(),
      'route_IsActive': routeIsActive,
      'route_CreatedBy': routeCreatedBy,
      'route_ModifiedBy': routeModifiedBy,
    };
  }
}

class RouteUpsertResultData {
  final bool status;
  final String message;
  final int routeId;

  RouteUpsertResultData({
    required this.status,
    required this.message,
    required this.routeId,
  });

  factory RouteUpsertResultData.fromJson(Map<String, dynamic> json) {
    return RouteUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      routeId: int.tryParse(json['route_Id']?.toString() ?? '0') ?? 0,
    );
  }
}

class RouteUpsertResponse {
  final bool status;
  final String message;
  final RouteUpsertResultData? data;
  final String? error;

  RouteUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory RouteUpsertResponse.fromJson(Map<String, dynamic> json) {
    RouteUpsertResultData? resultData;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      resultData = RouteUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return RouteUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: resultData,
      error: json['error']?.toString(),
    );
  }
}
