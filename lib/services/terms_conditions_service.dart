import 'package:flutter/foundation.dart';
import '../models/terms_conditions.dart';

class TermsConditionsService extends ChangeNotifier {
  static final TermsConditionsService _instance = TermsConditionsService._internal();
  factory TermsConditionsService() => _instance;
  TermsConditionsService._internal();

  final List<TermsConditions> _termsList = [];

  List<TermsConditions> get termsList => List.unmodifiable(_termsList);

  void initializeDummyData() {
    if (_termsList.isEmpty) {
      _termsList.addAll([
        TermsConditions(
          id: 'TC-001',
          title: 'Standard Sales Policy',
          terms: '1. Goods once sold will not be taken back.\n2. Subject to local jurisdiction only.',
          displayOnInvoice: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addTerms(TermsConditions terms) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _termsList.add(terms);
    notifyListeners();
  }

  Future<void> updateTerms(TermsConditions terms) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _termsList.indexWhere((t) => t.id == terms.id);
    if (index != -1) {
      _termsList[index] = terms;
      notifyListeners();
    }
  }

  Future<void> deleteTerms(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _termsList.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
