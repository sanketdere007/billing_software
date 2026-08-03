class Unit {
  final String id;
  final String name;
  final String? shortName;
  final String? description;
  final bool isActive;

  Unit({
    required this.id,
    required this.name,
    this.shortName,
    this.description,
    this.isActive = true,
  });

  Unit copyWith({
    String? id,
    String? name,
    String? shortName,
    String? description,
    bool? isActive,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
