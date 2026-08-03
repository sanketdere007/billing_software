import 'package:flutter/foundation.dart';
import '../models/branch.dart';

class BranchService extends ChangeNotifier {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  final List<Branch> _branches = [];

  List<Branch> get branches => List.unmodifiable(_branches);

  void initializeDummyData() {
    if (_branches.isEmpty) {
      _branches.addAll([
        Branch(
          id: 'BR-001',
          name: 'Main Branch HQ',
          code: 'HQ',
          companyId: 'COMP-001',
          city: 'Bangalore',
          state: 'Karnataka',
          isActive: true,
        ),
        Branch(
          id: 'BR-002',
          name: 'North Zone Office',
          code: 'NZ',
          companyId: 'COMP-001',
          city: 'Delhi',
          state: 'Delhi',
          isActive: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addBranch(Branch branch) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _branches.add(branch);
    notifyListeners();
  }

  Future<void> updateBranch(Branch branch) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _branches.indexWhere((b) => b.id == branch.id);
    if (index != -1) {
      _branches[index] = branch;
      notifyListeners();
    }
  }

  Future<void> deleteBranch(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _branches.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
