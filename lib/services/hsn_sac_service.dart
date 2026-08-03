import 'package:flutter/foundation.dart';
import '../models/hsn_sac.dart';

class HsnSacService extends ChangeNotifier {
  static final HsnSacService _instance = HsnSacService._internal();
  factory HsnSacService() => _instance;
  HsnSacService._internal();

  final List<HsnSac> _hsnSacs = [];
  List<HsnSac> get hsnSacs => List.unmodifiable(_hsnSacs);

  void initializeDummyData() {
    if (_hsnSacs.isEmpty) {
      _hsnSacs.addAll([
        HsnSac(id: 'HSN-001', code: '8471', description: 'Automatic data processing machines', gstPercentage: '18%'),
        HsnSac(id: 'HSN-002', code: '8517', description: 'Telephone sets', gstPercentage: '18%'),
      ]);
      notifyListeners();
    }
  }

  Future<void> addHsnSac(HsnSac hsnSac) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _hsnSacs.add(hsnSac);
    notifyListeners();
  }

  Future<void> updateHsnSac(HsnSac hsnSac) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _hsnSacs.indexWhere((h) => h.id == hsnSac.id);
    if (index != -1) {
      _hsnSacs[index] = hsnSac;
      notifyListeners();
    }
  }

  Future<void> deleteHsnSac(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _hsnSacs.removeWhere((h) => h.id == id);
    notifyListeners();
  }
}
