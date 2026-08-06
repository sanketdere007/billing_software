import 'package:flutter/foundation.dart';
import '../models/state_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class StateService extends ChangeNotifier {
  static final StateService _instance = StateService._internal();
  factory StateService() => _instance;
  StateService._internal();

  List<StateModel> _states = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StateModel> get states => List.unmodifiable(_states);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch states from API with optional force refresh and in-memory caching
  Future<List<StateModel>> getAllStates({
    String? search,
    bool? isActive,
    bool forceRefresh = false,
  }) async {
    final cleanSearch = (search == null || search == 'null')
        ? ''
        : search.trim();
    final bool hasCustomFilter = cleanSearch.isNotEmpty || isActive != null;
    if (_states.isNotEmpty && !forceRefresh && !hasCustomFilter) {
      return _states;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Always include Search parameter (empty string by default when not searching)
    final Map<String, String> queryParameters = {'Search': cleanSearch};

    // Include IsActive if active/inactive is specified, otherwise omit (null for all)
    if (isActive != null) {
      queryParameters['IsActive'] = isActive.toString();
    }

    debugPrint(
      '🗺️ [StateService.getAllStates] Requesting with parameters: $queryParameters (search: "$cleanSearch", isActive: $isActive)',
    );

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllStatesEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final stateResponse = StateListResponse.fromJson(response);
        if (stateResponse.status && stateResponse.data.isNotEmpty) {
          _states = stateResponse.data;
        } else if (response['data'] is List) {
          _states = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => StateModel.fromJson(e))
              .toList();
        } else {
          _states = stateResponse.data;
        }
      } else if (response is List) {
        _states = response
            .whereType<Map<String, dynamic>>()
            .map((e) => StateModel.fromJson(e))
            .toList();
      }

      _errorMessage = null;
      return _states;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'Failed to load states: $e';
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get state by ID from cache
  StateModel? getStateById(int id) {
    try {
      return _states.firstWhere((s) => s.stateId == id);
    } catch (_) {
      return null;
    }
  }

  /// Get state by name from cache
  StateModel? getStateByName(String name) {
    try {
      final trimmed = name.trim().toLowerCase();
      return _states.firstWhere(
        (s) => s.stateName.trim().toLowerCase() == trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear in-memory cached states
  void clearCache() {
    _states = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final stateService = StateService();
