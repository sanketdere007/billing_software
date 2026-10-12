import 'package:flutter/foundation.dart';
import '../models/batch_wise_stock_report.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class BatchWiseStockReportService {
  static final BatchWiseStockReportService _instance =
      BatchWiseStockReportService._internal();
  factory BatchWiseStockReportService() => _instance;
  BatchWiseStockReportService._internal();

  Future<BatchWiseStockReportResponse> getBatchWiseStockReport({
    int? compId,
    int? branchId,
    int? productId,
    String? search,
    bool? onlyInStock,
    int pageNumber = 1,
    int pageSize = 30,
  }) async {
    final effectiveCompId = compId ?? sessionService.selectedCompId ?? 0;
    final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 0;

    final Map<String, String> queryParameters = {
      'CompId': effectiveCompId.toString(),
      'BranchId': effectiveBranchId.toString(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    if (productId != null && productId > 0) {
      queryParameters['ProductId'] = productId.toString();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['Search'] = search.trim();
    }
    if (onlyInStock != null) {
      queryParameters['OnlyInStock'] = onlyInStock.toString();
    }

    debugPrint(
      '📊 [BatchWiseStockReportService.getBatchWiseStockReport] Requesting with: $queryParameters',
    );

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getBatchWiseStockReportEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final reportResponse = BatchWiseStockReportResponse.fromJson(response);
        if (reportResponse.status) {
          return reportResponse;
        } else {
          throw ApiException(
            reportResponse.message.isNotEmpty
                ? reportResponse.message
                : 'Failed to fetch batch wise stock report',
          );
        }
      }
      throw ApiException('Invalid response format');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error fetching batch wise stock report: $e');
    }
  }
}

final batchWiseStockReportService = BatchWiseStockReportService();
