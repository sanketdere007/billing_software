import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class SupplierService extends ChangeNotifier {
  static final SupplierService _instance = SupplierService._internal();
  factory SupplierService() => _instance;
  SupplierService._internal();

  List<SupplierListItem> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SupplierListItem> get suppliers => List.unmodifiable(_suppliers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all Suppliers
  Future<List<SupplierListItem>> getAllSuppliers({
    int? suppId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};

    if (suppId != null && suppId > 0) {
      queryParameters['Supp_Id'] = suppId.toString();
    }
    if (isActive != null) {
      queryParameters['Supp_IsActive'] = isActive.toString();
    }

    debugPrint('🏢 [SupplierService.getAllSuppliers] Requesting with parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllSuppliersEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final suppResponse = SupplierListResponse.fromJson(response);
        if (suppResponse.status || suppResponse.data.isNotEmpty) {
          _suppliers = suppResponse.data;
        } else if (response['data'] is List) {
          _suppliers = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => SupplierListItem.fromJson(e))
              .toList();
        } else {
          _suppliers = [];
          _errorMessage = suppResponse.message.isNotEmpty
              ? suppResponse.message
              : 'Failed to fetch suppliers.';
        }
      } else if (response is List) {
        _suppliers = response
            .whereType<Map<String, dynamic>>()
            .map((e) => SupplierListItem.fromJson(e))
            .toList();
      } else {
        _suppliers = [];
      }

      _errorMessage = null;
      return _suppliers;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _suppliers = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching suppliers: $e';
      _suppliers = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Insert or update Supplier
  Future<SupplierUpsertResponse> insertOrUpdateSupplier(SupplierUpsertRequest request) async {
    int createdBy = request.suppCreatedBy;
    int modifiedBy = request.suppModifiedBy;
    int compId = request.suppCompId;
    int branchId = request.suppBranchId;

    // Resolve current user empId and session comp/branch if not set
    try {
      final user = await sessionService.getUserData();
      final currentEmpId = user?.empId ?? 0;
      if (createdBy == 0) createdBy = currentEmpId;
      if (modifiedBy == 0) modifiedBy = currentEmpId;
      
      if (compId == 0) compId = sessionService.selectedCompId ?? 0;
      if (branchId == 0) branchId = sessionService.selectedBranchId ?? 0;
    } catch (_) {}

    final finalRequest = SupplierUpsertRequest(
      suppId: request.suppId,
      suppCode: request.suppCode,
      suppName: request.suppName,
      suppCompanyName: request.suppCompanyName,
      suppMobileNo: request.suppMobileNo,
      suppAlternateMobileNo: request.suppAlternateMobileNo,
      suppEmail: request.suppEmail,
      suppGSTNo: request.suppGSTNo,
      suppPANNo: request.suppPANNo,
      suppAddress: request.suppAddress,
      suppAreaId: request.suppAreaId,
      suppCityId: request.suppCityId,
      suppStateId: request.suppStateId,
      suppPincode: request.suppPincode,
      suppCountry: request.suppCountry,
      suppPaymentTerms: request.suppPaymentTerms,
      suppCreditLimit: request.suppCreditLimit,
      suppCreditDays: request.suppCreditDays,
      suppIsActive: request.suppIsActive,
      suppCreatedBy: createdBy,
      suppModifiedBy: modifiedBy,
      suppCompId: compId,
      suppBranchId: branchId,
    );

    debugPrint('🏢 [SupplierService.insertOrUpdateSupplier] Request payload: ${finalRequest.toJson()}');

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateSupplierEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = SupplierUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save supplier.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving supplier: $e');
    }
  }

  /// Clear in-memory cached suppliers
  void clearCache() {
    _suppliers = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final supplierService = SupplierService();
