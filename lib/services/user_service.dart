import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final List<AppUser> _users = [];

  List<AppUser> get users => List.unmodifiable(_users);

  void initializeDummyData() {
    if (_users.isEmpty) {
      _users.addAll([
        AppUser(
          id: 'USR-001',
          fullName: 'Admin User',
          username: 'admin',
          email: 'admin@system.com',
          mobileNumber: '9999999999',
          password: 'password',
          roleId: 'ROLE-001',
          companyId: 'COMP-001',
          branchId: 'BR-001',
          isActive: true,
        ),
        AppUser(
          id: 'USR-002',
          fullName: 'Sales Executive',
          username: 'sales',
          email: 'sales@system.com',
          mobileNumber: '8888888888',
          password: 'password',
          roleId: 'ROLE-002',
          companyId: 'COMP-001',
          branchId: 'BR-001',
          isActive: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _users.add(user);
    notifyListeners();
  }

  Future<void> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _users.removeWhere((u) => u.id == id);
    notifyListeners();
  }
}
