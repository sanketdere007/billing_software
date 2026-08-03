class BarcodeSettings {
  final String id;
  final String format; // CODE128, EAN13, UPCA, QR
  final String? prefix;
  final int length;
  final bool autoGenerate;
  final double width;
  final double height;
  final String? labelSize;
  final int printCopies;
  final bool isActive;

  BarcodeSettings({
    required this.id,
    required this.format,
    this.prefix,
    this.length = 8,
    this.autoGenerate = true,
    this.width = 1.5,
    this.height = 0.5,
    this.labelSize,
    this.printCopies = 1,
    this.isActive = true,
  });

  BarcodeSettings copyWith({
    String? id,
    String? format,
    String? prefix,
    int? length,
    bool? autoGenerate,
    double? width,
    double? height,
    String? labelSize,
    int? printCopies,
    bool? isActive,
  }) {
    return BarcodeSettings(
      id: id ?? this.id,
      format: format ?? this.format,
      prefix: prefix ?? this.prefix,
      length: length ?? this.length,
      autoGenerate: autoGenerate ?? this.autoGenerate,
      width: width ?? this.width,
      height: height ?? this.height,
      labelSize: labelSize ?? this.labelSize,
      printCopies: printCopies ?? this.printCopies,
      isActive: isActive ?? this.isActive,
    );
  }
}
