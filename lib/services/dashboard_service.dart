import 'package:flutter/foundation.dart';
import '../models/dashboard_charts_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class DashboardService extends ChangeNotifier {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  DashboardChartsData? _chartsData;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardChartsData? get chartsData => _chartsData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch dashboard charts data from `/api/Dashboard/GetCharts`
  /// Query parameters:
  /// - `CompId` (int)
  /// - `BranchId` (int)
  /// - `FromDate` (date-time string)
  /// - `ToDate` (date-time string)
  /// - `TopProducts` (int)
  Future<DashboardChartsData> getCharts({
    int? compId,
    int? branchId,
    DateTime? fromDate,
    DateTime? toDate,
    int topProducts = 5,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final effectiveCompId = compId ?? sessionService.selectedCompId ?? 0;
      final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 0;

      final now = DateTime.now();
      final effectiveFromDate = fromDate != null
          ? DateTime(fromDate.year, fromDate.month, fromDate.day, 0, 0, 0, 0)
          : DateTime(now.year, now.month, 1, 0, 0, 0, 0);

      final effectiveToDate = toDate != null
          ? DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999)
          : DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final Map<String, String> queryParameters = {
        'CompId': effectiveCompId.toString(),
        'BranchId': effectiveBranchId.toString(),
        'FromDate': effectiveFromDate.toIso8601String(),
        'ToDate': effectiveToDate.toIso8601String(),
        'TopProducts': topProducts.toString(),
      };

      debugPrint('📊 [DashboardService.getCharts] Requesting with: $queryParameters');

      final dynamic response = await apiService.get(
        ApiConstants.getDashboardChartsEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        if (response['status'] == true || response['data'] != null) {
          if (response['data'] is Map<String, dynamic>) {
            _chartsData = DashboardChartsData.fromJson(
              response['data'] as Map<String, dynamic>,
            );
          } else {
            _chartsData = DashboardChartsData.fromJson(response);
          }
        } else {
          _errorMessage =
              response['message']?.toString() ??
              response['error']?.toString() ??
              'Failed to load charts data';
          _chartsData = DashboardChartsData();
        }
      } else {
        _chartsData = DashboardChartsData();
      }

      return _chartsData ?? DashboardChartsData();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('⚠️ [DashboardService.getCharts] ApiException: ${e.message}');
      _chartsData ??= DashboardChartsData();
      rethrow;
    } catch (e) {
      _errorMessage = 'Error loading charts: $e';
      debugPrint('⚠️ [DashboardService.getCharts] Error: $e');
      _chartsData ??= DashboardChartsData();
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear cached chart data
  void clearCache() {
    _chartsData = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

final dashboardService = DashboardService();
