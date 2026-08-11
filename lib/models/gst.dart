class GstTaxListItem {
  final int gstTaxId;
  final String gstTaxName;
  final double gstTaxPercentage;
  final double gstTaxCgst;
  final double gstTaxSgst;
  final double gstTaxIgst;
  final bool gstTaxIsActive;
  final int gstTaxCreatedBy;
  final int gstTaxModifiedBy;
  final DateTime? gstTaxCreatedDate;
  final DateTime? gstTaxModifiedDate;

  GstTaxListItem({
    required this.gstTaxId,
    required this.gstTaxName,
    required this.gstTaxPercentage,
    required this.gstTaxCgst,
    required this.gstTaxSgst,
    required this.gstTaxIgst,
    required this.gstTaxIsActive,
    required this.gstTaxCreatedBy,
    required this.gstTaxModifiedBy,
    this.gstTaxCreatedDate,
    this.gstTaxModifiedDate,
  });

  factory GstTaxListItem.fromJson(Map<String, dynamic> json) {
    return GstTaxListItem(
      gstTaxId: json['gstTax_Id'] ?? 0,
      gstTaxName: json['gstTax_Name'] ?? '',
      gstTaxPercentage: (json['gstTax_Percentage'] ?? 0).toDouble(),
      gstTaxCgst: (json['gstTax_CGST'] ?? 0).toDouble(),
      gstTaxSgst: (json['gstTax_SGST'] ?? 0).toDouble(),
      gstTaxIgst: (json['gstTax_IGST'] ?? 0).toDouble(),
      gstTaxIsActive: json['gstTax_IsActive'] ?? true,
      gstTaxCreatedBy: json['gstTax_CreatedBy'] ?? 0,
      gstTaxModifiedBy: json['gstTax_ModifiedBy'] ?? 0,
      gstTaxCreatedDate: json['gstTax_CreatedDate'] != null
          ? DateTime.tryParse(json['gstTax_CreatedDate'])
          : null,
      gstTaxModifiedDate: json['gstTax_ModifiedDate'] != null
          ? DateTime.tryParse(json['gstTax_ModifiedDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gstTax_Id': gstTaxId,
      'gstTax_Name': gstTaxName,
      'gstTax_Percentage': gstTaxPercentage,
      'gstTax_CGST': gstTaxCgst,
      'gstTax_SGST': gstTaxSgst,
      'gstTax_IGST': gstTaxIgst,
      'gstTax_IsActive': gstTaxIsActive,
      'gstTax_CreatedBy': gstTaxCreatedBy,
      'gstTax_ModifiedBy': gstTaxModifiedBy,
      'gstTax_CreatedDate': gstTaxCreatedDate?.toIso8601String(),
      'gstTax_ModifiedDate': gstTaxModifiedDate?.toIso8601String(),
    };
  }
}

class GstTaxListResponse {
  final bool status;
  final String message;
  final List<GstTaxListItem> data;
  final String? error;

  GstTaxListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.error,
  });

  factory GstTaxListResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return GstTaxListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: dataList.map((e) => GstTaxListItem.fromJson(e)).toList(),
      error: json['error'],
    );
  }
}

class GstTaxUpsertRequest {
  final int gstTaxId;
  final String gstTaxName;
  final double gstTaxPercentage;
  final double gstTaxCgst;
  final double gstTaxSgst;
  final double gstTaxIgst;
  final bool gstTaxIsActive;
  final int gstTaxCreatedBy;
  final int gstTaxModifiedBy;

  GstTaxUpsertRequest({
    required this.gstTaxId,
    required this.gstTaxName,
    required this.gstTaxPercentage,
    required this.gstTaxCgst,
    required this.gstTaxSgst,
    required this.gstTaxIgst,
    required this.gstTaxIsActive,
    required this.gstTaxCreatedBy,
    required this.gstTaxModifiedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'gstTax_Id': gstTaxId,
      'gstTax_Name': gstTaxName,
      'gstTax_Percentage': gstTaxPercentage,
      'gstTax_CGST': gstTaxCgst,
      'gstTax_SGST': gstTaxSgst,
      'gstTax_IGST': gstTaxIgst,
      'gstTax_IsActive': gstTaxIsActive,
      'gstTax_CreatedBy': gstTaxCreatedBy,
      'gstTax_ModifiedBy': gstTaxModifiedBy,
    };
  }
}

class GstTaxUpsertResponseData {
  final bool status;
  final String message;
  final int gstTaxId;

  GstTaxUpsertResponseData({
    required this.status,
    required this.message,
    required this.gstTaxId,
  });

  factory GstTaxUpsertResponseData.fromJson(Map<String, dynamic> json) {
    return GstTaxUpsertResponseData(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      gstTaxId: json['gstTax_Id'] ?? 0,
    );
  }
}

class GstTaxUpsertResponse {
  final bool status;
  final String message;
  final GstTaxUpsertResponseData? data;
  final String? error;

  GstTaxUpsertResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory GstTaxUpsertResponse.fromJson(Map<String, dynamic> json) {
    return GstTaxUpsertResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? GstTaxUpsertResponseData.fromJson(json['data'])
          : null,
      error: json['error'],
    );
  }
}
