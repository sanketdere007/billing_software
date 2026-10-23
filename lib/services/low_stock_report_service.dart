import '../models/low_stock_report.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class LowStockReportService {
  static final LowStockReportService _instance =
      LowStockReportService._internal();
  factory LowStockReportService() => _instance;
  LowStockReportService._internal();

  final ApiService _apiService = apiService;

  Future<LowStockReportResponse> getLowStockReport({
    int? compId,
    int? branchId,
    double? lowStockQty,
    int? productId,
    String? search,
    int pageNumber = 1,
    int pageSize = 30,
  }) async {
    final effectiveCompId = compId ?? sessionService.selectedCompId ?? 0;
    final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 0;

    final request = LowStockReportRequest(
      compId: effectiveCompId,
      branchId: effectiveBranchId,
      lowStockQty: lowStockQty,
      productId: productId,
      search: search,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );

    final response = await _apiService.get(
      ApiConstants.getLowStockReportEndpoint,
      queryParameters: request.toQueryParameters(),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return LowStockReportResponse.fromJson(response);
    }

    throw ApiException('Invalid response format from server');
  }
}

final lowStockReportService = LowStockReportService();
