import 'package:flutter/foundation.dart';
import '../models/route_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class RouteService extends ChangeNotifier {
  // Singleton pattern
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  List<RouteListItem> _routes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RouteListItem> get routes => List.unmodifiable(_routes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all routes
  Future<List<RouteListItem>> getAllRoutes({
    int? compId,
    int? branchId,
    String? search,
    bool? isActive,
    int? pageNumber,
    int? pageSize,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanSearch = (search == null || search == 'null') ? '' : search.trim();

    final Map<String, String> queryParameters = {};

    if (compId != null && compId > 0) {
      queryParameters['Route_CompId'] = compId.toString();
    }
    if (branchId != null && branchId > 0) {
      queryParameters['Route_BranchId'] = branchId.toString();
    }
    if (cleanSearch.isNotEmpty) {
      queryParameters['Search'] = cleanSearch;
    }
    if (isActive != null) {
      queryParameters['IsActive'] = isActive.toString();
    }
    if (pageNumber != null) {
      queryParameters['PageNumber'] = pageNumber.toString();
    }
    if (pageSize != null) {
      queryParameters['PageSize'] = pageSize.toString();
    }

    debugPrint('📦 [RouteService.getAllRoutes] Requesting with query parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllRoutesEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final routeResponse = RouteListResponse.fromJson(response);
        if (routeResponse.status || routeResponse.data.isNotEmpty) {
          _routes = routeResponse.data;
        } else if (response['data'] is List) {
          _routes = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => RouteListItem.fromJson(e))
              .toList();
        } else {
          _routes = [];
          _errorMessage = routeResponse.message.isNotEmpty
              ? routeResponse.message
              : 'No routes found.';
        }
      } else if (response is List) {
        _routes = response
            .whereType<Map<String, dynamic>>()
            .map((e) => RouteListItem.fromJson(e))
            .toList();
      } else {
        _routes = [];
      }

      _errorMessage = null;

      // Apply client-side fallback filtering on fetched list
      List<RouteListItem> filteredResult = _routes;
      if (cleanSearch.isNotEmpty || isActive != null) {
        final searchLower = cleanSearch.toLowerCase();

        filteredResult = filteredResult.where((r) {
          if (isActive != null && r.routeIsActive != isActive) {
            return false;
          }

          if (searchLower.isNotEmpty) {
            final matches =
                r.routeName.toLowerCase().contains(searchLower) ||
                r.routeDescription.toLowerCase().contains(searchLower);
            if (!matches) return false;
          }

          return true;
        }).toList();
      }

      return filteredResult;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _routes = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching routes: $e';
      _routes = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Insert or update route
  Future<RouteUpsertResponse> insertOrUpdateRoute(
    RouteUpsertRequest request,
  ) async {
    int createdBy = request.routeCreatedBy;
    int modifiedBy = request.routeModifiedBy;

    if (createdBy == 0 && request.routeId == 0) {
      try {
        final user = await sessionService.getUserData();
        createdBy = user?.empId ?? 0;
      } catch (_) {}
    }

    if (modifiedBy == 0 && request.routeId != 0) {
      try {
        final user = await sessionService.getUserData();
        modifiedBy = user?.empId ?? 0;
      } catch (_) {}
    }

    final finalRequest = RouteUpsertRequest(
      routeId: request.routeId,
      routeCompId: request.routeCompId,
      routeBranchId: request.routeBranchId,
      routeName: request.routeName,
      routeDescription: request.routeDescription,
      routeIsActive: request.routeIsActive,
      routeCreatedBy: createdBy,
      routeModifiedBy: modifiedBy,
    );

    debugPrint(
      '📦 [RouteService.insertOrUpdateRoute] Request payload: ${finalRequest.toJson()}',
    );

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateRouteEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = RouteUpsertResponse.fromJson(response);

      if (upsertResponse.status ||
          (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save route.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving route: $e');
    }
  }

  RouteListItem? getRouteByIdFromCache(int id) {
    try {
      return _routes.firstWhere((r) => r.routeId == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _routes = [];
    _errorMessage = null;
    notifyListeners();
  }
}

// Global instance for convenience
final routeService = RouteService();
