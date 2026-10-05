import 'package:flutter/foundation.dart';
import '../models/outstanding_receivable_report.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  Future<OutstandingReceivableReportResponse> getOutstandingReceivableReport({
    int? compId,
    int? branchId,
    String? fromDate,
    String? toDate,
    String? search,
    int? customerId,
    int? routeId,
    int? areaId,
    int? cityId,
    int? stateId,
    bool? onlyOutstanding,
  }) async {
    final effectiveCompId = compId ?? sessionService.selectedCompId ?? 1;
    final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 1;

    final Map<String, String> queryParameters = {
      'CompId': effectiveCompId.toString(),
      'BranchId': effectiveBranchId.toString(),
    };

    if (fromDate != null && fromDate.isNotEmpty) queryParameters['FromDate'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) queryParameters['ToDate'] = toDate;
    if (search != null && search.trim().isNotEmpty) queryParameters['Search'] = search.trim();
    if (customerId != null && customerId > 0) queryParameters['CustomerId'] = customerId.toString();
    if (routeId != null && routeId > 0) queryParameters['RouteId'] = routeId.toString();
    if (areaId != null && areaId > 0) queryParameters['AreaId'] = areaId.toString();
    if (cityId != null && cityId > 0) queryParameters['CityId'] = cityId.toString();
    if (stateId != null && stateId > 0) queryParameters['StateId'] = stateId.toString();
    if (onlyOutstanding != null) queryParameters['OnlyOutstanding'] = onlyOutstanding.toString();

    debugPrint('📊 [ReportService.getOutstandingReceivableReport] Requesting with: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getOutstandingReceivableReportEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final reportResponse = OutstandingReceivableReportResponse.fromJson(response);
        if (reportResponse.status) {
          return reportResponse;
        } else {
          throw ApiException(reportResponse.message.isNotEmpty ? reportResponse.message : 'Failed to fetch outstanding receivable report');
        }
      }
      throw ApiException('Invalid response format');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error fetching outstanding receivable report: $e');
    }
  }
}

final reportService = ReportService();
