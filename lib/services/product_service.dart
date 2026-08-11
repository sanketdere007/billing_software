import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class ProductService extends ChangeNotifier {
  // Singleton pattern
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  List<ProductListItem> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductListItem> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all products from `/api/Product/GetAllProducts`
  /// Parameters: Prod_Id, Prod_CompId, Prod_BranchId, Search, Prod_IsActive
  Future<List<ProductListItem>> getAllProducts({
    int? prodId,
    int? compId,
    int? branchId,
    String? search,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanSearch = (search == null || search == 'null')
        ? ''
        : search.trim();
    final effectiveBranchId = (branchId != null && branchId > 0)
        ? branchId
        : (sessionService.selectedBranchId ?? 0);
    final effectiveCompId = (compId != null && compId > 0)
        ? compId
        : (sessionService.selectedCompId ?? 0);

    final Map<String, String> queryParameters = {
      if (prodId != null && prodId > 0) 'Prod_Id': prodId.toString(),
    };

    if (isActive != null) {
      queryParameters['Prod_IsActive'] = isActive.toString();
    }

    debugPrint(
      '📦 [ProductService.getAllProducts] Requesting with query parameters: $queryParameters',
    );

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllProductsEndpoint,
        queryParameters: queryParameters,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final prodResponse = ProductListResponse.fromJson(response);
        if (prodResponse.status || prodResponse.data.isNotEmpty) {
          _products = prodResponse.data;
        } else if (response['data'] is List) {
          _products = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => ProductListItem.fromJson(e))
              .toList();
        } else {
          _products = [];
          _errorMessage = prodResponse.message.isNotEmpty
              ? prodResponse.message
              : 'No products found.';
        }
      } else if (response is List) {
        _products = response
            .whereType<Map<String, dynamic>>()
            .map((e) => ProductListItem.fromJson(e))
            .toList();
      } else {
        _products = [];
      }

      _errorMessage = null;

      // Apply client-side fallback filtering on fetched list
      List<ProductListItem> filteredResult = _products;
      if (cleanSearch.isNotEmpty || isActive != null) {
        final searchLower = cleanSearch.toLowerCase();

        filteredResult = filteredResult.where((p) {
          if (isActive != null && p.prodIsActive != isActive) {
            return false;
          }

          if (searchLower.isNotEmpty) {
            final matches =
                p.prodName.toLowerCase().contains(searchLower) ||
                p.prodCode.toLowerCase().contains(searchLower) ||
                p.prodHSNCode.toLowerCase().contains(searchLower) ||
                p.prodCompanyName.toLowerCase().contains(searchLower) ||
                p.prodBranchName.toLowerCase().contains(searchLower);
            if (!matches) return false;
          }

          return true;
        }).toList();
      }

      return filteredResult;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _products = [];
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching products: $e';
      _products = [];
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Insert or update product via POST `/api/Product/InsertOrUpdateProduct`
  Future<ProductUpsertResponse> insertOrUpdateProduct(
    ProductUpsertRequest request,
  ) async {
    int createdBy = request.prodCreatedBy;
    int modifiedBy = request.prodModifiedBy;

    if (createdBy == 0 && request.prodId == 0) {
      try {
        final user = await sessionService.getUserData();
        createdBy = user?.empId ?? 0;
      } catch (_) {}
    }

    if (modifiedBy == 0 && request.prodId != 0) {
      try {
        final user = await sessionService.getUserData();
        modifiedBy = user?.empId ?? 0;
      } catch (_) {}
    }

    final finalRequest = ProductUpsertRequest(
      prodId: request.prodId,
      prodCompId: request.prodCompId,
      prodBranchId: request.prodBranchId,
      prodCode: request.prodCode,
      prodName: request.prodName,
      prodBrandId: request.prodBrandId,
      prodCategoryId: request.prodCategoryId,
      prodSubCategoryId: request.prodSubCategoryId,
      prodUnitId: request.prodUnitId,
      prodHSNCode: request.prodHSNCode,
      prodGSTPercent: request.prodGSTPercent,
      prodIsActive: request.prodIsActive,
      prodCreatedBy: createdBy,
      prodModifiedBy: modifiedBy,
    );

    debugPrint(
      '📦 [ProductService.insertOrUpdateProduct] Request payload: ${finalRequest.toJson()}',
    );

    try {
      final dynamic response = await apiService.post(
        ApiConstants.insertOrUpdateProductEndpoint,
        body: finalRequest.toJson(),
        requiresAuth: true,
      );

      if (response is! Map<String, dynamic>) {
        throw ApiException('Invalid response format from server.');
      }

      final upsertResponse = ProductUpsertResponse.fromJson(response);

      if (upsertResponse.status ||
          (upsertResponse.data != null && upsertResponse.data!.status)) {
        return upsertResponse;
      } else {
        final msg = upsertResponse.message.isNotEmpty
            ? upsertResponse.message
            : (upsertResponse.data?.message ?? 'Failed to save product.');
        throw ApiException(msg);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error saving product: $e');
    }
  }

  ProductListItem? getProductByIdFromCache(int id) {
    try {
      return _products.firstWhere((p) => p.prodId == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _products = [];
    _errorMessage = null;
    notifyListeners();
  }
}

// Global instance for convenience
final productService = ProductService();
