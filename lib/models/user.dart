class AppUser {
  final String id;
  final String fullName;
  final String username;
  final String? email;
  final String mobileNumber;
  final String password;
  final String roleId;
  final String companyId;
  final String branchId;
  final String? profileImage;
  final bool isActive;

  AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.email,
    required this.mobileNumber,
    required this.password,
    required this.roleId,
    required this.companyId,
    required this.branchId,
    this.profileImage,
    this.isActive = true,
  });

  AppUser copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? mobileNumber,
    String? password,
    String? roleId,
    String? companyId,
    String? branchId,
    String? profileImage,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      password: password ?? this.password,
      roleId: roleId ?? this.roleId,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
    );
  }
}
