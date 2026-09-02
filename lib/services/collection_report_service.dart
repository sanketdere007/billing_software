import '../models/collection_report.dart';
import 'api_service.dart';

class CollectionReportService {
  final ApiService _apiService = ApiService();

  Future<CollectionReportResponse> getCollectionReport(
    CollectionReportRequest request,
  ) async {
    final response = await _apiService.post(
      '/api/ReceiptEntry/CollectionReport',
      body: request.toJson(),
      requiresAuth: true,
    );

    return CollectionReportResponse.fromJson(response);
  }
}

final collectionReportService = CollectionReportService();
