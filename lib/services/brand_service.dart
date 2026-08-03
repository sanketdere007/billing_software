import 'package:flutter/foundation.dart';
import '../models/brand.dart';

class BrandService extends ChangeNotifier {
  static final BrandService _instance = BrandService._internal();
  factory BrandService() => _instance;
  BrandService._internal();

  final List<Brand> _brands = [];
  List<Brand> get brands => List.unmodifiable(_brands);

  void initializeDummyData() {
    if (_brands.isEmpty) {
      _brands.addAll([
        Brand(id: 'BRD-001', name: 'Logitech', description: 'Logitech peripherals'),
        Brand(id: 'BRD-002', name: 'Corsair', description: 'Corsair gaming gear'),
      ]);
      notifyListeners();
    }
  }

  Future<void> addBrand(Brand brand) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _brands.add(brand);
    notifyListeners();
  }

  Future<void> updateBrand(Brand brand) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _brands.indexWhere((b) => b.id == brand.id);
    if (index != -1) {
      _brands[index] = brand;
      notifyListeners();
    }
  }

  Future<void> deleteBrand(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _brands.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
