class PaymentMode {
  final String id;
  final String name;
  final String type; // Cash, UPI, Card, Bank, Wallet, Cheque
  final String? description;
  final int displayOrder;
  final bool isActive;

  PaymentMode({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
  });

  PaymentMode copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    int? displayOrder,
    bool? isActive,
  }) {
    return PaymentMode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
