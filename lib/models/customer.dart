class Customer {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? gstNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double creditLimit;
  final double openingBalance;
  final bool isActive;
  final String? notes;

  Customer({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.gstNumber,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.creditLimit = 0.0,
    this.openingBalance = 0.0,
    this.isActive = true,
    this.notes,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? gstNumber,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? creditLimit,
    double? openingBalance,
    bool? isActive,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      creditLimit: creditLimit ?? this.creditLimit,
      openingBalance: openingBalance ?? this.openingBalance,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }
}
