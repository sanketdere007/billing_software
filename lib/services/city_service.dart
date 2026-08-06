import 'package:flutter/foundation.dart';
import '../models/city.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class CityService extends ChangeNotifier {
  static final CityService _instance = CityService._internal();
  factory CityService() => _instance;
  CityService._internal();

  List<CityListItem> _cities = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CityListItem> get cities => List.unmodifiable(_cities);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all cities with query filters: Search (empty string by default), StateId, IsActive (null when All)
  Future<List<CityListItem>> getAllCities({
    String? search,
    int? stateId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanSearch = (search == null || search == 'null') ? '' : search.trim();
    final effectiveStateId = (stateId != null && stateId > 0) ? stateId : 0;

    // Always include Search and StateId (0 when not selected)
    final Map<String, String> queryParameters = {
      'Search': cleanSearch,
      'StateId': effectiveStateId.toString(),
    };

    // Include IsActive if active/inactive is specifically chosen, otherwise omit (null for all)
    if (isActive != null) {
      queryParameters['IsActive'] = isActive.toString();
    }

    debugPrint('🏙️ [CityService.getAllCities] Requesting with parameters: $queryParameters (search: "$cleanSearch", stateId: $effectiveStateId, isActive: $isActive)');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllCitiesEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final cityResponse = CityListResponse.fromJson(response);
        if (cityResponse.status || cityResponse.data.isNotEmpty) {
          _cities = cityResponse.data;
        } else if (response['data'] is List) {
          _cities = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => CityListItem.fromJson(e))
              .toList();
        } else {
          _cities = [];
          _errorMessage = cityResponse.message.isNotEmpty
              ? cityResponse.message
              : 'Failed to fetch cities.';
        }
      } else if (response is List) {
        _cities = response
            .whereType<Map<String, dynamic>>()
            .map((e) => CityListItem.fromJson(e))
            .toList();
      } else {
        _cities = [];
      }

      _errorMessage = null;
      return _cities;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _cities = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching cities: $e';
      _cities = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Insert or update city
  Future<CityUpsertResponse> insertOrUpdateCity(CityUpsertRequest request) async {
    int createdBy = request.cityCreatedBy;
    int modifiedBy = request.cityModifiedBy;

    // Resolve current user empId if not set
    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = CityUpsertRequest(
      cityId: request.cityId,
      cityStateId: request.cityStateId,
      cityName: request.cityName,
      cityIsActive: request.cityIsActive,
      cityCreatedBy: createdBy,
      cityModifiedBy: modifiedBy,
    );

    debugPrint('🏙️ [CityService.insertOrUpdateCity] Request payload: ${finalRequest.toJson()}');

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateCityEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = CityUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save city.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving city: $e');
    }
  }

  /// Get city by ID from in-memory cache
  CityListItem? getCityById(int id) {
    try {
      return _cities.firstWhere((c) => c.cityId == id);
    } catch (_) {
      return null;
    }
  }

  /// Get city by name from in-memory cache
  CityListItem? getCityByName(String name) {
    try {
      final trimmed = name.trim().toLowerCase();
      return _cities.firstWhere(
        (c) => c.cityName.trim().toLowerCase() == trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get cached cities filtered by State ID
  List<CityListItem> getCitiesByStateId(int stateId) {
    if (stateId <= 0) return _cities;
    return _cities.where((c) => c.stateId == stateId).toList();
  }

  /// Clear in-memory cached cities
  void clearCache() {
    _cities = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final cityService = CityService();
