class Currency {
  final String id;
  final String name;
  final String code;
  final String symbol;
  final int decimalPlaces;
  final double exchangeRate;
  final bool isDefault;
  final bool isActive;

  Currency({
    required this.id,
    required this.name,
    required this.code,
    required this.symbol,
    this.decimalPlaces = 2,
    this.exchangeRate = 1.0,
    this.isDefault = false,
    this.isActive = true,
  });

  Currency copyWith({
    String? id,
    String? name,
    String? code,
    String? symbol,
    int? decimalPlaces,
    double? exchangeRate,
    bool? isDefault,
    bool? isActive,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}
