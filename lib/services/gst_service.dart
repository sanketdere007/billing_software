import 'package:flutter/foundation.dart';
import '../models/gst.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class GstService extends ChangeNotifier {
  static final GstService _instance = GstService._internal();
  factory GstService() => _instance;
  GstService._internal();

  List<GstTaxListItem> _gsts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GstTaxListItem> get gsts => List.unmodifiable(_gsts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all GST Taxes
  Future<List<GstTaxListItem>> getAllGsts({
    int? gstTaxId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};

    if (gstTaxId != null && gstTaxId > 0) {
      queryParameters['GSTTax_Id'] = gstTaxId.toString();
    }
    if (isActive != null) {
      queryParameters['GSTTax_IsActive'] = isActive.toString();
    }

    debugPrint('📊 [GstService.getAllGsts] Requesting with parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllGSTTaxesEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final gstResponse = GstTaxListResponse.fromJson(response);
        if (gstResponse.status || gstResponse.data.isNotEmpty) {
          _gsts = gstResponse.data;
        } else if (response['data'] is List) {
          _gsts = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => GstTaxListItem.fromJson(e))
              .toList();
        } else {
          _gsts = [];
          _errorMessage = gstResponse.message.isNotEmpty
              ? gstResponse.message
              : 'Failed to fetch GST taxes.';
        }
      } else if (response is List) {
        _gsts = response
            .whereType<Map<String, dynamic>>()
            .map((e) => GstTaxListItem.fromJson(e))
            .toList();
      } else {
        _gsts = [];
      }

      _errorMessage = null;
      return _gsts;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _gsts = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching GST taxes: $e';
      _gsts = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Insert or update GST Tax
  Future<GstTaxUpsertResponse> insertOrUpdateGst(GstTaxUpsertRequest request) async {
    int createdBy = request.gstTaxCreatedBy;
    int modifiedBy = request.gstTaxModifiedBy;

    // Resolve current user empId if not set
    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = GstTaxUpsertRequest(
      gstTaxId: request.gstTaxId,
      gstTaxName: request.gstTaxName,
      gstTaxPercentage: request.gstTaxPercentage,
      gstTaxCgst: request.gstTaxCgst,
      gstTaxSgst: request.gstTaxSgst,
      gstTaxIgst: request.gstTaxIgst,
      gstTaxIsActive: request.gstTaxIsActive,
      gstTaxCreatedBy: createdBy,
      gstTaxModifiedBy: modifiedBy,
    );

    debugPrint('📊 [GstService.insertOrUpdateGst] Request payload: ${finalRequest.toJson()}');

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateGSTTaxEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = GstTaxUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save GST Tax.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving GST Tax: $e');
    }
  }

  /// Clear in-memory cached GST taxes
  void clearCache() {
    _gsts = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final gstService = GstService();
