import 'package:flutter/foundation.dart';
import '../models/purchase_return.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class PurchaseReturnService extends ChangeNotifier {
  static final PurchaseReturnService _instance = PurchaseReturnService._internal();
  factory PurchaseReturnService() => _instance;
  PurchaseReturnService._internal();

  final List<PurchaseReturn> _returns = [];

  List<PurchaseReturn> get returns => List.unmodifiable(_returns);

  void initializeDummyData() {
    if (_returns.isEmpty) {
      _returns.addAll([
        PurchaseReturn(
          id: 'PR-001',
          returnNo: 'PRET-2023-001',
          returnDate: DateTime.now().subtract(const Duration(days: 1)),
          invoiceNo: 'PINV-2023-001',
          supplierId: 'SUP-001',
          supplierName: 'Apex Suppliers Ltd',
          products: [
            PurchaseReturnProduct(
              id: 'PRP-001',
              productId: 'PROD-001',
              productName: 'Raw Materials - Grade A',
              returnQuantity: 2,
              unit: 'KG',
              price: 1200,
              taxAmount: 432,
              refundAmount: 2832,
              returnReason: 'Quality mismatch',
            )
          ],
          totalReturnQuantity: 2,
          returnAmount: 2400,
          taxAdjustment: 432,
          grandRefund: 2832,
          refundMode: 'Bank',
          refundStatus: 'Completed',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addReturn(PurchaseReturn returnEntry) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _returns.add(returnEntry);
    notifyListeners();
  }

  Future<void> deleteReturn(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _returns.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<PurchaseReturnUpsertResponse> insertOrUpdatePurchaseReturnEntry(
    PurchaseReturnUpsertRequest request,
  ) async {
    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdatePurchaseReturnEntryEndpoint,
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = PurchaseReturnUpsertResponse.fromJson(response);

      if (upsertResponse.status ||
          (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save purchase return entry.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving purchase return entry: $e');
    }
  }

  Future<PurchaseReturnMasterViewResponse> getPurchaseReturnMasterViewList({
    int? compId,
    int? branchId,
    int purchaseReturnMasterId = 0,
    int supplierId = 0,
    String search = "",
    required String fromDate,
    required String toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final effectiveCompId = compId ?? sessionService.selectedCompId ?? 1;
      final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 1;

      final requestBody = {
        "compId": effectiveCompId,
        "branchId": effectiveBranchId,
        "purchaseReturnMaster_Id": purchaseReturnMasterId,
        "supplierId": supplierId,
        "search": search,
        "searchText": search,
        "fromDate": fromDate,
        "toDate": toDate,
        "page": page,
        "pageNumber": page,
        "pageSize": pageSize,
      };

      dynamic response;
      try {
        response = await apiService.post(
          ApiConstants.getPurchaseReturnMasterViewListEndpoint,
          body: requestBody,
          requiresAuth: true,
        );
      } on ApiException catch (apiErr) {
        if (apiErr.statusCode == 404 || apiErr.statusCode == 405) {
          response = await apiService.get(
            ApiConstants.getPurchaseReturnMasterViewListEndpoint,
            queryParameters: {
              "compId": effectiveCompId.toString(),
              "branchId": effectiveBranchId.toString(),
              "purchaseReturnMaster_Id": purchaseReturnMasterId.toString(),
              "supplierId": supplierId.toString(),
              "search": search,
              "fromDate": fromDate,
              "toDate": toDate,
              "page": page.toString(),
              "pageSize": pageSize.toString(),
            },
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

      final masterResponse = PurchaseReturnMasterViewResponse.fromJson(jsonMap);

      if (masterResponse.status) {
        return masterResponse;
      } else {
        throw ApiException(
          masterResponse.message.isNotEmpty
              ? masterResponse.message
              : 'Failed to fetch purchase return master list.',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error fetching purchase return master list: $e');
    }
  }

  Future<List<PurchaseReturnDetailViewItem>> getPurchaseReturnDetailViewList(
    int masterId, {
    int? compId,
    int? branchId,
  }) async {
    try {
      final effectiveCompId = compId ?? sessionService.selectedCompId ?? 1;
      final effectiveBranchId = branchId ?? sessionService.selectedBranchId ?? 1;

      final requestBody = {
        "purchaseReturnMaster_Id": masterId,
        "purchaseReturnMasterId": masterId,
        "masterId": masterId,
        "compId": effectiveCompId,
        "branchId": effectiveBranchId,
      };

      dynamic response;
      try {
        response = await apiService.post(
          ApiConstants.getPurchaseReturnDetailViewListEndpoint,
          body: requestBody,
          requiresAuth: true,
        );
      } on ApiException catch (apiErr) {
        if (apiErr.statusCode == 404 || apiErr.statusCode == 405) {
          try {
            response = await apiService.get(
              '${ApiConstants.getPurchaseReturnDetailViewListEndpoint}/$masterId',
              requiresAuth: true,
            );
          } catch (_) {
            response = await apiService.get(
              ApiConstants.getPurchaseReturnDetailViewListEndpoint,
              queryParameters: {
                "purchaseReturnMaster_Id": masterId.toString(),
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

      final detailResponse = PurchaseReturnDetailViewResponse.fromJson(jsonMap);

      if (detailResponse.status) {
        return detailResponse.data;
      } else {
        throw ApiException(
          detailResponse.message.isNotEmpty
              ? detailResponse.message
              : 'Failed to fetch purchase return details.',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error fetching purchase return detail list: $e');
    }
  }
}

final purchaseReturnService = PurchaseReturnService();
