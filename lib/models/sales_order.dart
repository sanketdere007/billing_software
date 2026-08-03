class SalesOrderProduct {
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

  SalesOrderProduct({
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

class SalesOrder {
  final String id;
  final String orderNo;
  final DateTime orderDate;
  final String customerId;
  final String customerName;
  final String? salespersonId;
  final String? branchId;
  final String? warehouseId;
  final List<SalesOrderProduct> products;
  
  final double subtotal;
  final double discount;
  final double gst;
  final double roundOff;
  final double grandTotal;
  
  final double paidAmount;
  final double balance;
  
  final String status;
  final String? remarks;
  final String? termsAndConditions;

  SalesOrder({
    required this.id,
    required this.orderNo,
    required this.orderDate,
    required this.customerId,
    required this.customerName,
    this.salespersonId,
    this.branchId,
    this.warehouseId,
    required this.products,
    required this.subtotal,
    this.discount = 0.0,
    this.gst = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    this.paidAmount = 0.0,
    required this.balance,
    required this.status,
    this.remarks,
    this.termsAndConditions,
  });
}
