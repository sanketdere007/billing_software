class Brand {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  Brand({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  Brand copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
