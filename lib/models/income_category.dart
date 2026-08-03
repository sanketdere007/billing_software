class IncomeCategory {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  IncomeCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  IncomeCategory copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return IncomeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
