import 'package:flutter/foundation.dart';
import '../models/sales_return.dart';

class SalesReturnService extends ChangeNotifier {
  static final SalesReturnService _instance = SalesReturnService._internal();
  factory SalesReturnService() => _instance;
  SalesReturnService._internal();

  final List<SalesReturn> _returns = [];

  List<SalesReturn> get returns => List.unmodifiable(_returns);

  void initializeDummyData() {
    if (_returns.isEmpty) {
      _returns.addAll([
        SalesReturn(
          id: 'SR-001',
          returnNo: 'RET-2023-001',
          returnDate: DateTime.now().subtract(const Duration(days: 1)),
          invoiceNo: 'INV-2023-001',
          customerId: 'CUST-001',
          customerName: 'Acme Corp',
          products: [
            SalesReturnProduct(
              id: 'SRP-001',
              productId: 'PROD-001',
              productName: 'Laptop Dell XPS',
              returnQuantity: 1,
              unit: 'PCS',
              price: 85000,
              refundAmount: 85000,
              returnReason: 'Defective screen',
              isDamaged: true,
            )
          ],
          totalReturnQuantity: 1,
          returnAmount: 85000,
          grandRefund: 85000,
          refundMode: 'Credit Note',
          refundStatus: 'Completed',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addReturn(SalesReturn salesReturn) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _returns.add(salesReturn);
    notifyListeners();
  }

  Future<void> updateReturn(SalesReturn salesReturn) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _returns.indexWhere((r) => r.id == salesReturn.id);
    if (index != -1) {
      _returns[index] = salesReturn;
      notifyListeners();
    }
  }

  Future<void> deleteReturn(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _returns.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
