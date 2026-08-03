class HsnSac {
  final String id;
  final String code;
  final String? description;
  final String? gstPercentage;
  final bool isActive;

  HsnSac({
    required this.id,
    required this.code,
    this.description,
    this.gstPercentage,
    this.isActive = true,
  });

  HsnSac copyWith({
    String? id,
    String? code,
    String? description,
    String? gstPercentage,
    bool? isActive,
  }) {
    return HsnSac(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      isActive: isActive ?? this.isActive,
    );
  }
}
