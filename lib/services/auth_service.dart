import 'package:flutter/foundation.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'session_service.dart';

class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    loadSessionUser();
  }

  UserData? _currentUser;
  UserData? get currentUser => _currentUser;

  /// Authenticate user via Login API
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final request = LoginRequest(
      empUserName: username.trim(),
      password: password,
    );

    final dynamic rawResponse = await apiService.post(
      ApiConstants.loginEndpoint,
      body: request.toJson(),
      requiresAuth: false,
    );

    if (rawResponse is! Map<String, dynamic>) {
      throw ApiException('Unexpected response structure from server.');
    }

    final loginResponse = LoginResponse.fromJson(rawResponse);

    if (loginResponse.status && loginResponse.data != null) {
      // Persist session into SharedPreferences
      await sessionService.saveSession(loginResponse.data!);
      _currentUser = loginResponse.data;
      notifyListeners();
      return loginResponse;
    } else {
      final message = loginResponse.message.isNotEmpty
          ? loginResponse.message
          : 'Invalid Username or Password';
      throw ApiException(message);
    }
  }

  /// Initialize and load stored session user details
  Future<UserData?> loadSessionUser() async {
    _currentUser = await sessionService.getUserData();
    notifyListeners();
    return _currentUser;
  }

  /// Check if user session is valid
  Future<bool> isAuthenticated() async {
    final isValid = await sessionService.isUserLoggedIn();
    if (isValid && _currentUser == null) {
      await loadSessionUser();
    }
    return isValid;
  }

  /// Logout current user and clear stored credentials
  Future<void> logout() async {
    await sessionService.clearSession();
    _currentUser = null;
    notifyListeners();
  }
}

final authService = AuthService();
