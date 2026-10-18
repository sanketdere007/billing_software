import '../models/product_wise_sales_return_report.dart';
import 'api_service.dart';

class ProductWiseSalesReturnReportService {
  static final ProductWiseSalesReturnReportService _instance =
      ProductWiseSalesReturnReportService._internal();
  factory ProductWiseSalesReturnReportService() => _instance;
  ProductWiseSalesReturnReportService._internal();

  final ApiService _apiService = apiService;

  Future<ProductWiseSalesReturnResponse> getProductWiseSalesReturnReport({
    required int compId,
    required int branchId,
    required DateTime fromDate,
    required DateTime toDate,
    int? productId,
    String search = '',
    String? status,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 15,
  }) async {
    final fromDateApi = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
      0,
      0,
      0,
    );
    final toDateApi = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
      23,
      59,
      59,
      999,
    );

    final queryParams = <String, String>{
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'FromDate': fromDateApi.toIso8601String(),
      'ToDate': toDateApi.toIso8601String(),
      if (productId != null && productId > 0)
        'ProductId': productId.toString(),
      if (search.isNotEmpty) 'Search': search,
      if (status != null && status.isNotEmpty) 'Status': status,
      if (isActive != null) 'IsActive': isActive.toString(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    final response = await _apiService.get(
      '/api/Report/ProductWiseSalesReturnReport',
      queryParameters: queryParams,
    );

    return ProductWiseSalesReturnResponse.fromJson(response);
  }

  Future<ProductWiseSalesReturnDetailResponse>
      getProductWiseSalesReturnDetailReport({
    required int compId,
    required int branchId,
    required int productId,
    required DateTime fromDate,
    required DateTime toDate,
    int? customerId,
    int? batchId,
    String? invoiceNo,
    String search = '',
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 15,
  }) async {
    final fromDateApi = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
      0,
      0,
      0,
    );
    final toDateApi = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
      23,
      59,
      59,
      999,
    );

    final queryParams = <String, String>{
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'ProductId': productId.toString(),
      'FromDate': fromDateApi.toIso8601String(),
      'ToDate': toDateApi.toIso8601String(),
      if (customerId != null && customerId > 0)
        'CustomerId': customerId.toString(),
      if (batchId != null && batchId > 0) 'BatchId': batchId.toString(),
      if (invoiceNo != null && invoiceNo.isNotEmpty) 'InvoiceNo': invoiceNo,
      if (search.isNotEmpty) 'Search': search,
      if (isActive != null) 'IsActive': isActive.toString(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    final response = await _apiService.get(
      '/api/Report/ProductWiseSalesReturnDetailReport',
      queryParameters: queryParams,
    );

    return ProductWiseSalesReturnDetailResponse.fromJson(response);
  }
}

final productWiseSalesReturnReportService =
    ProductWiseSalesReturnReportService();
