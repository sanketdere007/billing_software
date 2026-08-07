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

  /// Returns 'emp_FirstName emp_LastName' if available, otherwise falls back to username or 'User'
  String get firstAndLastName {
    final first = (empFirstName ?? '').trim();
    final last = (empLastName ?? '').trim();
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    if (empUserName != null && empUserName!.trim().isNotEmpty) {
      return empUserName!.trim();
    }
    return 'User';
  }

  /// Returns user initials for profile avatar (e.g. 'SD' for 'Sanket Dere')
  String get initials {
    final first = (empFirstName ?? '').trim();
    final last = (empLastName ?? '').trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    } else if (first.isNotEmpty) {
      return first[0].toUpperCase();
    } else if (empUserName != null && empUserName!.trim().isNotEmpty) {
      return empUserName!.trim()[0].toUpperCase();
    }
    return 'U';
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
    if (json['emp_Id'] != null || json['empId'] != null || json['Emp_Id'] != null) {
      final rawId = json['emp_Id'] ?? json['empId'] ?? json['Emp_Id'];
      if (rawId is int) {
        parsedEmpId = rawId;
      } else if (rawId is num) {
        parsedEmpId = rawId.toInt();
      } else if (rawId is String) {
        parsedEmpId = int.tryParse(rawId);
      }
    }

    bool? parsedIsActive;
    final rawIsActive = json['emp_IsActive'] ?? json['empIsActive'] ?? json['Emp_IsActive'];
    if (rawIsActive != null) {
      if (rawIsActive is bool) {
        parsedIsActive = rawIsActive;
      } else if (rawIsActive is num) {
        parsedIsActive = rawIsActive == 1;
      } else if (rawIsActive is String) {
        parsedIsActive = rawIsActive.toLowerCase() == 'true' || rawIsActive == '1';
      }
    }

    return UserData(
      token: (json['token'] ?? json['Token'])?.toString(),
      expiration: (json['expiration'] ?? json['Expiration'])?.toString(),
      empId: parsedEmpId,
      empFirstName: (json['emp_FirstName'] ?? json['empFirstName'] ?? json['Emp_FirstName'] ?? json['emp_firstname'])?.toString(),
      empMiddleName: (json['emp_MiddleName'] ?? json['empMiddleName'] ?? json['Emp_MiddleName'] ?? json['emp_middlename'])?.toString(),
      empLastName: (json['emp_LastName'] ?? json['empLastName'] ?? json['Emp_LastName'] ?? json['emp_lastname'])?.toString(),
      empEmail: (json['emp_Email'] ?? json['empEmail'] ?? json['Emp_Email'])?.toString(),
      empMobileNumber: (json['emp_MobileNumber'] ?? json['empMobileNumber'] ?? json['Emp_MobileNumber'])?.toString(),
      empUserName: (json['emp_UserName'] ?? json['empUserName'] ?? json['Emp_UserName'])?.toString(),
      empGender: (json['emp_Gender'] ?? json['empGender'] ?? json['Emp_Gender'])?.toString(),
      empRole: (json['emp_Role'] ?? json['empRole'] ?? json['Emp_Role'])?.toString(),
      empDepartment: (json['emp_Department'] ?? json['empDepartment'] ?? json['Emp_Department'])?.toString(),
      empDesignation: (json['emp_Designation'] ?? json['empDesignation'] ?? json['Emp_Designation'])?.toString(),
      empJoiningDate: (json['emp_JoiningDate'] ?? json['empJoiningDate'] ?? json['Emp_JoiningDate'])?.toString(),
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
