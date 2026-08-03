class Subcategory {
  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final String code;
  final String? description;
  final int? displayOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.code,
    this.description,
    this.displayOrder,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  Subcategory copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? name,
    String? code,
    String? description,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Subcategory(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
