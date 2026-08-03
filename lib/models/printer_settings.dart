class PrinterSettings {
  final String id;
  final String name;
  final String type; // Thermal, A4
  final String? paperSize;
  final String? printWidth;
  final bool autoPrint;
  final int numberOfCopies;
  final bool isDefault;
  final bool isActive;

  PrinterSettings({
    required this.id,
    required this.name,
    required this.type,
    this.paperSize,
    this.printWidth,
    this.autoPrint = false,
    this.numberOfCopies = 1,
    this.isDefault = false,
    this.isActive = true,
  });

  PrinterSettings copyWith({
    String? id,
    String? name,
    String? type,
    String? paperSize,
    String? printWidth,
    bool? autoPrint,
    int? numberOfCopies,
    bool? isDefault,
    bool? isActive,
  }) {
    return PrinterSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      paperSize: paperSize ?? this.paperSize,
      printWidth: printWidth ?? this.printWidth,
      autoPrint: autoPrint ?? this.autoPrint,
      numberOfCopies: numberOfCopies ?? this.numberOfCopies,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}
