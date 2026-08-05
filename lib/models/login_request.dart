class LoginRequest {
  final String empUserName;
  final String password;

  LoginRequest({
    required this.empUserName,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'emp_UserName': empUserName,
      'password': password,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      empUserName: json['emp_UserName'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}
