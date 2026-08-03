import 'package:flutter/foundation.dart';
import '../models/subcategory.dart';

class SubcategoryService extends ChangeNotifier {
  static final SubcategoryService _instance = SubcategoryService._internal();
  factory SubcategoryService() => _instance;
  SubcategoryService._internal();

  final List<Subcategory> _subcategories = [];
  List<Subcategory> get subcategories => List.unmodifiable(_subcategories);

  void initializeDummyData() {
    if (_subcategories.isEmpty) {
      _subcategories.addAll([
        Subcategory(
          id: 'SUBCAT-001',
          categoryId: 'CAT-001',
          categoryName: 'Electronics',
          name: 'Mobile Phones',
          code: 'MOB',
          description: 'Smartphones and accessories',
          displayOrder: 1,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        Subcategory(
          id: 'SUBCAT-002',
          categoryId: 'CAT-001',
          categoryName: 'Electronics',
          name: 'Laptops',
          code: 'LAP',
          description: 'Laptops and accessories',
          displayOrder: 2,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addSubcategory(Subcategory subcategory) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    _subcategories.add(subcategory);
    notifyListeners();
  }

  Future<void> updateSubcategory(Subcategory subcategory) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    final index = _subcategories.indexWhere((s) => s.id == subcategory.id);
    if (index != -1) {
      _subcategories[index] = subcategory;
      notifyListeners();
    }
  }

  Future<void> deleteSubcategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    _subcategories.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> toggleStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    final index = _subcategories.indexWhere((s) => s.id == id);
    if (index != -1) {
      final current = _subcategories[index];
      _subcategories[index] = current.copyWith(isActive: !current.isActive);
      notifyListeners();
    }
  }

  // Method for server-side like checking if duplicate exists
  bool isDuplicateName(String name, String categoryId, {String? excludeId}) {
    return _subcategories.any((s) => 
      s.categoryId == categoryId && 
      s.name.toLowerCase().trim() == name.toLowerCase().trim() && 
      s.id != excludeId
    );
  }
}
