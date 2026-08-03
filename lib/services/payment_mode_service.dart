import 'package:flutter/foundation.dart';
import '../models/payment_mode.dart';

class PaymentModeService extends ChangeNotifier {
  static final PaymentModeService _instance = PaymentModeService._internal();
  factory PaymentModeService() => _instance;
  PaymentModeService._internal();

  final List<PaymentMode> _paymentModes = [];

  List<PaymentMode> get paymentModes => List.unmodifiable(_paymentModes);

  void initializeDummyData() {
    if (_paymentModes.isEmpty) {
      _paymentModes.addAll([
        PaymentMode(id: 'PM-001', name: 'Cash', type: 'Cash', displayOrder: 1, isActive: true),
        PaymentMode(id: 'PM-002', name: 'Credit Card', type: 'Card', displayOrder: 2, isActive: true),
        PaymentMode(id: 'PM-003', name: 'UPI', type: 'UPI', displayOrder: 3, isActive: true),
        PaymentMode(id: 'PM-004', name: 'Bank Transfer', type: 'Bank', displayOrder: 4, isActive: true),
      ]);
      notifyListeners();
    }
  }

  Future<void> addPaymentMode(PaymentMode mode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _paymentModes.add(mode);
    notifyListeners();
  }

  Future<void> updatePaymentMode(PaymentMode mode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _paymentModes.indexWhere((m) => m.id == mode.id);
    if (index != -1) {
      _paymentModes[index] = mode;
      notifyListeners();
    }
  }

  Future<void> deletePaymentMode(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _paymentModes.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
