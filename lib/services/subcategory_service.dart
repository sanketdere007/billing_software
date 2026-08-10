import 'package:flutter/foundation.dart';
import '../models/subcategory.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class SubCategoryService extends ChangeNotifier {
  static final SubCategoryService _instance = SubCategoryService._internal();
  factory SubCategoryService() => _instance;
  SubCategoryService._internal();

  List<SubCategoryListItem> _subcategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SubCategoryListItem> get subcategories => List.unmodifiable(_subcategories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<SubCategoryListItem>> getAllSubCategories({
    int? subCatId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};

    if (subCatId != null && subCatId > 0) {
      queryParameters['SubCat_Id'] = subCatId.toString();
    }
    if (isActive != null) {
      queryParameters['SubCat_IsActive'] = isActive.toString();
    }

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllSubCategoriesEndpoint,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final subCategoryResponse = SubCategoryListResponse.fromJson(response);
        if (subCategoryResponse.status || subCategoryResponse.data.isNotEmpty) {
          _subcategories = subCategoryResponse.data;
        } else if (response['data'] is List) {
          _subcategories = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => SubCategoryListItem.fromJson(e))
              .toList();
        } else {
          _subcategories = [];
          _errorMessage = subCategoryResponse.message.isNotEmpty
              ? subCategoryResponse.message
              : 'Failed to fetch subcategories.';
        }
      } else if (response is List) {
        _subcategories = response
            .whereType<Map<String, dynamic>>()
            .map((e) => SubCategoryListItem.fromJson(e))
            .toList();
      } else {
        _subcategories = [];
      }

      _errorMessage = null;
      return _subcategories;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _subcategories = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching subcategories: $e';
      _subcategories = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SubCategoryUpsertResponse> insertOrUpdateSubCategory(SubCategoryUpsertRequest request) async {
    int createdBy = request.subCatCreatedBy;
    int modifiedBy = request.subCatModifiedBy;

    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = SubCategoryUpsertRequest(
      subCatId: request.subCatId,
      subCatCatId: request.subCatCatId,
      subCatName: request.subCatName,
      subCatDescription: request.subCatDescription,
      subCatIsActive: request.subCatIsActive,
      subCatCreatedBy: createdBy,
      subCatModifiedBy: modifiedBy,
    );

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateSubCategoryEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = SubCategoryUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save subcategory.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving subcategory: $e');
    }
  }

  SubCategoryListItem? getSubCategoryById(int id) {
    try {
      return _subcategories.firstWhere((c) => c.subCatId == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _subcategories = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final subcategoryService = SubCategoryService();
