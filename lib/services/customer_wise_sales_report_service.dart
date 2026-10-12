import '../models/customer_wise_sales_report.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class CustomerWiseSalesReportService {
  final ApiService _apiService = ApiService();

  Future<CustomerWiseSalesReportResponse> getCustomerWiseSalesReport(
    CustomerWiseSalesReportRequest request,
  ) async {
    final response = await _apiService.get(
      ApiConstants.getCustomerWiseSalesReportEndpoint,
      queryParameters: request.toQueryParameters(),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return CustomerWiseSalesReportResponse.fromJson(response);
    }

    throw ApiException('Invalid response format from server');
  }
}

final customerWiseSalesReportService = CustomerWiseSalesReportService();
