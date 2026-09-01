import 'package:flutter/foundation.dart';
import '../models/batch.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class BatchService extends ChangeNotifier {
  // Singleton pattern
  static final BatchService _instance = BatchService._internal();
  factory BatchService() => _instance;
  BatchService._internal();

  List<BatchListItem> _batches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BatchListItem> get batches => List.unmodifiable(_batches);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<BatchListItem>> getAllBatches({
    int? compId,
    int? branchId,
    int? productId,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanSearch = (search == null || search == 'null') ? '' : search.trim();
    final effectiveBranchId = (branchId != null && branchId > 0)
        ? branchId
        : (sessionService.selectedBranchId ?? 0);
    final effectiveCompId = (compId != null && compId > 0)
        ? compId
        : (sessionService.selectedCompId ?? 0);

    final Map<String, String> queryParameters = {
      if (effectiveCompId > 0) 'CompId': effectiveCompId.toString(),
      if (effectiveBranchId > 0) 'BranchId': effectiveBranchId.toString(),
      if (productId != null && productId > 0) 'ProductId': productId.toString(),
      if (cleanSearch.isNotEmpty) 'Search': cleanSearch,
    };

    debugPrint(
      '📦 [BatchService.getAllBatches] Requesting with query parameters: $queryParameters',
    );

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllBatchesEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final batchResponse = BatchListResponse.fromJson(response);
        if (batchResponse.status || batchResponse.data.isNotEmpty) {
          _batches = batchResponse.data;
        } else if (response['data'] is List) {
          _batches = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => BatchListItem.fromJson(e))
              .toList();
        } else {
          _batches = [];
          _errorMessage = batchResponse.message.isNotEmpty
              ? batchResponse.message
              : 'No batches found.';
        }
      } else if (response is List) {
        _batches = response
            .whereType<Map<String, dynamic>>()
            .map((e) => BatchListItem.fromJson(e))
            .toList();
      } else {
        _batches = [];
      }

      _errorMessage = null;
      return _batches;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _batches = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching batches: $e';
      _batches = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _batches = [];
    _errorMessage = null;
    notifyListeners();
  }
}

// Global instance for convenience
final batchService = BatchService();
