import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';

class CategoryService extends ChangeNotifier {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final List<Category> _categories = [];
  List<Category> get categories => List.unmodifiable(_categories);

  void initializeDummyData() {
    if (_categories.isEmpty) {
      _categories.addAll([
        Category(id: 'CAT-001', name: 'Electronics', description: 'All electronic items'),
        Category(id: 'CAT-002', name: 'Furniture', description: 'Office and home furniture'),
      ]);
      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
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
