import '../models/product_wise_sales_report.dart';
import 'api_service.dart';

class ProductWiseSalesReportService {
  static final ProductWiseSalesReportService _instance = ProductWiseSalesReportService._internal();
  factory ProductWiseSalesReportService() => _instance;
  ProductWiseSalesReportService._internal();

  final ApiService _apiService = apiService;

  Future<ProductWiseSalesResponse> getProductWiseSalesReport({
    required int compId,
    required int branchId,
    required DateTime fromDate,
    required DateTime toDate,
    String searchText = '',
    int pageNumber = 1,
    int pageSize = 15,
    String sortColumn = '',
    String sortDirection = '',
  }) async {
    final queryParams = {
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'FromDate': fromDate.toIso8601String(),
      'ToDate': toDate.toIso8601String(),
      'SearchText': searchText,
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
      if (sortColumn.isNotEmpty) 'SortColumn': sortColumn,
      if (sortDirection.isNotEmpty) 'SortDirection': sortDirection,
    };

    final response = await _apiService.get(
      '/api/Report/ProductWiseSalesReport',
      queryParameters: queryParams,
    );

    return ProductWiseSalesResponse.fromJson(response);
  }

  Future<ProductWiseCustomerPurchaseResponse> getProductWiseCustomerPurchaseList({
    required int productId,
    required DateTime fromDate,
    required DateTime toDate,
    required int compId,
    required int branchId,
    String searchText = '',
    int pageNumber = 1,
    int pageSize = 15,
  }) async {
    final queryParams = {
      'ProductId': productId.toString(),
      'FromDate': fromDate.toIso8601String(),
      'ToDate': toDate.toIso8601String(),
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'SearchText': searchText,
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    final response = await _apiService.get(
      '/api/Report/ProductWiseCustomerPurchaseList',
      queryParameters: queryParams,
    );

    return ProductWiseCustomerPurchaseResponse.fromJson(response);
  }
}

final productWiseSalesReportService = ProductWiseSalesReportService();
