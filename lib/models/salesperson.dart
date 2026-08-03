class Salesperson {
  final String id;
  final String name;
  final String? employeeCode;
  final String? mobileNumber;
  final String? email;
  final String? branchId;
  final double? commissionPercentage;
  final String? address;
  final bool isActive;

  Salesperson({
    required this.id,
    required this.name,
    this.employeeCode,
    this.mobileNumber,
    this.email,
    this.branchId,
    this.commissionPercentage,
    this.address,
    this.isActive = true,
  });

  Salesperson copyWith({
    String? id,
    String? name,
    String? employeeCode,
    String? mobileNumber,
    String? email,
    String? branchId,
    double? commissionPercentage,
    String? address,
    bool? isActive,
  }) {
    return Salesperson(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeCode: employeeCode ?? this.employeeCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      branchId: branchId ?? this.branchId,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
}
