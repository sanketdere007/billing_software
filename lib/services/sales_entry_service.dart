import 'package:flutter/foundation.dart';
import '../models/sales_entry.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class SalesEntryService extends ChangeNotifier {
  static final SalesEntryService _instance = SalesEntryService._internal();
  factory SalesEntryService() => _instance;
  SalesEntryService._internal();

  final List<SalesEntry> _entries = [];

  List<SalesEntry> get entries => List.unmodifiable(_entries);

  void initializeDummyData() {
    if (_entries.isEmpty) {
      _entries.addAll([
        SalesEntry(
          id: 'SE-001',
          invoiceNo: 'SINV-2023-001',
          invoiceDate: DateTime.now().subtract(const Duration(days: 2)),
          customerId: 'CUST-001',
          customerName: 'Acme Corp',
          products: [
            SalesEntryProduct(
              id: 'SEP-001',
              productId: 'PROD-001',
              productName: 'Raw Materials - Grade A',
              quantity: 20,
              unit: 'KG',
              price: 1200,
              taxAmount: 4320,
              total: 28320,
            )
          ],
          totalQuantity: 20,
          grossAmount: 24000,
          gst: 4320,
          grandTotal: 28320,
          payments: {'Bank': 28320},
          amountReceived: 28320,
          balance: 0,
          status: 'Completed',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addEntry(SalesEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _entries.add(entry);
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<SalesEntryUpsertResponse> insertOrUpdateSalesEntry(
    SalesEntryUpsertRequest request,
  ) async {
    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateSalesEntryEndpoint,
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = SalesEntryUpsertResponse.fromJson(response);

      if (upsertResponse.status ||
          (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save sales entry.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving sales entry: $e');
    }
  }

  Future<SalesMasterListResponse> getAllSalesMaster({
    int compId = 0,
    int branchId = 0,
    String? fromDate,
    String? toDate,
    String? search,
    int? customerId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'CompId': compId.toString(),
        'BranchId': branchId.toString(),
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };
      
      if (fromDate != null) queryParams['FromDate'] = fromDate;
      if (toDate != null) queryParams['ToDate'] = toDate;
      if (search != null && search.isNotEmpty) queryParams['Search'] = search;
      if (customerId != null) queryParams['CustomerId'] = customerId.toString();

      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.getAllSalesMasterEndpoint)
          .replace(queryParameters: queryParams);

      final dynamic response = await apiService.get(
        uri.toString().replaceFirst(ApiConstants.baseUrl, ''),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      return SalesMasterListResponse.fromJson(response);
    } catch (e) {
      throw ApiException('Error fetching sales master data: $e');
    }
  }

  Future<SalesDetailListResponse> getAllSalesDetail(int salesMasterId) async {
    try {
      final endpoint = '${ApiConstants.getAllSalesDetailEndpoint}/$salesMasterId';
      final dynamic response = await apiService.get(
        endpoint,
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      return SalesDetailListResponse.fromJson(response);
    } catch (e) {
      throw ApiException('Error fetching sales detail data: $e');
    }
  }
}
