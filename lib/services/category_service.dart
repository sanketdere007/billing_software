import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class CategoryService extends ChangeNotifier {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  List<CategoryListItem> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryListItem> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<CategoryListItem>> getAllCategories({
    int? catId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};

    if (catId != null && catId > 0) {
      queryParameters['Cat_Id'] = catId.toString();
    }
    if (isActive != null) {
      queryParameters['Cat_IsActive'] = isActive.toString();
    }

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllCategoriesEndpoint,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final categoryResponse = CategoryListResponse.fromJson(response);
        if (categoryResponse.status || categoryResponse.data.isNotEmpty) {
          _categories = categoryResponse.data;
        } else if (response['data'] is List) {
          _categories = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => CategoryListItem.fromJson(e))
              .toList();
        } else {
          _categories = [];
          _errorMessage = categoryResponse.message.isNotEmpty
              ? categoryResponse.message
              : 'Failed to fetch categories.';
        }
      } else if (response is List) {
        _categories = response
            .whereType<Map<String, dynamic>>()
            .map((e) => CategoryListItem.fromJson(e))
            .toList();
      } else {
        _categories = [];
      }

      _errorMessage = null;
      return _categories;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _categories = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching categories: $e';
      _categories = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CategoryUpsertResponse> insertOrUpdateCategory(CategoryUpsertRequest request) async {
    int createdBy = request.catCreatedBy;
    int modifiedBy = request.catModifiedBy;

    if (createdBy == 0 || modifiedBy == 0) {
      try {
        final user = await sessionService.getUserData();
        final currentEmpId = user?.empId ?? 0;
        if (createdBy == 0) createdBy = currentEmpId;
        if (modifiedBy == 0) modifiedBy = currentEmpId;
      } catch (_) {}
    }

    final finalRequest = CategoryUpsertRequest(
      catId: request.catId,
      catName: request.catName,
      catDescription: request.catDescription,
      catIsActive: request.catIsActive,
      catCreatedBy: createdBy,
      catModifiedBy: modifiedBy,
    );

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateCategoryEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = CategoryUpsertResponse.fromJson(response);

      if (upsertResponse.status || (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save category.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving category: $e');
    }
  }

  CategoryListItem? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.catId == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _categories = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final categoryService = CategoryService();
