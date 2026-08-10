import 'package:flutter/foundation.dart';
import '../models/brand.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class BrandService extends ChangeNotifier {
  static final BrandService _instance = BrandService._internal();
  factory BrandService() => _instance;
  BrandService._internal();

  List<BrandListItem> _brands = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BrandListItem> get brands => List.unmodifiable(_brands);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<BrandListItem>> getAllBrands({
    int? brandId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};

    if (brandId != null && brandId > 0) {
      queryParameters['Brand_Id'] = brandId.toString();
    }
    if (isActive != null) {
      queryParameters['Brand_IsActive'] = isActive.toString();
    }

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllBrandsEndpoint,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final brandResponse = BrandListResponse.fromJson(response);
        if (brandResponse.status || brandResponse.data.isNotEmpty) {
          _brands = brandResponse.data;
        } else if (response['data'] is List) {
          _brands = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => BrandListItem.fromJson(e))
              .toList();
        } else {
          _brands = [];
          _errorMessage = brandResponse.message.isNotEmpty
              ? brandResponse.message
              : 'Failed to fetch brands.';
        }
      } else if (response is List) {
        _brands = response
            .whereType<Map<String, dynamic>>()
            .map((e) => BrandListItem.fromJson(e))
            .toList();
      } else {
        _brands = [];
      }

      _errorMessage = null;
      return _brands;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _brands = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching brands: $e';
      _brands = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BrandUpsertResponse> insertOrUpdateBrand(BrandUpsertRequest request) async {
    int createdBy = request.brandCreatedBy;
    int modifiedBy = request.brandModifiedBy;

    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = BrandUpsertRequest(
      brandId: request.brandId,
      brandName: request.brandName,
      brandDescription: request.brandDescription,
      brandIsActive: request.brandIsActive,
      brandCreatedBy: createdBy,
      brandModifiedBy: modifiedBy,
    );

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateBrandEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = BrandUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save brand.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving brand: $e');
    }
  }

  BrandListItem? getBrandById(int id) {
    try {
      return _brands.firstWhere((c) => c.brandId == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _brands = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final brandService = BrandService();
