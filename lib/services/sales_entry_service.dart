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
}
