/// Model representing the data payload of a database backup response
class DatabaseBackupData {
  final bool status;
  final String message;
  final String? backupFilePath;
  final String? fileName;
  final int? fileSizeBytes;
  final String? fileSizeFormatted;
  final String? createdAt;

  DatabaseBackupData({
    required this.status,
    required this.message,
    this.backupFilePath,
    this.fileName,
    this.fileSizeBytes,
    this.fileSizeFormatted,
    this.createdAt,
  });

  factory DatabaseBackupData.fromJson(Map<String, dynamic> json) {
    return DatabaseBackupData(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      backupFilePath: json['backupFilePath']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSizeBytes: json['fileSizeBytes'] is int
          ? json['fileSizeBytes'] as int
          : int.tryParse(json['fileSizeBytes']?.toString() ?? ''),
      fileSizeFormatted: json['fileSizeFormatted']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'backupFilePath': backupFilePath,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'fileSizeFormatted': fileSizeFormatted,
      'createdAt': createdAt,
    };
  }
}

/// Root response model for `/api/DatabaseBackup/CreateDatabaseBackup`
class DatabaseBackupResponse {
  final bool status;
  final String message;
  final DatabaseBackupData? data;

  DatabaseBackupResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory DatabaseBackupResponse.fromJson(Map<String, dynamic> json) {
    return DatabaseBackupResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? DatabaseBackupData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}
