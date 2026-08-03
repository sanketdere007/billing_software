class BankAccount {
  final String id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String? branchName;
  final String? upiId;
  final double openingBalance;
  final bool isActive;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    this.branchName,
    this.upiId,
    this.openingBalance = 0.0,
    this.isActive = true,
  });

  BankAccount copyWith({
    String? id,
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    String? upiId,
    double? openingBalance,
    bool? isActive,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      branchName: branchName ?? this.branchName,
      upiId: upiId ?? this.upiId,
      openingBalance: openingBalance ?? this.openingBalance,
      isActive: isActive ?? this.isActive,
    );
  }
}
