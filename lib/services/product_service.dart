import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  // Singleton pattern
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);

  void initializeDummyData() {
    if (_products.isEmpty) {
      _products.addAll([
        Product(
          id: 'PROD-001',
          name: 'Wireless Mouse',
          code: 'WM-01',
          category: 'Electronics',
          brand: 'Logitech',
          unit: 'Pieces',
          hsnSac: '8471',
          gst: '18%',
          purchasePrice: 500,
          sellingPrice: 800,
          mrp: 999,
          openingStock: 50,
          minimumStock: 10,
        ),
        Product(
          id: 'PROD-002',
          name: 'Mechanical Keyboard',
          code: 'MK-01',
          category: 'Electronics',
          brand: 'Corsair',
          unit: 'Pieces',
          hsnSac: '8471',
          gst: '18%',
          purchasePrice: 2000,
          sellingPrice: 3500,
          mrp: 4500,
          openingStock: 20,
          minimumStock: 5,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
