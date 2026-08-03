import 'package:flutter/foundation.dart';
import '../models/company.dart';

class CompanyService extends ChangeNotifier {
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  final List<Company> _companies = [];

  List<Company> get companies => List.unmodifiable(_companies);

  void initializeDummyData() {
    if (_companies.isEmpty) {
      _companies.addAll([
        Company(
          id: 'COMP-001',
          name: 'Tech Innovators Inc.',
          code: 'TI',
          gstNumber: '29ABCDE1234F1Z5',
          email: 'contact@techinnovators.com',
          city: 'Bangalore',
          state: 'Karnataka',
          isActive: true,
        ),
        Company(
          id: 'COMP-002',
          name: 'Global Trade Corp',
          code: 'GTC',
          gstNumber: '27XYZAB5678F1Z9',
          email: 'info@globaltrade.com',
          city: 'Mumbai',
          state: 'Maharashtra',
          isActive: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addCompany(Company company) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _companies.add(company);
    notifyListeners();
  }

  Future<void> updateCompany(Company company) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _companies.indexWhere((c) => c.id == company.id);
    if (index != -1) {
      _companies[index] = company;
      notifyListeners();
    }
  }

  Future<void> deleteCompany(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _companies.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
