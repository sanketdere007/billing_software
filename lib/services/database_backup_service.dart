import 'package:flutter/foundation.dart';
import '../models/database_backup.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class DatabaseBackupService extends ChangeNotifier {
  static final DatabaseBackupService _instance = DatabaseBackupService._internal();
  factory DatabaseBackupService() => _instance;
  DatabaseBackupService._internal();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DatabaseBackupData? _lastBackup;
  DatabaseBackupData? get lastBackup => _lastBackup;

  /// Call Database Backup API (`/api/DatabaseBackup/CreateDatabaseBackup`)
  Future<DatabaseBackupResponse> createBackup() async {
    _isLoading = true;
    notifyListeners();

    try {
      dynamic rawResponse;

      try {
        rawResponse = await apiService.post(
          ApiConstants.createDatabaseBackupEndpoint,
          requiresAuth: true,
          timeout: const Duration(minutes: 2),
        );
      } on ApiException catch (e) {
        // Fallback to GET if method not allowed (405)
        if (e.statusCode == 405) {
          rawResponse = await apiService.get(
            ApiConstants.createDatabaseBackupEndpoint,
            requiresAuth: true,
            timeout: const Duration(minutes: 2),
          );
        } else {
          rethrow;
        }
      }

      if (rawResponse is! Map<String, dynamic>) {
        throw ApiException('Unexpected response structure from server.');
      }

      final backupResponse = DatabaseBackupResponse.fromJson(rawResponse);

      if (!backupResponse.status) {
        final message = backupResponse.message.isNotEmpty
            ? backupResponse.message
            : 'Failed to create database backup.';
        throw ApiException(message);
      }

      if (backupResponse.data != null) {
        _lastBackup = backupResponse.data;
      }

      return backupResponse;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final databaseBackupService = DatabaseBackupService();
