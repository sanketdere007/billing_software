class Gst {
  final String id;
  final String? name;
  final double percentage;
  final double cgst;
  final double sgst;
  final double igst;
  final String? description;
  final bool isActive;

  Gst({
    required this.id,
    this.name,
    required this.percentage,
    required this.cgst,
    required this.sgst,
    required this.igst,
    this.description,
    this.isActive = true,
  });

  Gst copyWith({
    String? id,
    String? name,
    double? percentage,
    double? cgst,
    double? sgst,
    double? igst,
    String? description,
    bool? isActive,
  }) {
    return Gst(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
