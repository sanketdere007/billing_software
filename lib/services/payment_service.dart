import '../models/payment.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class PaymentService {
  Future<PaymentUpsertResponse> insertOrUpdatePayment(
    PaymentUpsertRequest request,
  ) async {
    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdatePaymentEndpoint,
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      return PaymentUpsertResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to save payment: $e');
    }
  }
}

final paymentService = PaymentService();
