import 'package:flutter/foundation.dart';
import '../models/bank_account.dart';

class BankAccountService extends ChangeNotifier {
  static final BankAccountService _instance = BankAccountService._internal();
  factory BankAccountService() => _instance;
  BankAccountService._internal();

  final List<BankAccount> _bankAccounts = [];

  List<BankAccount> get bankAccounts => List.unmodifiable(_bankAccounts);

  void initializeDummyData() {
    if (_bankAccounts.isEmpty) {
      _bankAccounts.addAll([
        BankAccount(
          id: 'BANK-001',
          bankName: 'State Bank of India',
          accountHolderName: 'Tech Innovators Inc.',
          accountNumber: '12345678901',
          ifscCode: 'SBIN0001234',
          branchName: 'Main Branch',
          openingBalance: 100000.0,
          isActive: true,
        ),
        BankAccount(
          id: 'BANK-002',
          bankName: 'HDFC Bank',
          accountHolderName: 'Tech Innovators Inc.',
          accountNumber: '09876543210',
          ifscCode: 'HDFC0005678',
          openingBalance: 50000.0,
          isActive: true,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addBankAccount(BankAccount bankAccount) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _bankAccounts.add(bankAccount);
    notifyListeners();
  }

  Future<void> updateBankAccount(BankAccount bankAccount) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _bankAccounts.indexWhere((b) => b.id == bankAccount.id);
    if (index != -1) {
      _bankAccounts[index] = bankAccount;
      notifyListeners();
    }
  }

  Future<void> deleteBankAccount(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _bankAccounts.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
