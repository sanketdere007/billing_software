import 'package:flutter/foundation.dart';
import '../models/company.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class CompanyService extends ChangeNotifier {
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  List<CompanyListItem> _companies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CompanyListItem> get companies => List.unmodifiable(_companies);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all companies from `/api/Company/GetAllCompanies`
  /// Query parameters:
  /// - `Comp_IsActive` (bool)
  /// - `IsActive` (bool)
  Future<List<CompanyListItem>> getAllCompanies({bool? isActive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};
    if (isActive != null) {
      queryParameters['Comp_IsActive'] = isActive.toString();
      queryParameters['IsActive'] = isActive.toString();
    }

    debugPrint('🏢 [CompanyService.getAllCompanies] Requesting with parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllCompaniesEndpoint,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final companyResponse = CompanyListResponse.fromJson(response);
        if (companyResponse.status || companyResponse.data.isNotEmpty) {
          _companies = companyResponse.data;
        } else if (response['data'] is List) {
          _companies = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => CompanyListItem.fromJson(e))
              .toList();
        } else {
          _companies = [];
          _errorMessage = companyResponse.message.isNotEmpty
              ? companyResponse.message
              : (companyResponse.error ?? 'Failed to fetch companies.');
        }
      } else if (response is List) {
        _companies = response
            .whereType<Map<String, dynamic>>()
            .map((e) => CompanyListItem.fromJson(e))
            .toList();
      } else {
        _companies = [];
      }

      _errorMessage = null;
      return _companies;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('⚠️ [CompanyService.getAllCompanies] ApiException: ${e.message}');
      if (_companies.isEmpty) {
        // If empty, maintain previous list or empty
      }
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching companies: $e';
      debugPrint('⚠️ [CompanyService.getAllCompanies] Error: $e');
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get company by integer ID from cache
  CompanyListItem? getCompanyById(int id) {
    try {
      return _companies.firstWhere((c) => c.compId == id);
    } catch (_) {
      return null;
    }
  }

  /// Get company by name from cache
  CompanyListItem? getCompanyByName(String name) {
    try {
      final trimmed = name.trim().toLowerCase();
      return _companies.firstWhere(
        (c) => c.compName.trim().toLowerCase() == trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Initialize fallback dummy data if API unavailable
  void initializeDummyData() {
    if (_companies.isEmpty) {
      _companies.addAll([
        CompanyListItem(
          compId: 1,
          compName: 'Tech Innovators Inc.',
          compGSTNo: '29ABCDE1234F1Z5',
          compEmail: 'contact@techinnovators.com',
          compCity: 'Bangalore',
          compState: 'Karnataka',
          compIsActive: true,
          code: 'TI',
        ),
        CompanyListItem(
          compId: 2,
          compName: 'Global Trade Corp',
          compGSTNo: '27XYZAB5678F1Z9',
          compEmail: 'info@globaltrade.com',
          compCity: 'Mumbai',
          compState: 'Maharashtra',
          compIsActive: true,
          code: 'GTC',
        ),
      ]);
      notifyListeners();
    }
  }

  /// Add company (local/legacy support)
  Future<void> addCompany(Company company) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _companies.add(company);
    notifyListeners();
  }

  /// Update company (local/legacy support)
  Future<void> updateCompany(Company company) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _companies.indexWhere((c) => c.compId == company.compId);
    if (index != -1) {
      _companies[index] = company;
      notifyListeners();
    }
  }

  /// Delete company (local/legacy support)
  Future<void> deleteCompany(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final parsedId = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    _companies.removeWhere((c) => c.compId == parsedId || c.id == id);
    notifyListeners();
  }

  /// Clear cache
  void clearCache() {
    _companies = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final companyService = CompanyService();
