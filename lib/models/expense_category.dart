class ExpenseCategory {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  ExpenseCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
