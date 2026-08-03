import 'package:flutter/foundation.dart';
import '../models/price_list.dart';

class PriceListService extends ChangeNotifier {
  static final PriceListService _instance = PriceListService._internal();
  factory PriceListService() => _instance;
  PriceListService._internal();

  final List<PriceList> _priceLists = [];

  List<PriceList> get priceLists => List.unmodifiable(_priceLists);

  void initializeDummyData() {
    if (_priceLists.isEmpty) {
      _priceLists.addAll([
        PriceList(
          id: 'PL-001',
          name: 'Standard Retail',
          description: 'Regular retail prices',
          isDefault: true,
          isActive: true,
        ),
        PriceList(
          id: 'PL-002',
          name: 'Wholesale B2B',
          description: 'Discounted prices for B2B',
          isDefault: false,
          isActive: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addPriceList(PriceList priceList) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _priceLists.add(priceList);
    notifyListeners();
  }

  Future<void> updatePriceList(PriceList priceList) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _priceLists.indexWhere((p) => p.id == priceList.id);
    if (index != -1) {
      _priceLists[index] = priceList;
      notifyListeners();
    }
  }

  Future<void> deletePriceList(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _priceLists.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
