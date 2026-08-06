import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

/// Service for managing Customer operations via backend API:
/// 1] GET `/api/Customer/GetAllCustomers`
/// 2] GET `/api/Customer/GetCustomerById/{Cust_Id}`
/// 3] POST `/api/Customer/InsertorUpdateCustomer`
class CustomerService extends ChangeNotifier {
  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  List<CustomerListItem> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerListItem> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all customers from `/api/Customer/GetAllCustomers`
  /// with query filters: Search, Cust_BranchId, Cust_CompId, Area, City, State, IsActive
  Future<List<CustomerListItem>> getAllCustomers({
    String? search,
    int? branchId,
    int? compId,
    String? area,
    String? city,
    String? state,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanSearch = (search == null || search == 'null') ? '' : search.trim();
    final effectiveBranchId = (branchId != null && branchId > 0) ? branchId : 0;
    final effectiveCompId = (compId != null && compId > 0) ? compId : 0;

    final Map<String, String> queryParameters = {
      'Search': cleanSearch,
      if (effectiveBranchId > 0) 'Cust_BranchId': effectiveBranchId.toString(),
      if (effectiveCompId > 0) 'Cust_CompId': effectiveCompId.toString(),
    };

    if (area != null && area.trim().isNotEmpty) {
      queryParameters['Area'] = area.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      queryParameters['City'] = city.trim();
    }
    if (state != null && state.trim().isNotEmpty) {
      queryParameters['State'] = state.trim();
    }
    if (isActive != null) {
      queryParameters['IsActive'] = isActive.toString();
    }

    debugPrint('👥 [CustomerService.getAllCustomers] Requesting with query parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllCustomersEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final custResponse = CustomerListResponse.fromJson(response);
        if (custResponse.status || custResponse.data.isNotEmpty) {
          _customers = custResponse.data;
        } else if (response['data'] is List) {
          _customers = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => CustomerListItem.fromJson(e))
              .toList();
        } else {
          _customers = [];
          _errorMessage = custResponse.message.isNotEmpty
              ? custResponse.message
              : 'No customers found.';
        }
      } else if (response is List) {
        _customers = response
            .whereType<Map<String, dynamic>>()
            .map((e) => CustomerListItem.fromJson(e))
            .toList();
      } else {
        _customers = [];
      }

      _errorMessage = null;
      return _customers;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _customers = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching customers: $e';
      _customers = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch full customer details by ID from `/api/Customer/GetCustomerById/{Cust_Id}`
  Future<CustomerListItem?> getCustomerById(int custId) async {
    if (custId <= 0) return null;

    final endpoint = '${ApiConstants.getCustomerByIdEndpoint}/$custId';
    debugPrint('👥 [CustomerService.getCustomerById] Requesting URL: $endpoint');

    try {
      final dynamic response = await apiService.get(
        endpoint,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final detailResponse = CustomerDetailResponse.fromJson(response);
        if (detailResponse.data != null) {
          // Update in-memory cached customer if exists
          final index = _customers.indexWhere((c) => c.custId == custId);
          if (index != -1) {
            _customers[index] = detailResponse.data!;
            notifyListeners();
          }
          return detailResponse.data;
        } else if (response['data'] is Map<String, dynamic>) {
          return CustomerListItem.fromJson(response['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error fetching customer details: $e');
    }
  }

  /// Insert or update customer via POST `/api/Customer/InsertorUpdateCustomer`
  Future<CustomerUpsertResponse> insertOrUpdateCustomer(CustomerUpsertRequest request) async {
    int createdBy = request.custCreatedBy;
    int modifiedBy = request.custModifiedBy;

    // Resolve current user empId if not set
    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = CustomerUpsertRequest(
      custId: request.custId,
      custName: request.custName,
      custCompanyName: request.custCompanyName,
      custMobileNo: request.custMobileNo,
      custAlternateMobileNo: request.custAlternateMobileNo,
      custEmail: request.custEmail,
      custGSTNo: request.custGSTNo,
      custPANNo: request.custPANNo,
      custAddress: request.custAddress,
      custAreaId: request.custAreaId,
      custCityId: request.custCityId,
      custStateId: request.custStateId,
      custPincode: request.custPincode,
      custCountry: request.custCountry,
      custBranchId: request.custBranchId,
      custCompId: request.custCompId,
      custIsActive: request.custIsActive,
      custCreatedBy: createdBy,
      custModifiedBy: modifiedBy,
    );

    debugPrint('👥 [CustomerService.insertOrUpdateCustomer] Request payload: ${finalRequest.toJson()}');

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateCustomerEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = CustomerUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save customer.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving customer: $e');
    }
  }

  /// Get customer from local in-memory cache by ID
  CustomerListItem? getCustomerByIdFromCache(int id) {
    try {
      return _customers.firstWhere((c) => c.custId == id);
    } catch (_) {
      return null;
    }
  }

  /// Get customer from local in-memory cache by name
  CustomerListItem? getCustomerByName(String name) {
    try {
      final trimmed = name.trim().toLowerCase();
      return _customers.firstWhere(
        (c) => c.custName.trim().toLowerCase() == trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get customer from local in-memory cache by mobile
  CustomerListItem? getCustomerByMobile(String mobile) {
    try {
      final trimmed = mobile.trim();
      return _customers.firstWhere(
        (c) => c.custMobileNo.trim() == trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear in-memory cached customers
  void clearCache() {
    _customers = [];
    _errorMessage = null;
    notifyListeners();
  }

  // --- Compatibility methods ---
  void initializeDummyData() {}

  Future<void> addCustomer(CustomerListItem customer) async {
    await insertOrUpdateCustomer(CustomerUpsertRequest(
      custId: customer.custId,
      custName: customer.custName,
      custCompanyName: customer.custCompanyName,
      custMobileNo: customer.custMobileNo,
      custAlternateMobileNo: customer.custAlternateMobileNo,
      custEmail: customer.custEmail,
      custGSTNo: customer.custGSTNo,
      custPANNo: customer.custPANNo,
      custAddress: customer.custAddress,
      custAreaId: customer.custAreaId,
      custCityId: customer.custCityId,
      custStateId: customer.custStateId,
      custPincode: customer.custPincode,
      custCountry: customer.custCountry,
      custBranchId: customer.custBranchId > 0 ? customer.custBranchId : 1,
      custCompId: customer.custCompId > 0 ? customer.custCompId : 1,
      custIsActive: customer.custIsActive,
      custCreatedBy: customer.custCreatedBy,
      custModifiedBy: customer.custModifiedBy,
    ));
  }

  Future<void> updateCustomer(CustomerListItem customer) async {
    await insertOrUpdateCustomer(CustomerUpsertRequest(
      custId: customer.custId,
      custName: customer.custName,
      custCompanyName: customer.custCompanyName,
      custMobileNo: customer.custMobileNo,
      custAlternateMobileNo: customer.custAlternateMobileNo,
      custEmail: customer.custEmail,
      custGSTNo: customer.custGSTNo,
      custPANNo: customer.custPANNo,
      custAddress: customer.custAddress,
      custAreaId: customer.custAreaId,
      custCityId: customer.custCityId,
      custStateId: customer.custStateId,
      custPincode: customer.custPincode,
      custCountry: customer.custCountry,
      custBranchId: customer.custBranchId > 0 ? customer.custBranchId : 1,
      custCompId: customer.custCompId > 0 ? customer.custCompId : 1,
      custIsActive: customer.custIsActive,
      custCreatedBy: customer.custCreatedBy,
      custModifiedBy: customer.custModifiedBy,
    ));
  }

  Future<void> deleteCustomer(String id) async {
    final intId = int.tryParse(id) ?? 0;
    if (intId > 0) {
      _customers.removeWhere((c) => c.custId == intId);
      notifyListeners();
    }
  }
}

// Global instance for convenience
final customerService = CustomerService();
