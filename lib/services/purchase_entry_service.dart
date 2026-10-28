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

  Future<PurchaseMasterViewResponseData> getPurchaseMasterViewList({
    int? compId,
    int? branchId,
    int? supplierId,
    int pageNumber = 1,
    int pageSize = 20,
    String searchText = '',
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final effectiveCompId = compId ?? sessionService.selectedCompId ?? 1;
      final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 1;

      final body = {
        "compId": effectiveCompId,
        "branchId": effectiveBranchId,
        if (supplierId != null && supplierId > 0) "supplierId": supplierId,
        "search": searchText,
        "searchText": searchText,
        "fromDate": fromDate.toIso8601String(),
        "toDate": toDate.toIso8601String(),
        "page": pageNumber,
        "pageNumber": pageNumber,
        "pageSize": pageSize,
      };

      dynamic response;
      try {
        response = await apiService.post(
          ApiConstants.getPurchaseMasterViewListEndpoint,
          body: body,
          requiresAuth: true,
        );
      } on ApiException catch (apiErr) {
        if (apiErr.statusCode == 404 || apiErr.statusCode == 405) {
          final queryParams = {
            "compId": effectiveCompId.toString(),
            "branchId": effectiveBranchId.toString(),
            if (supplierId != null && supplierId > 0) "supplierId": supplierId.toString(),
            "search": searchText,
            "searchText": searchText,
            "fromDate": fromDate.toIso8601String(),
            "toDate": toDate.toIso8601String(),
            "page": pageNumber.toString(),
            "pageNumber": pageNumber.toString(),
            "pageSize": pageSize.toString(),
          };
          response = await apiService.get(
            ApiConstants.getPurchaseMasterViewListEndpoint,
            queryParameters: queryParams,
            requiresAuth: true,
          );
        } else {
          rethrow;
        }
      }

      final Map<String, dynamic> jsonMap;
      if (response is Map<String, dynamic>) {
        jsonMap = response;
      } else if (response is List) {
        jsonMap = <String, dynamic>{'status': true, 'data': response};
      } else {
        throw ApiException('Invalid response format from server.');
      }

      final viewResponse = PurchaseMasterViewResponse.fromJson(jsonMap);
      if (viewResponse.status && viewResponse.data != null) {
        return viewResponse.data!;
      } else {
        throw ApiException(
          viewResponse.message.isNotEmpty
              ? viewResponse.message
              : 'Failed to fetch purchase entries',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error fetching purchase entries: $e');
    }
  }

  Future<List<PurchaseDetailViewItem>> getPurchaseDetailViewList(
    int purchaseMasterId, {
    int? compId,
    int? branchId,
  }) async {
    try {
      final effectiveCompId = compId ?? sessionService.selectedCompId ?? 1;
      final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 1;

      dynamic response;
      try {
        response = await apiService.post(
          ApiConstants.getPurchaseDetailViewListEndpoint,
          body: {
            "purchaseMaster_Id": purchaseMasterId,
            "purchaseMasterId": purchaseMasterId,
            "masterId": purchaseMasterId,
            "compId": effectiveCompId,
            "branchId": effectiveBranchId,
          },
          requiresAuth: true,
        );
      } on ApiException catch (apiErr) {
        if (apiErr.statusCode == 404 || apiErr.statusCode == 405) {
          try {
            response = await apiService.get(
              '${ApiConstants.getPurchaseDetailViewListEndpoint}/$purchaseMasterId',
              requiresAuth: true,
            );
          } catch (_) {
            response = await apiService.get(
              ApiConstants.getPurchaseDetailViewListEndpoint,
              queryParameters: {
                "purchaseMaster_Id": purchaseMasterId.toString(),
                "purchaseMasterId": purchaseMasterId.toString(),
                "compId": effectiveCompId.toString(),
                "branchId": effectiveBranchId.toString(),
              },
              requiresAuth: true,
            );
          }
        } else {
          rethrow;
        }
      }

      final Map<String, dynamic> jsonMap;
      if (response is Map<String, dynamic>) {
        jsonMap = response;
      } else if (response is List) {
        jsonMap = <String, dynamic>{'status': true, 'data': response};
      } else {
        throw ApiException('Invalid response format from server.');
      }

      final detailResponse = PurchaseDetailViewResponse.fromJson(jsonMap);
      if (detailResponse.status) {
        return detailResponse.data;
      } else {
        throw ApiException(
          detailResponse.message.isNotEmpty
              ? detailResponse.message
              : 'Failed to fetch purchase details',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error fetching purchase details: $e');
    }
  }
}

final purchaseEntryService = PurchaseEntryService();
