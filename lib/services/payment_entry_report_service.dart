import '../models/payment_entry_report.dart';
import 'api_service.dart';

class PaymentEntryReportService {
  final ApiService _apiService = ApiService();

  Future<PaymentEntryReportResponse> getPaymentEntryReport(
    PaymentEntryReportRequest request,
  ) async {
    final queryParams = <String, String>{};
    final json = request.toJson();
    json.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });

    final response = await _apiService.get(
      '/api/Report/PaymentEntryReport',
      queryParameters: queryParams,
      requiresAuth: true,
    );

    return PaymentEntryReportResponse.fromJson(response);
  }
}

final paymentEntryReportService = PaymentEntryReportService();
