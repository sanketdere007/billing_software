class Branch {
  final String id;
  final String name;
  final String? code;
  final String companyId;
  final String? gstNumber;
  final String? contactPerson;
  final String? mobileNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    this.code,
    required this.companyId,
    this.gstNumber,
    this.contactPerson,
    this.mobileNumber,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.isActive = true,
  });

  Branch copyWith({
    String? id,
    String? name,
    String? code,
    String? companyId,
    String? gstNumber,
    String? contactPerson,
    String? mobileNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    bool? isActive,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      companyId: companyId ?? this.companyId,
      gstNumber: gstNumber ?? this.gstNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isActive: isActive ?? this.isActive,
    );
  }
}
