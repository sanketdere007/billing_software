class Warehouse {
  final String id;
  final String name;
  final String? code;
  final String branchId;
  final String? managerName;
  final String? mobileNumber;
  final String? address;
  final String? description;
  final bool isActive;

  Warehouse({
    required this.id,
    required this.name,
    this.code,
    required this.branchId,
    this.managerName,
    this.mobileNumber,
    this.address,
    this.description,
    this.isActive = true,
  });

  Warehouse copyWith({
    String? id,
    String? name,
    String? code,
    String? branchId,
    String? managerName,
    String? mobileNumber,
    String? address,
    String? description,
    bool? isActive,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      branchId: branchId ?? this.branchId,
      managerName: managerName ?? this.managerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
