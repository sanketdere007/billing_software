import 'package:flutter/foundation.dart';
import '../models/unit.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class UnitService extends ChangeNotifier {
  static final UnitService _instance = UnitService._internal();
  factory UnitService() => _instance;
  UnitService._internal();

  List<UnitListItem> _units = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UnitListItem> get units => List.unmodifiable(_units);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<UnitListItem>> getAllUnits({
    int? unitId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};

    if (unitId != null && unitId > 0) {
      queryParameters['Unit_Id'] = unitId.toString();
    }
    if (isActive != null) {
      queryParameters['Unit_IsActive'] = isActive.toString();
    }

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllUnitsEndpoint,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final unitResponse = UnitListResponse.fromJson(response);
        if (unitResponse.status || unitResponse.data.isNotEmpty) {
          _units = unitResponse.data;
        } else if (response['data'] is List) {
          _units = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => UnitListItem.fromJson(e))
              .toList();
        } else {
          _units = [];
          _errorMessage = unitResponse.message.isNotEmpty
              ? unitResponse.message
              : 'Failed to fetch units.';
        }
      } else if (response is List) {
        _units = response
            .whereType<Map<String, dynamic>>()
            .map((e) => UnitListItem.fromJson(e))
            .toList();
      } else {
        _units = [];
      }

      _errorMessage = null;
      return _units;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _units = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching units: $e';
      _units = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UnitUpsertResponse> insertOrUpdateUnit(UnitUpsertRequest request) async {
    int createdBy = request.unitCreatedBy;
    int modifiedBy = request.unitModifiedBy;

    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = UnitUpsertRequest(
      unitId: request.unitId,
      unitName: request.unitName,
      unitShortName: request.unitShortName,
      unitIsActive: request.unitIsActive,
      unitCreatedBy: createdBy,
      unitModifiedBy: modifiedBy,
    );

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateUnitEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = UnitUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save unit.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving unit: $e');
    }
  }

  UnitListItem? getUnitById(int id) {
    try {
      return _units.firstWhere((c) => c.unitId == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _units = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final unitService = UnitService();
