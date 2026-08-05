import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_response.dart';
import '../utils/api_constants.dart';

class SessionService {
  // Singleton pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  // Storage Keys
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyToken = 'auth_token';
  static const String _keyExpiration = 'token_expiration';
  static const String _keyEmpId = 'emp_Id';
  static const String _keyEmpFirstName = 'emp_FirstName';
  static const String _keyEmpMiddleName = 'emp_MiddleName';
  static const String _keyEmpLastName = 'emp_LastName';
  static const String _keyEmpEmail = 'emp_Email';
  static const String _keyEmpMobileNumber = 'emp_MobileNumber';
  static const String _keyEmpUserName = 'emp_UserName';
  static const String _keyEmpGender = 'emp_Gender';
  static const String _keyEmpRole = 'emp_Role';
  static const String _keyEmpDepartment = 'emp_Department';
  static const String _keyEmpDesignation = 'emp_Designation';
  static const String _keyEmpJoiningDate = 'emp_JoiningDate';
  static const String _keyEmpIsActive = 'emp_IsActive';

  /// Save session after successful login
  Future<void> saveSession(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyIsLoggedIn, true);

    if (userData.token != null) {
      await prefs.setString(_keyToken, userData.token!);
    }
    if (userData.expiration != null) {
      await prefs.setString(_keyExpiration, userData.expiration!);
    }
    if (userData.empId != null) {
      await prefs.setInt(_keyEmpId, userData.empId!);
    }
    if (userData.empFirstName != null) {
      await prefs.setString(_keyEmpFirstName, userData.empFirstName!);
    }
    if (userData.empMiddleName != null) {
      await prefs.setString(_keyEmpMiddleName, userData.empMiddleName!);
    }
    if (userData.empLastName != null) {
      await prefs.setString(_keyEmpLastName, userData.empLastName!);
    }
    if (userData.empEmail != null) {
      await prefs.setString(_keyEmpEmail, userData.empEmail!);
    }
    if (userData.empMobileNumber != null) {
      await prefs.setString(_keyEmpMobileNumber, userData.empMobileNumber!);
    }
    if (userData.empUserName != null) {
      await prefs.setString(_keyEmpUserName, userData.empUserName!);
    }
    if (userData.empGender != null) {
      await prefs.setString(_keyEmpGender, userData.empGender!);
    }
    if (userData.empRole != null) {
      await prefs.setString(_keyEmpRole, userData.empRole!);
    }
    if (userData.empDepartment != null) {
      await prefs.setString(_keyEmpDepartment, userData.empDepartment!);
    }
    if (userData.empDesignation != null) {
      await prefs.setString(_keyEmpDesignation, userData.empDesignation!);
    }
    if (userData.empJoiningDate != null) {
      await prefs.setString(_keyEmpJoiningDate, userData.empJoiningDate!);
    }
    if (userData.empIsActive != null) {
      await prefs.setBool(_keyEmpIsActive, userData.empIsActive!);
    }
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Get HTTP headers with Authorization Bearer token attached
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      return ApiConstants.authHeaders(token);
    }
    return ApiConstants.defaultHeaders;
  }

  /// Retrieve the stored UserData object
  Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final empUserName = prefs.getString(_keyEmpUserName);

    // If neither token nor username is stored, user is not logged in
    if (token == null && empUserName == null) {
      return null;
    }

    return UserData(
      token: token,
      expiration: prefs.getString(_keyExpiration),
      empId: prefs.getInt(_keyEmpId),
      empFirstName: prefs.getString(_keyEmpFirstName),
      empMiddleName: prefs.getString(_keyEmpMiddleName),
      empLastName: prefs.getString(_keyEmpLastName),
      empEmail: prefs.getString(_keyEmpEmail),
      empMobileNumber: prefs.getString(_keyEmpMobileNumber),
      empUserName: empUserName,
      empGender: prefs.getString(_keyEmpGender),
      empRole: prefs.getString(_keyEmpRole),
      empDepartment: prefs.getString(_keyEmpDepartment),
      empDesignation: prefs.getString(_keyEmpDesignation),
      empJoiningDate: prefs.getString(_keyEmpJoiningDate),
      empIsActive: prefs.getBool(_keyEmpIsActive),
    );
  }

  /// Validate whether the current user session is active and unexpired
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final token = prefs.getString(_keyToken);

    if (!isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    // Check expiration timestamp if available
    final expiration = prefs.getString(_keyExpiration);
    if (expiration != null && expiration.isNotEmpty) {
      try {
        final expDate = DateTime.parse(expiration);
        if (DateTime.now().toUtc().isAfter(expDate.toUtc())) {
          // Token expired, clear invalid session
          await clearSession();
          return false;
        }
      } catch (_) {
        // If unparseable format, consider active
      }
    }

    return true;
  }

  /// Clear all stored user session details and tokens on logout
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyExpiration);
    await prefs.remove(_keyEmpId);
    await prefs.remove(_keyEmpFirstName);
    await prefs.remove(_keyEmpMiddleName);
    await prefs.remove(_keyEmpLastName);
    await prefs.remove(_keyEmpEmail);
    await prefs.remove(_keyEmpMobileNumber);
    await prefs.remove(_keyEmpUserName);
    await prefs.remove(_keyEmpGender);
    await prefs.remove(_keyEmpRole);
    await prefs.remove(_keyEmpDepartment);
    await prefs.remove(_keyEmpDesignation);
    await prefs.remove(_keyEmpJoiningDate);
    await prefs.remove(_keyEmpIsActive);
  }
}

// Global instance for convenience
final sessionService = SessionService();
