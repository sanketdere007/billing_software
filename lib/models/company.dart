class Company {
  final String id;
  final String name;
  final String? code;
  final String? gstNumber;
  final String? panNumber;
  final String? email;
  final String? mobileNumber;
  final String? website;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? companyLogo;
  final String? financialYear;
  final String? currency;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    this.code,
    this.gstNumber,
    this.panNumber,
    this.email,
    this.mobileNumber,
    this.website,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.companyLogo,
    this.financialYear,
    this.currency,
    this.isActive = true,
  });

  Company copyWith({
    String? id,
    String? name,
    String? code,
    String? gstNumber,
    String? panNumber,
    String? email,
    String? mobileNumber,
    String? website,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? companyLogo,
    String? financialYear,
    String? currency,
    bool? isActive,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      companyLogo: companyLogo ?? this.companyLogo,
      financialYear: financialYear ?? this.financialYear,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
    );
  }
}
