import 'package:flutter/foundation.dart';
import '../models/currency.dart';

class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final List<Currency> _currencies = [];

  List<Currency> get currencies => List.unmodifiable(_currencies);

  void initializeDummyData() {
    if (_currencies.isEmpty) {
      _currencies.addAll([
        Currency(id: 'CUR-001', name: 'Indian Rupee', code: 'INR', symbol: '₹', isDefault: true),
        Currency(id: 'CUR-002', name: 'US Dollar', code: 'USD', symbol: '\$', exchangeRate: 83.5),
        Currency(id: 'CUR-003', name: 'Euro', code: 'EUR', symbol: '€', exchangeRate: 90.2),
      ]);
      notifyListeners();
    }
  }

  Future<void> addCurrency(Currency currency) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currencies.add(currency);
    notifyListeners();
  }

  Future<void> updateCurrency(Currency currency) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _currencies.indexWhere((c) => c.id == currency.id);
    if (index != -1) {
      _currencies[index] = currency;
      notifyListeners();
    }
  }

  Future<void> deleteCurrency(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currencies.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
