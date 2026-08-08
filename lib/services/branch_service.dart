import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class BranchService extends ChangeNotifier {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  List<BranchListItem> _branches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BranchListItem> get branches => List.unmodifiable(_branches);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all branches from `/api/Branch/GetAllBranches`
  /// Query parameters:
  /// - `Branch_CompId` / `CompId` (int)
  /// - `Branch_IsActive` / `IsActive` (bool)
  Future<List<BranchListItem>> getAllBranches({
    int? compId,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParameters = {};

    if (compId != null && compId > 0) {
      queryParameters['Branch_CompId'] = compId.toString();
      queryParameters['CompId'] = compId.toString();
    }

    if (isActive != null) {
      queryParameters['Branch_IsActive'] = isActive.toString();
      queryParameters['IsActive'] = isActive.toString();
    }

    debugPrint('🏬 [BranchService.getAllBranches] Requesting with parameters: $queryParameters');

    try {
      final dynamic response = await apiService.get(
        ApiConstants.getAllBranchesEndpoint,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final branchResponse = BranchListResponse.fromJson(response);
        if (branchResponse.status || branchResponse.data.isNotEmpty) {
          _branches = branchResponse.data;
        } else if (response['data'] is List) {
          _branches = (response['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => BranchListItem.fromJson(e))
              .toList();
        } else {
          _branches = [];
          _errorMessage = branchResponse.message.isNotEmpty
              ? branchResponse.message
              : (branchResponse.error ?? 'Failed to fetch branches.');
        }
      } else if (response is List) {
        _branches = response
            .whereType<Map<String, dynamic>>()
            .map((e) => BranchListItem.fromJson(e))
            .toList();
      } else {
        _branches = [];
      }

      _errorMessage = null;
      return _branches;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('⚠️ [BranchService.getAllBranches] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      _errorMessage = 'Error fetching branches: $e';
      debugPrint('⚠️ [BranchService.getAllBranches] Error: $e');
      throw ApiException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get cached branches filtered by Company ID
  List<BranchListItem> getBranchesByCompId(int compId) {
    if (compId <= 0) return _branches;
    return _branches.where((b) => b.branchCompId == compId).toList();
  }

  /// Get branch by integer ID from cache
  BranchListItem? getBranchById(int id) {
    try {
      return _branches.firstWhere((b) => b.branchId == id);
    } catch (_) {
      return null;
    }
  }

  /// Get branch by name from cache
  BranchListItem? getBranchByName(String name) {
    try {
      final trimmed = name.trim().toLowerCase();
      return _branches.firstWhere(
        (b) => b.branchName.trim().toLowerCase() == trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Initialize fallback dummy data if API unavailable
  void initializeDummyData() {
    if (_branches.isEmpty) {
      _branches.addAll([
        BranchListItem(
          branchId: 1,
          branchCompId: 1,
          branchCompName: 'Tech Innovators Inc.',
          branchName: 'Pune Head Office',
          branchContactPerson: 'Sanket Dere',
          branchMobileNo: '9876543212',
          branchEmail: 'pune@sankysoft.in',
          branchCity: 'Pune',
          branchState: 'Maharashtra',
          branchIsActive: true,
          code: 'HQ',
        ),
        BranchListItem(
          branchId: 2,
          branchCompId: 1,
          branchCompName: 'Tech Innovators Inc.',
          branchName: 'Mumbai Regional Office',
          branchCity: 'Mumbai',
          branchState: 'Maharashtra',
          branchIsActive: true,
          code: 'MRO',
        ),
        BranchListItem(
          branchId: 3,
          branchCompId: 2,
          branchCompName: 'Global Trade Corp',
          branchName: 'Delhi Central Branch',
          branchCity: 'Delhi',
          branchState: 'Delhi',
          branchIsActive: true,
          code: 'DCB',
        ),
      ]);
      notifyListeners();
    }
  }

  /// Add branch (local/legacy support)
  Future<void> addBranch(Branch branch) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _branches.add(branch);
    notifyListeners();
  }

  /// Update branch (local/legacy support)
  Future<void> updateBranch(Branch branch) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _branches.indexWhere((b) => b.branchId == branch.branchId);
    if (index != -1) {
      _branches[index] = branch;
      notifyListeners();
    }
  }

  /// Delete branch (local/legacy support)
  Future<void> deleteBranch(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final parsedId = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    _branches.removeWhere((b) => b.branchId == parsedId || b.id == id);
    notifyListeners();
  }

  /// Clear cache
  void clearCache() {
    _branches = [];
    _errorMessage = null;
    notifyListeners();
  }
}

final branchService = BranchService();
