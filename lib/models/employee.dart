class Employee {
  // Personal Information
  final String id; // Employee Code
  final String firstName;
  final String lastName;
  final String mobile;
  final String? alternateMobile;
  final String? email;
  final DateTime? dob;
  final String? gender;
  final String? profilePhoto;

  // Employment Information
  final String employeeId;
  final String designation;
  final String? department;
  final String branch;
  final DateTime joiningDate;
  final String? employmentType; // Full Time / Part Time / Contract
  final String? reportingManager;
  final String? shift;
  final double? salary;
  final double? commissionPercentage;

  // Address Information
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;

  // Login Information
  final String? username;
  final String? password;
  final String? role;
  final bool allowLogin;

  // Other Information
  final String? aadhaarNumber;
  final String? panNumber;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? notes;
  final bool isActive;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.alternateMobile,
    this.email,
    this.dob,
    this.gender,
    this.profilePhoto,
    required this.employeeId,
    required this.designation,
    this.department,
    required this.branch,
    required this.joiningDate,
    this.employmentType,
    this.reportingManager,
    this.shift,
    this.salary,
    this.commissionPercentage,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.username,
    this.password,
    this.role,
    this.allowLogin = false,
    this.aadhaarNumber,
    this.panNumber,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.notes,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName';

  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? mobile,
    String? alternateMobile,
    String? email,
    DateTime? dob,
    String? gender,
    String? profilePhoto,
    String? employeeId,
    String? designation,
    String? department,
    String? branch,
    DateTime? joiningDate,
    String? employmentType,
    String? reportingManager,
    String? shift,
    double? salary,
    double? commissionPercentage,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? username,
    String? password,
    String? role,
    bool? allowLogin,
    String? aadhaarNumber,
    String? panNumber,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? notes,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      alternateMobile: alternateMobile ?? this.alternateMobile,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      branch: branch ?? this.branch,
      joiningDate: joiningDate ?? this.joiningDate,
      employmentType: employmentType ?? this.employmentType,
      reportingManager: reportingManager ?? this.reportingManager,
      shift: shift ?? this.shift,
      salary: salary ?? this.salary,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      allowLogin: allowLogin ?? this.allowLogin,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      panNumber: panNumber ?? this.panNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}
