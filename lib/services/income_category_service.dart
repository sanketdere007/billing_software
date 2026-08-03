import 'package:flutter/foundation.dart';
import '../models/income_category.dart';

class IncomeCategoryService extends ChangeNotifier {
  static final IncomeCategoryService _instance = IncomeCategoryService._internal();
  factory IncomeCategoryService() => _instance;
  IncomeCategoryService._internal();

  final List<IncomeCategory> _categories = [];

  List<IncomeCategory> get categories => List.unmodifiable(_categories);

  void initializeDummyData() {
    if (_categories.isEmpty) {
      _categories.addAll([
        IncomeCategory(id: 'IC-001', name: 'Product Sales', description: 'Income from selling products'),
        IncomeCategory(id: 'IC-002', name: 'Services', description: 'Income from services rendered'),
        IncomeCategory(id: 'IC-003', name: 'Interest', description: 'Interest income from banks'),
      ]);
      notifyListeners();
    }
  }

  Future<void> addCategory(IncomeCategory category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(IncomeCategory category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
