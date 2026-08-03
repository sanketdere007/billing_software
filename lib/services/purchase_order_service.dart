import 'package:flutter/foundation.dart';
import '../models/purchase_order.dart';

class PurchaseOrderService extends ChangeNotifier {
  static final PurchaseOrderService _instance = PurchaseOrderService._internal();
  factory PurchaseOrderService() => _instance;
  PurchaseOrderService._internal();

  final List<PurchaseOrder> _orders = [];

  List<PurchaseOrder> get orders => List.unmodifiable(_orders);

  void initializeDummyData() {
    if (_orders.isEmpty) {
      _orders.addAll([
        PurchaseOrder(
          id: 'PO-001',
          orderNo: 'PO-2023-001',
          orderDate: DateTime.now().subtract(const Duration(days: 3)),
          supplierId: 'SUP-001',
          supplierName: 'Apex Suppliers Ltd',
          products: [
            PurchaseOrderProduct(
              id: 'POP-001',
              productId: 'PROD-001',
              productName: 'Raw Materials - Grade A',
              quantity: 50,
              unit: 'KG',
              price: 1200,
              total: 60000,
            )
          ],
          subtotal: 60000,
          grandTotal: 60000,
          balance: 60000,
          status: 'Pending',
        ),
        PurchaseOrder(
          id: 'PO-002',
          orderNo: 'PO-2023-002',
          orderDate: DateTime.now().subtract(const Duration(days: 1)),
          supplierId: 'SUP-002',
          supplierName: 'Prime Distribution Hub',
          products: [
            PurchaseOrderProduct(
              id: 'POP-002',
              productId: 'PROD-002',
              productName: 'Office Packaging Boxes',
              quantity: 500,
              unit: 'PCS',
              price: 25,
              total: 12500,
            )
          ],
          subtotal: 12500,
          grandTotal: 12500,
          paidAmount: 5000,
          balance: 7500,
          status: 'Partially Paid',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addOrder(PurchaseOrder order) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.add(order);
    notifyListeners();
  }

  Future<void> updateOrder(PurchaseOrder order) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
  }
}
