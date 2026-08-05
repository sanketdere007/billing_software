class LoginResponse {
  final bool status;
  final String message;
  final UserData? data;

  LoginResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? UserData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class UserData {
  final String? token;
  final String? expiration;
  final int? empId;
  final String? empFirstName;
  final String? empMiddleName;
  final String? empLastName;
  final String? empEmail;
  final String? empMobileNumber;
  final String? empUserName;
  final String? empGender;
  final String? empRole;
  final String? empDepartment;
  final String? empDesignation;
  final String? empJoiningDate;
  final bool? empIsActive;

  UserData({
    this.token,
    this.expiration,
    this.empId,
    this.empFirstName,
    this.empMiddleName,
    this.empLastName,
    this.empEmail,
    this.empMobileNumber,
    this.empUserName,
    this.empGender,
    this.empRole,
    this.empDepartment,
    this.empDesignation,
    this.empJoiningDate,
    this.empIsActive,
  });

  String get fullName {
    final parts = [
      empFirstName,
      empMiddleName,
      empLastName,
    ].where((p) => p != null && p.trim().isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : (empUserName ?? 'User');
  }

  bool get isExpired {
    if (expiration == null || expiration!.isEmpty) return false;
    try {
      final expDate = DateTime.parse(expiration!);
      return DateTime.now().toUtc().isAfter(expDate.toUtc());
    } catch (_) {
      return false;
    }
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    int? parsedEmpId;
    if (json['emp_Id'] != null) {
      if (json['emp_Id'] is int) {
        parsedEmpId = json['emp_Id'] as int;
      } else if (json['emp_Id'] is num) {
        parsedEmpId = (json['emp_Id'] as num).toInt();
      } else if (json['emp_Id'] is String) {
        parsedEmpId = int.tryParse(json['emp_Id'] as String);
      }
    }

    bool? parsedIsActive;
    if (json['emp_IsActive'] != null) {
      if (json['emp_IsActive'] is bool) {
        parsedIsActive = json['emp_IsActive'] as bool;
      } else if (json['emp_IsActive'] is num) {
        parsedIsActive = (json['emp_IsActive'] as num) == 1;
      } else if (json['emp_IsActive'] is String) {
        parsedIsActive = (json['emp_IsActive'] as String).toLowerCase() == 'true' ||
            (json['emp_IsActive'] as String) == '1';
      }
    }

    return UserData(
      token: json['token']?.toString(),
      expiration: json['expiration']?.toString(),
      empId: parsedEmpId,
      empFirstName: json['emp_FirstName']?.toString(),
      empMiddleName: json['emp_MiddleName']?.toString(),
      empLastName: json['emp_LastName']?.toString(),
      empEmail: json['emp_Email']?.toString(),
      empMobileNumber: json['emp_MobileNumber']?.toString(),
      empUserName: json['emp_UserName']?.toString(),
      empGender: json['emp_Gender']?.toString(),
      empRole: json['emp_Role']?.toString(),
      empDepartment: json['emp_Department']?.toString(),
      empDesignation: json['emp_Designation']?.toString(),
      empJoiningDate: json['emp_JoiningDate']?.toString(),
      empIsActive: parsedIsActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiration': expiration,
      'emp_Id': empId,
      'emp_FirstName': empFirstName,
      'emp_MiddleName': empMiddleName,
      'emp_LastName': empLastName,
      'emp_Email': empEmail,
      'emp_MobileNumber': empMobileNumber,
      'emp_UserName': empUserName,
      'emp_Gender': empGender,
      'emp_Role': empRole,
      'emp_Department': empDepartment,
      'emp_Designation': empDesignation,
      'emp_JoiningDate': empJoiningDate,
      'emp_IsActive': empIsActive,
    };
  }
}
