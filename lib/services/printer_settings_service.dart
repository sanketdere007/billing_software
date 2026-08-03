import 'package:flutter/foundation.dart';
import '../models/printer_settings.dart';

class PrinterSettingsService extends ChangeNotifier {
  static final PrinterSettingsService _instance = PrinterSettingsService._internal();
  factory PrinterSettingsService() => _instance;
  PrinterSettingsService._internal();

  final List<PrinterSettings> _settingsList = [];

  List<PrinterSettings> get settingsList => List.unmodifiable(_settingsList);

  void initializeDummyData() {
    if (_settingsList.isEmpty) {
      _settingsList.addAll([
        PrinterSettings(
          id: 'PS-001',
          name: 'POS Thermal Printer',
          type: 'Thermal',
          printWidth: '80mm',
          autoPrint: true,
          isDefault: true,
        ),
        PrinterSettings(
          id: 'PS-002',
          name: 'Office LaserJet',
          type: 'A4',
          paperSize: 'A4',
          autoPrint: false,
          isDefault: false,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addSettings(PrinterSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _settingsList.add(settings);
    notifyListeners();
  }

  Future<void> updateSettings(PrinterSettings settings) async {
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
