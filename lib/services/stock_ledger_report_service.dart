import '../models/stock_ledger_report.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class StockLedgerReportService {
  static final StockLedgerReportService _instance =
      StockLedgerReportService._internal();
  factory StockLedgerReportService() => _instance;
  StockLedgerReportService._internal();

  final ApiService _apiService = apiService;

  Future<StockLedgerReportResponse> getStockLedgerReport({
    int? compId,
    int? branchId,
    required DateTime fromDate,
    required DateTime toDate,
    int? productId,
    int? batchId,
    String? transactionType,
    String? type,
    String? search,
    int pageNumber = 1,
    int pageSize = 30,
  }) async {
    final effectiveCompId = compId ?? sessionService.selectedCompId ?? 0;
    final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 0;

    final request = StockLedgerReportRequest(
      compId: effectiveCompId,
      branchId: effectiveBranchId,
      fromDate: fromDate,
      toDate: toDate,
      productId: productId,
      batchId: batchId,
      transactionType: transactionType,
      type: type,
      search: search,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );

    final response = await _apiService.get(
      ApiConstants.getStockLedgerReportEndpoint,
      queryParameters: request.toQueryParameters(),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return StockLedgerReportResponse.fromJson(response);
    }

    throw ApiException('Invalid response format from server');
  }
}

final stockLedgerReportService = StockLedgerReportService();
