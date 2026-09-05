import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/current_stock.dart';
import '../utils/api_constants.dart';
import 'auth_service.dart';
import 'session_service.dart';

class CurrentStockService {
  Future<CurrentStockResponse> getCurrentStock({
    int? compId,
    int? branchId,
    int? productId,
    String search = '',
    bool isActive = true,
    int pageNumber = 1,
    int pageSize = 15,
  }) async {
    try {
      final token = authService.currentUser?.token;
      if (token == null || token.isEmpty) {
        return CurrentStockResponse(
          status: false,
          message: 'Authentication token not found.',
          data: [],
        );
      }

      final cId = compId ?? sessionService.selectedCompId ?? 0;
      final bId = branchId ?? sessionService.selectedBranchId ?? 0;

      final queryParams = {
        'CompId': cId.toString(),
        'BranchId': bId.toString(),
        if (productId != null) 'ProductId': productId.toString(),
        if (search.isNotEmpty) 'Search': search,
        'IsActive': isActive.toString(),
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };

      final uri = Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.getAllProductStockEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConstants.authHeaders(token),
      ).timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return CurrentStockResponse.fromJson(jsonResponse);
      } else {
        return CurrentStockResponse(
          status: false,
          message: 'Failed to fetch data (Status ${response.statusCode})',
          data: [],
        );
      }
    } catch (e) {
      return CurrentStockResponse(
        status: false,
        message: 'Error fetching data: $e',
        data: [],
      );
    }
  }
}

final currentStockService = CurrentStockService();
