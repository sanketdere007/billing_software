import 'package:flutter/foundation.dart';
import '../models/sales_order.dart';

class SalesOrderService extends ChangeNotifier {
  static final SalesOrderService _instance = SalesOrderService._internal();
  factory SalesOrderService() => _instance;
  SalesOrderService._internal();

  final List<SalesOrder> _orders = [];

  List<SalesOrder> get orders => List.unmodifiable(_orders);

  void initializeDummyData() {
    if (_orders.isEmpty) {
      _orders.addAll([
        SalesOrder(
          id: 'SO-001',
          orderNo: 'ORD-2023-001',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          customerId: 'CUST-001',
          customerName: 'Acme Corp',
          products: [
            SalesOrderProduct(
              id: 'SOP-001',
              productId: 'PROD-001',
              productName: 'Laptop Dell XPS',
              quantity: 2,
              unit: 'PCS',
              price: 85000,
              total: 170000,
            )
          ],
          subtotal: 170000,
          grandTotal: 170000,
          balance: 170000,
          status: 'Pending',
        ),
        SalesOrder(
          id: 'SO-002',
          orderNo: 'ORD-2023-002',
          orderDate: DateTime.now().subtract(const Duration(days: 1)),
          customerId: 'CUST-002',
          customerName: 'Global Industries',
          products: [
            SalesOrderProduct(
              id: 'SOP-002',
              productId: 'PROD-002',
              productName: 'Wireless Mouse',
              quantity: 10,
              unit: 'PCS',
              price: 1500,
              total: 15000,
            )
          ],
          subtotal: 15000,
          grandTotal: 15000,
          paidAmount: 5000,
          balance: 10000,
          status: 'Partially Paid',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addOrder(SalesOrder order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.add(order);
    notifyListeners();
  }

  Future<void> updateOrder(SalesOrder order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
  }
}
