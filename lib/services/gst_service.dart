import 'package:flutter/foundation.dart';
import '../models/gst.dart';

class GstService extends ChangeNotifier {
  static final GstService _instance = GstService._internal();
  factory GstService() => _instance;
  GstService._internal();

  final List<Gst> _gsts = [];
  List<Gst> get gsts => List.unmodifiable(_gsts);

  void initializeDummyData() {
    if (_gsts.isEmpty) {
      _gsts.addAll([
        Gst(id: 'GST-001', name: 'GST 18%', percentage: 18, cgst: 9, sgst: 9, igst: 18),
        Gst(id: 'GST-002', name: 'GST 12%', percentage: 12, cgst: 6, sgst: 6, igst: 12),
      ]);
      notifyListeners();
    }
  }

  Future<void> addGst(Gst gst) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _gsts.add(gst);
    notifyListeners();
  }

  Future<void> updateGst(Gst gst) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _gsts.indexWhere((g) => g.id == gst.id);
    if (index != -1) {
      _gsts[index] = gst;
      notifyListeners();
    }
  }

  Future<void> deleteGst(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _gsts.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
