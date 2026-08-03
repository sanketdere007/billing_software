import 'package:flutter/foundation.dart';
import '../models/role.dart';

class RoleService extends ChangeNotifier {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  final List<Role> _roles = [];

  List<Role> get roles => List.unmodifiable(_roles);

  void initializeDummyData() {
    if (_roles.isEmpty) {
      _roles.addAll([
        Role(
          id: 'ROLE-001',
          name: 'Super Admin',
          description: 'Full access to all modules',
          permissions: {
            'Dashboard': ['View'],
            'Customer': ['View', 'Add', 'Edit', 'Delete'],
          },
        ),
        Role(
          id: 'ROLE-002',
          name: 'Sales Manager',
          description: 'Access to sales and customers',
          permissions: {
            'Dashboard': ['View'],
            'Customer': ['View', 'Add', 'Edit'],
            'Sales': ['View', 'Add', 'Edit'],
          },
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addRole(Role role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _roles.add(role);
    notifyListeners();
  }

  Future<void> updateRole(Role role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _roles.indexWhere((r) => r.id == role.id);
    if (index != -1) {
      _roles[index] = role;
      notifyListeners();
    }
  }

  Future<void> deleteRole(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _roles.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
