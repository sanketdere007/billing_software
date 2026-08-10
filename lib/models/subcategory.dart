class SubCategoryListItem {
  final int subCatId;
  final int subCatCatId;
  final String subCatName;
  final String subCatDescription;
  final bool subCatIsActive;
  final int subCatCreatedBy;
  final int subCatModifiedBy;
  final String catName;
  final DateTime? subCatCreatedDate;
  final DateTime? subCatModifiedDate;

  const SubCategoryListItem({
    required this.subCatId,
    required this.subCatCatId,
    required this.subCatName,
    required this.subCatDescription,
    this.subCatIsActive = true,
    required this.subCatCreatedBy,
    required this.subCatModifiedBy,
    required this.catName,
    this.subCatCreatedDate,
    this.subCatModifiedDate,
  });

  factory SubCategoryListItem.fromJson(Map<String, dynamic> json) {
    return SubCategoryListItem(
      subCatId: int.tryParse(json['subCat_Id']?.toString() ?? '0') ?? 0,
      subCatCatId: int.tryParse(json['subCat_CatId']?.toString() ?? '0') ?? 0,
      subCatName: json['subCat_Name']?.toString() ?? '',
      subCatDescription: json['subCat_Description']?.toString() ?? '',
      subCatIsActive: json['subCat_IsActive'] == true || json['subCat_IsActive'] == 'true' || json['subCat_IsActive'] == 1,
      subCatCreatedBy: int.tryParse(json['subCat_CreatedBy']?.toString() ?? '0') ?? 0,
      subCatModifiedBy: int.tryParse(json['subCat_ModifiedBy']?.toString() ?? '0') ?? 0,
      catName: json['cat_Name']?.toString() ?? '',
      subCatCreatedDate: json['subCat_CreatedDate'] != null ? DateTime.tryParse(json['subCat_CreatedDate'].toString()) : null,
      subCatModifiedDate: json['subCat_ModifiedDate'] != null ? DateTime.tryParse(json['subCat_ModifiedDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subCat_Id': subCatId,
      'subCat_CatId': subCatCatId,
      'subCat_Name': subCatName,
      'subCat_Description': subCatDescription,
      'subCat_IsActive': subCatIsActive,
      'subCat_CreatedBy': subCatCreatedBy,
      'subCat_ModifiedBy': subCatModifiedBy,
      'cat_Name': catName,
      if (subCatCreatedDate != null) 'subCat_CreatedDate': subCatCreatedDate?.toIso8601String(),
      if (subCatModifiedDate != null) 'subCat_ModifiedDate': subCatModifiedDate?.toIso8601String(),
    };
  }

  SubCategoryListItem copyWith({
    int? subCatId,
    int? subCatCatId,
    String? subCatName,
    String? subCatDescription,
    bool? subCatIsActive,
    int? subCatCreatedBy,
    int? subCatModifiedBy,
    String? catName,
    DateTime? subCatCreatedDate,
    DateTime? subCatModifiedDate,
  }) {
    return SubCategoryListItem(
      subCatId: subCatId ?? this.subCatId,
      subCatCatId: subCatCatId ?? this.subCatCatId,
      subCatName: subCatName ?? this.subCatName,
      subCatDescription: subCatDescription ?? this.subCatDescription,
      subCatIsActive: subCatIsActive ?? this.subCatIsActive,
      subCatCreatedBy: subCatCreatedBy ?? this.subCatCreatedBy,
      subCatModifiedBy: subCatModifiedBy ?? this.subCatModifiedBy,
      catName: catName ?? this.catName,
      subCatCreatedDate: subCatCreatedDate ?? this.subCatCreatedDate,
      subCatModifiedDate: subCatModifiedDate ?? this.subCatModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubCategoryListItem &&
          runtimeType == other.runtimeType &&
          subCatId == other.subCatId;

  @override
  int get hashCode => subCatId.hashCode;

  @override
  String toString() => subCatName;
}

class SubCategoryListResponse {
  final bool status;
  final String message;
  final List<SubCategoryListItem> data;
  final String? error;

  SubCategoryListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory SubCategoryListResponse.fromJson(Map<String, dynamic> json) {
    List<SubCategoryListItem> list = [];
    if (json['data'] != null && json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => SubCategoryListItem.fromJson(item))
          .toList();
    }

    return SubCategoryListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: list,
      error: json['error']?.toString(),
    );
  }
}

class SubCategoryUpsertRequest {
  final int subCatId;
  final int subCatCatId;
  final String subCatName;
  final String subCatDescription;
  final bool subCatIsActive;
  final int subCatCreatedBy;
  final int subCatModifiedBy;

  SubCategoryUpsertRequest({
    this.subCatId = 0,
    required this.subCatCatId,
    required this.subCatName,
    this.subCatDescription = '',
    this.subCatIsActive = true,
    this.subCatCreatedBy = 0,
    this.subCatModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'subCat_Id': subCatId,
      'subCat_CatId': subCatCatId,
      'subCat_Name': subCatName.trim(),
      'subCat_Description': subCatDescription.trim(),
      'subCat_IsActive': subCatIsActive,
      'subCat_CreatedBy': subCatCreatedBy,
      'subCat_ModifiedBy': subCatModifiedBy,
    };
  }
}

class SubCategoryUpsertResultData {
  final bool status;
  final String message;
  final int subCatId;

  SubCategoryUpsertResultData({
    required this.status,
    required this.message,
    required this.subCatId,
  });

  factory SubCategoryUpsertResultData.fromJson(Map<String, dynamic> json) {
    return SubCategoryUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      subCatId: int.tryParse(json['subCat_Id']?.toString() ?? '0') ?? 0,
    );
  }
}

class SubCategoryUpsertResponse {
  final bool status;
  final String message;
  final SubCategoryUpsertResultData? data;
  final String? error;

  SubCategoryUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory SubCategoryUpsertResponse.fromJson(Map<String, dynamic> json) {
    SubCategoryUpsertResultData? dataObj;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataObj = SubCategoryUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return SubCategoryUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}
