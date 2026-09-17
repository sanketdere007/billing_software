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

  Future<Map<String, dynamic>> deleteReceiptEntry(int id) async {
    final response = await _apiService.delete(
      '/api/ReceiptEntry/DeleteReceiptEntry/$id',
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }
}

final collectionReportService = CollectionReportService();
