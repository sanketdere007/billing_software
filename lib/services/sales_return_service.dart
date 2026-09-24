import 'package:flutter/foundation.dart';
import '../models/sales_return.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class SalesReturnService extends ChangeNotifier {
  static final SalesReturnService _instance = SalesReturnService._internal();
  factory SalesReturnService() => _instance;
  SalesReturnService._internal();

  Future<SalesReturnUpsertResponse> insertOrUpdateSalesReturnEntry(
    SalesReturnUpsertRequest request,
  ) async {
    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateSalesReturnEntryEndpoint,
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = SalesReturnUpsertResponse.fromJson(response);

      if (upsertResponse.status ||
          (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save sales return entry.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving sales return entry: $e');
    }
  }

  Future<SalesReturnMasterListResponse> getSalesReturnList({
    required int compId,
    required int branchId,
    int? customerId,
    String? fromDate,
    String? toDate,
    String search = '',
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final body = {
        "compId": compId,
        "branchId": branchId,
        "customerId": customerId ?? 0,
        "fromDate": fromDate,
        "toDate": toDate,
        "search": search,
        "pageNumber": pageNumber,
        "pageSize": pageSize,
      };

      final dynamic response = await apiService.post(
        ApiConstants.getSalesReturnListEndpoint,
        body: body,
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final listResponse = SalesReturnMasterListResponse.fromJson(response);

      if (listResponse.status) {
        return listResponse;
      } else {
        throw ApiException(listResponse.message.isNotEmpty
            ? listResponse.message
            : 'Failed to load sales return entries.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error loading sales return entries: $e');
    }
  }

  Future<void> deleteSalesReturnApi(int salesReturnMasterId) async {
    try {
      final endpoint = '${ApiConstants.deleteSalesReturnEntryEndpoint}/$salesReturnMasterId';
      final dynamic response = await apiService.delete(
        endpoint,
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      if (response['status'] == true) {
        return;
      } else {
        throw ApiException(response['message']?.toString() ?? 'Failed to delete sales return entry.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error deleting sales return entry: $e');
    }
  }

  Future<SalesReturnDetailListResponse> getSalesReturnDetailList(int salesReturnMasterId) async {
    try {
      final endpoint = '${ApiConstants.getSalesReturnDetailListEndpoint}/$salesReturnMasterId';
      final dynamic response = await apiService.get(
        endpoint,
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final detailListResponse = SalesReturnDetailListResponse.fromJson(response);
      
      if (!detailListResponse.status) {
        throw ApiException(detailListResponse.message.isNotEmpty 
            ? detailListResponse.message 
            : 'Failed to load sales return details.');
      }
      
      return detailListResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error loading sales return details: $e');
    }
  }
}
