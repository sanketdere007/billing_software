class CategoryListItem {
  final int catId;
  final String catName;
  final String catDescription;
  final bool catIsActive;
  final int catCreatedBy;
  final int catModifiedBy;
  final DateTime? catCreatedDate;
  final DateTime? catModifiedDate;

  const CategoryListItem({
    required this.catId,
    required this.catName,
    required this.catDescription,
    this.catIsActive = true,
    required this.catCreatedBy,
    required this.catModifiedBy,
    this.catCreatedDate,
    this.catModifiedDate,
  });

  factory CategoryListItem.fromJson(Map<String, dynamic> json) {
    return CategoryListItem(
      catId: int.tryParse(json['cat_Id']?.toString() ?? '0') ?? 0,
      catName: json['cat_Name']?.toString() ?? '',
      catDescription: json['cat_Description']?.toString() ?? '',
      catIsActive: json['cat_IsActive'] == true || json['cat_IsActive'] == 'true' || json['cat_IsActive'] == 1,
      catCreatedBy: int.tryParse(json['cat_CreatedBy']?.toString() ?? '0') ?? 0,
      catModifiedBy: int.tryParse(json['cat_ModifiedBy']?.toString() ?? '0') ?? 0,
      catCreatedDate: json['cat_CreatedDate'] != null ? DateTime.tryParse(json['cat_CreatedDate'].toString()) : null,
      catModifiedDate: json['cat_ModifiedDate'] != null ? DateTime.tryParse(json['cat_ModifiedDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cat_Id': catId,
      'cat_Name': catName,
      'cat_Description': catDescription,
      'cat_IsActive': catIsActive,
      'cat_CreatedBy': catCreatedBy,
      'cat_ModifiedBy': catModifiedBy,
      if (catCreatedDate != null) 'cat_CreatedDate': catCreatedDate?.toIso8601String(),
      if (catModifiedDate != null) 'cat_ModifiedDate': catModifiedDate?.toIso8601String(),
    };
  }

  CategoryListItem copyWith({
    int? catId,
    String? catName,
    String? catDescription,
    bool? catIsActive,
    int? catCreatedBy,
    int? catModifiedBy,
    DateTime? catCreatedDate,
    DateTime? catModifiedDate,
  }) {
    return CategoryListItem(
      catId: catId ?? this.catId,
      catName: catName ?? this.catName,
      catDescription: catDescription ?? this.catDescription,
      catIsActive: catIsActive ?? this.catIsActive,
      catCreatedBy: catCreatedBy ?? this.catCreatedBy,
      catModifiedBy: catModifiedBy ?? this.catModifiedBy,
      catCreatedDate: catCreatedDate ?? this.catCreatedDate,
      catModifiedDate: catModifiedDate ?? this.catModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryListItem &&
          runtimeType == other.runtimeType &&
          catId == other.catId;

  @override
  int get hashCode => catId.hashCode;

  @override
  String toString() => catName;
}

class CategoryListResponse {
  final bool status;
  final String message;
  final List<CategoryListItem> data;
  final String? error;

  CategoryListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory CategoryListResponse.fromJson(Map<String, dynamic> json) {
    List<CategoryListItem> list = [];
    if (json['data'] != null && json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => CategoryListItem.fromJson(item))
          .toList();
    }

    return CategoryListResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: list,
      error: json['error']?.toString(),
    );
  }
}

class CategoryUpsertRequest {
  final int catId;
  final String catName;
  final String catDescription;
  final bool catIsActive;
  final int catCreatedBy;
  final int catModifiedBy;

  CategoryUpsertRequest({
    this.catId = 0,
    required this.catName,
    this.catDescription = '',
    this.catIsActive = true,
    this.catCreatedBy = 0,
    this.catModifiedBy = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'cat_Id': catId,
      'cat_Name': catName.trim(),
      'cat_Description': catDescription.trim(),
      'cat_IsActive': catIsActive,
      'cat_CreatedBy': catCreatedBy,
      'cat_ModifiedBy': catModifiedBy,
    };
  }
}

class CategoryUpsertResultData {
  final bool status;
  final String message;
  final int catId;

  CategoryUpsertResultData({
    required this.status,
    required this.message,
    required this.catId,
  });

  factory CategoryUpsertResultData.fromJson(Map<String, dynamic> json) {
    return CategoryUpsertResultData(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      catId: int.tryParse(json['cat_Id']?.toString() ?? '0') ?? 0,
    );
  }
}

class CategoryUpsertResponse {
  final bool status;
  final String message;
  final CategoryUpsertResultData? data;
  final String? error;

  CategoryUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory CategoryUpsertResponse.fromJson(Map<String, dynamic> json) {
    CategoryUpsertResultData? dataObj;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataObj = CategoryUpsertResultData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return CategoryUpsertResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: dataObj,
      error: json['error']?.toString(),
    );
  }
}
