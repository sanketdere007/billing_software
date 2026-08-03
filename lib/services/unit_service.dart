import 'package:flutter/foundation.dart';
import '../models/unit.dart';

class UnitService extends ChangeNotifier {
  static final UnitService _instance = UnitService._internal();
  factory UnitService() => _instance;
  UnitService._internal();

  final List<Unit> _units = [];
  List<Unit> get units => List.unmodifiable(_units);

  void initializeDummyData() {
    if (_units.isEmpty) {
      _units.addAll([
        Unit(id: 'UNT-001', name: 'Pieces', shortName: 'PCS', description: 'Item count'),
        Unit(id: 'UNT-002', name: 'Kilograms', shortName: 'KG', description: 'Weight measure'),
      ]);
      notifyListeners();
    }
  }

  Future<void> addUnit(Unit unit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _units.add(unit);
    notifyListeners();
  }

  Future<void> updateUnit(Unit unit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _units.indexWhere((u) => u.id == unit.id);
    if (index != -1) {
      _units[index] = unit;
      notifyListeners();
    }
  }

  Future<void> deleteUnit(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _units.removeWhere((u) => u.id == id);
    notifyListeners();
  }
}
