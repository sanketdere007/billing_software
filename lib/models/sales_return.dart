class SalesReturnProduct {
  final String id;
  final String productId;
  final String productName;
  final double returnQuantity;
  final String unit;
  final double price;
  final double taxAmount;
  final double refundAmount;
  
  final String? returnReason;
  final bool isDamaged;

  SalesReturnProduct({
    required this.id,
    required this.productId,
    required this.productName,
    required this.returnQuantity,
    required this.unit,
    required this.price,
    this.taxAmount = 0.0,
    required this.refundAmount,
    this.returnReason,
    this.isDamaged = false,
  });
}

class SalesReturn {
  final String id;
  final String returnNo;
  final DateTime returnDate;
  final String invoiceNo;
  final String? customerId;
  final String customerName;
  
  final List<SalesReturnProduct> products;
  
  final double totalReturnQuantity;
  final double returnAmount;
  final double taxAdjustment;
  final double grandRefund;
  
  final String refundMode; // Cash, UPI, Bank, Wallet, Credit Note
  final String refundStatus; // Pending, Completed
  
  SalesReturn({
    required this.id,
    required this.returnNo,
    required this.returnDate,
    required this.invoiceNo,
    this.customerId,
    required this.customerName,
    required this.products,
    required this.totalReturnQuantity,
    required this.returnAmount,
    this.taxAdjustment = 0.0,
    required this.grandRefund,
    required this.refundMode,
    this.refundStatus = 'Completed',
  });
}
