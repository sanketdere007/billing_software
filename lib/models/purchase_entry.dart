class PurchaseEntryProduct {
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

  PurchaseEntryProduct({
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

class PurchaseEntry {
  final String id;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String supplierId;
  final String supplierName;
  final String? branchId;
  final String? warehouseId;
  
  final List<PurchaseEntryProduct> products;
  
  final double totalQuantity;
  final double grossAmount;
  final double discount;
  final double gst;
  final double otherCharges;
  final double roundOff;
  final double grandTotal;
  
  // Payments
  final Map<String, double> payments;
  final double amountPaid;
  final double balance;
  
  final String status;

  PurchaseEntry({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.supplierId,
    required this.supplierName,
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
    this.payments = const {},
    this.amountPaid = 0.0,
    this.balance = 0.0,
    this.status = 'Completed',
  });
}
