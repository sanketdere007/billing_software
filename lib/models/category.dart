class Category {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  Category copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
