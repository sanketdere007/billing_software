import 'package:flutter/foundation.dart';
import '../models/purchase_return.dart';

class PurchaseReturnService extends ChangeNotifier {
  static final PurchaseReturnService _instance = PurchaseReturnService._internal();
  factory PurchaseReturnService() => _instance;
  PurchaseReturnService._internal();

  final List<PurchaseReturn> _returns = [];

  List<PurchaseReturn> get returns => List.unmodifiable(_returns);

  void initializeDummyData() {
    if (_returns.isEmpty) {
      _returns.addAll([
        PurchaseReturn(
          id: 'PR-001',
          returnNo: 'PRET-2023-001',
          returnDate: DateTime.now().subtract(const Duration(days: 1)),
          invoiceNo: 'PINV-2023-001',
          supplierId: 'SUP-001',
          supplierName: 'Apex Suppliers Ltd',
          products: [
            PurchaseReturnProduct(
              id: 'PRP-001',
              productId: 'PROD-001',
              productName: 'Raw Materials - Grade A',
              returnQuantity: 2,
              unit: 'KG',
              price: 1200,
              taxAmount: 432,
              refundAmount: 2832,
              returnReason: 'Quality mismatch',
            )
          ],
          totalReturnQuantity: 2,
          returnAmount: 2400,
          taxAdjustment: 432,
          grandRefund: 2832,
          refundMode: 'Bank',
          refundStatus: 'Completed',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addReturn(PurchaseReturn returnEntry) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _returns.add(returnEntry);
    notifyListeners();
  }

  Future<void> deleteReturn(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _returns.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
