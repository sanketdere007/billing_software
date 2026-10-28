import 'package:flutter/material.dart';
import '../../reports/purchase_entry_report_screen.dart';

export '../../reports/purchase_entry_report_screen.dart';

/// PurchaseEntryListScreen forwards directly to [PurchaseEntryReportScreen]
/// to avoid duplicate screens and ensure unified API integration for purchase entries.
class PurchaseEntryListScreen extends StatelessWidget {
  const PurchaseEntryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PurchaseEntryReportScreen();
  }
}
