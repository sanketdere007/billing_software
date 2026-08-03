import 'package:flutter/foundation.dart';
import '../models/barcode_settings.dart';

class BarcodeSettingsService extends ChangeNotifier {
  static final BarcodeSettingsService _instance = BarcodeSettingsService._internal();
  factory BarcodeSettingsService() => _instance;
  BarcodeSettingsService._internal();

  final List<BarcodeSettings> _settingsList = [];

  List<BarcodeSettings> get settingsList => List.unmodifiable(_settingsList);

  void initializeDummyData() {
    if (_settingsList.isEmpty) {
      _settingsList.addAll([
        BarcodeSettings(
          id: 'BC-001',
          format: 'CODE128',
          prefix: 'ITEM-',
          length: 10,
          labelSize: '50x25 mm',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addSettings(BarcodeSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _settingsList.add(settings);
    notifyListeners();
  }

  Future<void> updateSettings(BarcodeSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _settingsList.indexWhere((s) => s.id == settings.id);
    if (index != -1) {
      _settingsList[index] = settings;
      notifyListeners();
    }
  }

  Future<void> deleteSettings(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _settingsList.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
