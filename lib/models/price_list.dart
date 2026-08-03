class PriceList {
  final String id;
  final String name;
  final String? description;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isDefault;
  final bool isActive;

  PriceList({
    required this.id,
    required this.name,
    this.description,
    this.effectiveFrom,
    this.effectiveTo,
    this.isDefault = false,
    this.isActive = true,
  });

  PriceList copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    bool? isDefault,
    bool? isActive,
  }) {
    return PriceList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}
