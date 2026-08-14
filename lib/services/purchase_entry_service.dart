import 'package:flutter/foundation.dart';
import '../models/purchase_entry.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class PurchaseEntryService extends ChangeNotifier {
  static final PurchaseEntryService _instance = PurchaseEntryService._internal();
  factory PurchaseEntryService() => _instance;
  PurchaseEntryService._internal();

  final List<PurchaseEntry> _entries = [];

  List<PurchaseEntry> get entries => List.unmodifiable(_entries);

  void initializeDummyData() {
    if (_entries.isEmpty) {
      _entries.addAll([
        PurchaseEntry(
          id: 'PE-001',
          invoiceNo: 'PINV-2023-001',
          invoiceDate: DateTime.now().subtract(const Duration(days: 2)),
          supplierId: 'SUP-001',
          supplierName: 'Apex Suppliers Ltd',
          products: [
            PurchaseEntryProduct(
              id: 'PEP-001',
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
          amountPaid: 28320,
          balance: 0,
          status: 'Completed',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addEntry(PurchaseEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _entries.add(entry);
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<PurchaseEntryUpsertResponse> insertOrUpdatePurchaseEntry(
    PurchaseEntryUpsertRequest request,
  ) async {
    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdatePurchaseEntryEndpoint,
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = PurchaseEntryUpsertResponse.fromJson(response);

      if (upsertResponse.status ||
          (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save purchase entry.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving purchase entry: $e');
    }
  }
}

