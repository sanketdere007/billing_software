import 'package:flutter/foundation.dart';
import '../models/warehouse.dart';

class WarehouseService extends ChangeNotifier {
  static final WarehouseService _instance = WarehouseService._internal();
  factory WarehouseService() => _instance;
  WarehouseService._internal();

  final List<Warehouse> _warehouses = [];

  List<Warehouse> get warehouses => List.unmodifiable(_warehouses);

  void initializeDummyData() {
    if (_warehouses.isEmpty) {
      _warehouses.addAll([
        Warehouse(
          id: 'WH-001',
          name: 'Central Warehouse',
          code: 'CW',
          branchId: 'BR-001',
          managerName: 'John Doe',
          isActive: true,
        ),
        Warehouse(
          id: 'WH-002',
          name: 'East Godown',
          code: 'EG',
          branchId: 'BR-001',
          managerName: 'Jane Smith',
          isActive: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _warehouses.add(warehouse);
    notifyListeners();
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _warehouses.indexWhere((w) => w.id == warehouse.id);
    if (index != -1) {
      _warehouses[index] = warehouse;
      notifyListeners();
    }
  }

  Future<void> deleteWarehouse(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _warehouses.removeWhere((w) => w.id == id);
    notifyListeners();
  }
}
