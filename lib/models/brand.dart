class BrandListItem {
  final int brandId;
  final String brandName;
  final String brandDescription;
  final bool brandIsActive;
  final int brandCreatedBy;
  final int brandModifiedBy;
  final DateTime? brandCreatedDate;
  final DateTime? brandModifiedDate;

  const BrandListItem({
    required this.brandId,
    required this.brandName,
    required this.brandDescription,
    this.brandIsActive = true,
    required this.brandCreatedBy,
    required this.brandModifiedBy,
    this.brandCreatedDate,
    this.brandModifiedDate,
  });

  factory BrandListItem.fromJson(Map<String, dynamic> json) {
    return BrandListItem(
      brandId: int.tryParse(json['brand_Id']?.toString() ?? '0') ?? 0,
      brandName: json['brand_Name']?.toString() ?? '',
      brandDescription: json['brand_Description']?.toString() ?? '',
      brandIsActive: json['brand_IsActive'] == true || json['brand_IsActive'] == 'true' || json['brand_IsActive'] == 1,
      brandCreatedBy: int.tryParse(json['brand_CreatedBy']?.toString() ?? '0') ?? 0,
      brandModifiedBy: int.tryParse(json['brand_ModifiedBy']?.toString() ?? '0') ?? 0,
      brandCreatedDate: json['brand_CreatedDate'] != null ? DateTime.tryParse(json['brand_CreatedDate'].toString()) : null,
      brandModifiedDate: json['brand_ModifiedDate'] != null ? DateTime.tryParse(json['brand_ModifiedDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand_Id': brandId,
      'brand_Name': brandName,
      'brand_Description': brandDescription,
      'brand_IsActive': brandIsActive,
      'brand_CreatedBy': brandCreatedBy,
      'brand_ModifiedBy': brandModifiedBy,
      if (brandCreatedDate != null) 'brand_CreatedDate': brandCreatedDate?.toIso8601String(),
      if (brandModifiedDate != null) 'brand_ModifiedDate': brandModifiedDate?.toIso8601String(),
    };
  }

  BrandListItem copyWith({
    int? brandId,
    String? brandName,
    String? brandDescription,
    bool? brandIsActive,
    int? brandCreatedBy,
    int? brandModifiedBy,
    DateTime? brandCreatedDate,
    DateTime? brandModifiedDate,
  }) {
    return BrandListItem(
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      brandDescription: brandDescription ?? this.brandDescription,
      brandIsActive: brandIsActive ?? this.brandIsActive,
      brandCreatedBy: brandCreatedBy ?? this.brandCreatedBy,
      brandModifiedBy: brandModifiedBy ?? this.brandModifiedBy,
      brandCreatedDate: brandCreatedDate ?? this.brandCreatedDate,
      brandModifiedDate: brandModifiedDate ?? this.brandModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandListItem &&
          runtimeType == other.runtimeType &&
          brandId == other.brandId;

  @override
  int get hashCode => brandId.hashCode;

  @override
  String toString() => brandName;
}

class BrandListResponse {
  final bool status;
  final String message;
  final List<BrandListItem> data;
  final String? error;

  BrandListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory BrandListResponse.fromJson(Map<String, dynamic> json) {
    List<BrandListItem> list = [];
    if (json['data'] != null && json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => BrandListItem.fromJson(item))
          .toList();
    }

    return BrandListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: list,
      error: json['error']?.toString(),
    );
  }
}

class BrandUpsertRequest {
  final int brandId;
  final String brandName;
  final String brandDescription;
  final bool brandIsActive;
  final int brandCreatedBy;
  final int brandModifiedBy;

  BrandUpsertRequest({
    this.brandId = 0,
    required this.brandName,
    this.brandDescription = '',
    this.brandIsActive = true,
    this.brandCreatedBy = 0,
    this.brandModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'brand_Id': brandId,
      'brand_Name': brandName.trim(),
      'brand_Description': brandDescription.trim(),
      'brand_IsActive': brandIsActive,
      'brand_CreatedBy': brandCreatedBy,
      'brand_ModifiedBy': brandModifiedBy,
    };
  }
}

class BrandUpsertResultData {
  final bool status;
  final String message;
  final int brandId;

  BrandUpsertResultData({
    required this.status,
    required this.message,
    required this.brandId,
  });

  factory BrandUpsertResultData.fromJson(Map<String, dynamic> json) {
    return BrandUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      brandId: int.tryParse(json['brand_Id']?.toString() ?? '0') ?? 0,
    );
  }
}

class BrandUpsertResponse {
  final bool status;
  final String message;
  final BrandUpsertResultData? data;
  final String? error;

  BrandUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory BrandUpsertResponse.fromJson(Map<String, dynamic> json) {
    BrandUpsertResultData? dataObj;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataObj = BrandUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return BrandUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}
