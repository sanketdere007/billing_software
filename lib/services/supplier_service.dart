import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../models/supplier_reports.dart';
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
    int? pageNumber,
    int? pageSize,
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
    if (pageNumber != null) {
      queryParameters['PageNumber'] = pageNumber.toString();
    }
    if (pageSize != null) {
      queryParameters['PageSize'] = pageSize.toString();
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

  /// Fetch Supplier Outstanding Report
  Future<List<SupplierOutstandingReportItem>> getSupplierOutstandingReport({
    int compId = 0,
    int branchId = 0,
    int ledgerId = 0,
    int supplierId = 0,
    String search = '',
    bool isActive = true,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {
      if (compId > 0) 'CompId': compId.toString(),
      if (branchId > 0) 'BranchId': branchId.toString(),
      if (ledgerId > 0) 'LedgerId': ledgerId.toString(),
      if (supplierId > 0) 'SupplierId': supplierId.toString(),
      if (search.isNotEmpty) 'Search': search,
      'IsActive': isActive.toString(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    debugPrint('🏢 [SupplierService.getSupplierOutstandingReport] Requesting with parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getSupplierOutstandingReportEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final repResponse = SupplierOutstandingReportResponse.fromJson(response);
        if (repResponse.status || repResponse.data.isNotEmpty) {
          return repResponse.data;
        } else {
          _errorMessage = repResponse.message.isNotEmpty
              ? repResponse.message
              : 'Failed to fetch outstanding report.';
          return [];
        }
      }
      return [];
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching outstanding report: $e';
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch Supplier Pending Invoice Report
  Future<List<SupplierPendingInvoiceItem>> getSupplierPendingInvoice({
    int supplierId = 0,
    int compId = 0,
    int branchId = 0,
    int ledgerId = 0,
    String search = '',
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {
      if (supplierId > 0) 'SupplierId': supplierId.toString(),
      if (compId > 0) 'CompId': compId.toString(),
      if (branchId > 0) 'BranchId': branchId.toString(),
      if (ledgerId > 0) 'LedgerId': ledgerId.toString(),
      if (search.isNotEmpty) 'Search': search,
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    debugPrint('🏢 [SupplierService.getSupplierPendingInvoice] Requesting with parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getSupplierPendingInvoiceEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final repResponse = SupplierPendingInvoiceResponse.fromJson(response);
        if (repResponse.status || repResponse.data.isNotEmpty) {
          return repResponse.data;
        } else {
          _errorMessage = repResponse.message.isNotEmpty
              ? repResponse.message
              : 'Failed to fetch pending invoices.';
          return [];
        }
      }
      return [];
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching pending invoices: $e';
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
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
