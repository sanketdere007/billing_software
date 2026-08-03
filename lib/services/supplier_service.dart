import 'package:flutter/foundation.dart';
import '../models/supplier.dart';

class SupplierService extends ChangeNotifier {
  // Singleton pattern
  static final SupplierService _instance = SupplierService._internal();
  factory SupplierService() => _instance;
  SupplierService._internal();

  // In-memory list of suppliers
  final List<Supplier> _suppliers = [];

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);

  // Initialize with some dummy data for testing
  void initializeDummyData() {
    if (_suppliers.isEmpty) {
      _suppliers.addAll([
        Supplier(
          id: 'SUP-001',
          name: 'Tech Distributors',
          mobile: '9876541111',
          email: 'sales@techdist.com',
          city: 'Mumbai',
          state: 'Maharashtra',
          isActive: true,
        ),
        Supplier(
          id: 'SUP-002',
          name: 'Global Goods Supplier',
          mobile: '9876542222',
          email: 'info@globalgoods.com',
          city: 'Delhi',
          state: 'Delhi',
          isActive: true,
          openingBalance: 5000.0,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _suppliers.add(supplier);
    notifyListeners();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      _suppliers[index] = supplier;
      notifyListeners();
    }
  }

  Future<void> deleteSupplier(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
