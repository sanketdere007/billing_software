class SalesEntryProduct {
  final String id;
  final String productId;
  final String productName;
  final String barcode;
  final double quantity;
  final String unit;
  final double price;
  final double discountPercent;
  final double gstPercent;
  final double taxAmount;
  final double total;

  SalesEntryProduct({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode = '',
    required this.quantity,
    required this.unit,
    required this.price,
    this.discountPercent = 0.0,
    this.gstPercent = 0.0,
    this.taxAmount = 0.0,
    required this.total,
  });
}

class SalesEntry {
  final String id;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String? customerId;
  final String customerName; // "Walk-in" or Actual Name
  final String? salespersonId;
  final String? branchId;
  final String? warehouseId;
  
  final List<SalesEntryProduct> products;
  
  final double totalQuantity;
  final double grossAmount;
  final double discount;
  final double gst;
  final double otherCharges;
  final double roundOff;
  final double grandTotal;
  
  // Payments
  final Map<String, double> payments; // e.g., {'Cash': 500, 'UPI': 200}
  final double amountReceived;
  final double balance;
  final double changeReturn;
  
  final String status; // Completed, Hold, Cancelled
  
  SalesEntry({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    this.customerId,
    required this.customerName,
    this.salespersonId,
    this.branchId,
    this.warehouseId,
    required this.products,
    required this.totalQuantity,
    required this.grossAmount,
    this.discount = 0.0,
    this.gst = 0.0,
    this.otherCharges = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    required this.payments,
    this.amountReceived = 0.0,
    this.balance = 0.0,
    this.changeReturn = 0.0,
    this.status = 'Completed',
  });
}
