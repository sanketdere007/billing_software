import 'package:flutter/foundation.dart';
import '../models/salesperson.dart';

class SalespersonService extends ChangeNotifier {
  static final SalespersonService _instance = SalespersonService._internal();
  factory SalespersonService() => _instance;
  SalespersonService._internal();

  final List<Salesperson> _salespersons = [];

  List<Salesperson> get salespersons => List.unmodifiable(_salespersons);

  void initializeDummyData() {
    if (_salespersons.isEmpty) {
      _salespersons.addAll([
        Salesperson(
          id: 'SP-001',
          name: 'Alice Cooper',
          employeeCode: 'EMP001',
          mobileNumber: '7777777777',
          branchId: 'BR-001',
          commissionPercentage: 5.0,
          isActive: true,
        ),
        Salesperson(
          id: 'SP-002',
          name: 'Bob Builder',
          employeeCode: 'EMP002',
          mobileNumber: '6666666666',
          branchId: 'BR-002',
          commissionPercentage: 3.5,
          isActive: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addSalesperson(Salesperson salesperson) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _salespersons.add(salesperson);
    notifyListeners();
  }

  Future<void> updateSalesperson(Salesperson salesperson) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _salespersons.indexWhere((s) => s.id == salesperson.id);
    if (index != -1) {
      _salespersons[index] = salesperson;
      notifyListeners();
    }
  }

  Future<void> deleteSalesperson(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _salespersons.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
