class Role {
  final String id;
  final String name;
  final String? description;
  final Map<String, List<String>> permissions;

  Role({
    required this.id,
    required this.name,
    this.description,
    this.permissions = const {},
  });

  Role copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, List<String>>? permissions,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
    );
  }
}
