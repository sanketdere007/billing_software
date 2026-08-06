import 'package:flutter/foundation.dart';
import '../models/area.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class AreaService extends ChangeNotifier {
  static final AreaService _instance = AreaService._internal();
  factory AreaService() => _instance;
  AreaService._internal();

  List<AreaListItem> _areas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AreaListItem> get areas => List.unmodifiable(_areas);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all areas with query filters: Search, StateId, CityId, Pincode, IsActive
  Future<List<AreaListItem>> getAllAreas({
    String? search,
    int? stateId,
    int? cityId,
    String? pincode,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanSearch = (search == null || search == 'null') ? '' : search.trim();
    final effectiveStateId = (stateId != null && stateId > 0) ? stateId : 0;
    final effectiveCityId = (cityId != null && cityId > 0) ? cityId : 0;
    final cleanPincode = (pincode == null || pincode == 'null') ? '' : pincode.trim();

    // Query parameters
    final Map<String, String> queryParameters = {
      'Search': cleanSearch,
      'StateId': effectiveStateId.toString(),
      'CityId': effectiveCityId.toString(),
    };

    if (cleanPincode.isNotEmpty) {
      queryParameters['Pincode'] = cleanPincode;
    }

    if (isActive != null) {
      queryParameters['IsActive'] = isActive.toString();
    }

    debugPrint('📍 [AreaService.getAllAreas] Requesting with parameters: $queryParameters (search: "$cleanSearch", stateId: $effectiveStateId, cityId: $effectiveCityId, pincode: "$cleanPincode", isActive: $isActive)');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllAreasEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final areaResponse = AreaListResponse.fromJson(response);
        if (areaResponse.status || areaResponse.data.isNotEmpty) {
          _areas = areaResponse.data;
        } else if (response['data'] is List) {
          _areas = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => AreaListItem.fromJson(e))
              .toList();
        } else {
          _areas = [];
          _errorMessage = areaResponse.message.isNotEmpty
              ? areaResponse.message
              : 'Failed to fetch areas.';
        }
      } else if (response is List) {
        _areas = response
            .whereType<Map<String, dynamic>>()
            .map((e) => AreaListItem.fromJson(e))
            .toList();
      } else {
        _areas = [];
      }

      _errorMessage = null;
      return _areas;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _areas = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching areas: $e';
      _areas = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Insert or update area
  Future<AreaUpsertResponse> insertOrUpdateArea(AreaUpsertRequest request) async {
    int createdBy = request.areaCreatedBy;
    int modifiedBy = request.areaModifiedBy;

    // Resolve current user empId if not set
    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = AreaUpsertRequest(
      areaId: request.areaId,
      areaStateId: request.areaStateId,
      areaCityId: request.areaCityId,
      areaName: request.areaName,
      areaPincode: request.areaPincode,
      areaIsActive: request.areaIsActive,
      areaCreatedBy: createdBy,
      areaModifiedBy: modifiedBy,
    );

    debugPrint('📍 [AreaService.insertOrUpdateArea] Request payload: ${finalRequest.toJson()}');

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateAreaEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = AreaUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save area.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving area: $e');
    }
  }

  /// Get area by ID from in-memory cache
  AreaListItem? getAreaById(int id) {
    try {
      return _areas.firstWhere((a) => a.areaId == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear in-memory cached areas
  void clearCache() {
    _areas = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final areaService = AreaService();
