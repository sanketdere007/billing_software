import 'package:flutter/foundation.dart';
import '../models/expense_category.dart';

class ExpenseCategoryService extends ChangeNotifier {
  static final ExpenseCategoryService _instance = ExpenseCategoryService._internal();
  factory ExpenseCategoryService() => _instance;
  ExpenseCategoryService._internal();

  final List<ExpenseCategory> _categories = [];

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);

  void initializeDummyData() {
    if (_categories.isEmpty) {
      _categories.addAll([
        ExpenseCategory(id: 'EC-001', name: 'Office Supplies', description: 'Pens, paper, staples, etc.'),
        ExpenseCategory(id: 'EC-002', name: 'Travel', description: 'Flight, train, bus tickets'),
        ExpenseCategory(id: 'EC-003', name: 'Meals', description: 'Business lunches and dinners'),
      ]);
      notifyListeners();
    }
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(ExpenseCategory category) async {
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
