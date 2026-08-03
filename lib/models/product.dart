class Product {
  final String id;
  final String name;
  final String? code;
  final String? barcode;
  final String category;
  final String brand;
  final String unit;
  final String hsnSac;
  final String gst;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double openingStock;
  final double minimumStock;
  final String? imageUrl;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.code,
    this.barcode,
    required this.category,
    required this.brand,
    required this.unit,
    required this.hsnSac,
    required this.gst,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.mrp = 0.0,
    this.openingStock = 0.0,
    this.minimumStock = 0.0,
    this.imageUrl,
    this.isActive = true,
  });

  Product copyWith({
    String? id,
    String? name,
    String? code,
    String? barcode,
    String? category,
    String? brand,
    String? unit,
    String? hsnSac,
    String? gst,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    double? openingStock,
    double? minimumStock,
    String? imageUrl,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      hsnSac: hsnSac ?? this.hsnSac,
      gst: gst ?? this.gst,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      openingStock: openingStock ?? this.openingStock,
      minimumStock: minimumStock ?? this.minimumStock,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
