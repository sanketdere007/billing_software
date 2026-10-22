import '../models/product_wise_purchase_report.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class ProductWisePurchaseReportService {
  static final ProductWisePurchaseReportService _instance =
      ProductWisePurchaseReportService._internal();
  factory ProductWisePurchaseReportService() => _instance;
  ProductWisePurchaseReportService._internal();

  final ApiService _apiService = apiService;

  Future<ProductWisePurchaseReportResponse> getProductWisePurchaseReport({
    required int compId,
    required int branchId,
    required DateTime fromDate,
    required DateTime toDate,
    int? productId,
    int? supplierId,
    String search = '',
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final request = ProductWisePurchaseReportRequest(
      compId: compId,
      branchId: branchId,
      fromDate: fromDate,
      toDate: toDate,
      productId: productId,
      supplierId: supplierId,
      search: search,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );

    final response = await _apiService.get(
      ApiConstants.getProductWisePurchaseReportEndpoint,
      queryParameters: request.toQueryParameters(),
    );

    if (response is Map<String, dynamic>) {
      return ProductWisePurchaseReportResponse.fromJson(response);
    }

    throw ApiException('Invalid response format from server');
  }
}

final productWisePurchaseReportService = ProductWisePurchaseReportService();
