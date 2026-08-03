class TermsConditions {
  final String id;
  final String title;
  final String terms;
  final bool displayOnInvoice;
  final bool isActive;

  TermsConditions({
    required this.id,
    required this.title,
    required this.terms,
    this.displayOnInvoice = true,
    this.isActive = true,
  });

  TermsConditions copyWith({
    String? id,
    String? title,
    String? terms,
    bool? displayOnInvoice,
    bool? isActive,
  }) {
    return TermsConditions(
      id: id ?? this.id,
      title: title ?? this.title,
      terms: terms ?? this.terms,
      displayOnInvoice: displayOnInvoice ?? this.displayOnInvoice,
      isActive: isActive ?? this.isActive,
    );
  }
}
