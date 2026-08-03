class Supplier {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? gstNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double openingBalance;
  final bool isActive;
  final String? notes;

  Supplier({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.gstNumber,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.openingBalance = 0.0,
    this.isActive = true,
    this.notes,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? gstNumber,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? openingBalance,
    bool? isActive,
    String? notes,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      openingBalance: openingBalance ?? this.openingBalance,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }
}
