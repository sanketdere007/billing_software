import 'package:flutter/foundation.dart';
import '../models/sales_entry.dart';

class SalesEntryService extends ChangeNotifier {
  static final SalesEntryService _instance = SalesEntryService._internal();
  factory SalesEntryService() => _instance;
  SalesEntryService._internal();

  final List<SalesEntry> _entries = [];

  List<SalesEntry> get entries => List.unmodifiable(_entries);

  void initializeDummyData() {
    if (_entries.isEmpty) {
      _entries.addAll([
        SalesEntry(
          id: 'SE-001',
          invoiceNo: 'INV-2023-001',
          invoiceDate: DateTime.now().subtract(const Duration(days: 1)),
          customerId: 'CUST-001',
          customerName: 'Acme Corp',
          products: [
            SalesEntryProduct(
              id: 'SEP-001',
              productId: 'PROD-001',
              productName: 'Laptop Dell XPS',
              quantity: 1,
              unit: 'PCS',
              price: 85000,
              total: 85000,
            )
          ],
          totalQuantity: 1,
          grossAmount: 85000,
          grandTotal: 85000,
          payments: {'Bank Transfer': 85000},
          amountReceived: 85000,
          balance: 0,
          status: 'Completed',
        ),
        SalesEntry(
          id: 'SE-002',
          invoiceNo: 'INV-2023-002',
          invoiceDate: DateTime.now(),
          customerName: 'Walk-in Customer',
          products: [
            SalesEntryProduct(
              id: 'SEP-002',
              productId: 'PROD-003',
              productName: 'Keyboard',
              quantity: 2,
              unit: 'PCS',
              price: 500,
              total: 1000,
            )
          ],
          totalQuantity: 2,
          grossAmount: 1000,
          grandTotal: 1000,
          payments: {'Cash': 1000},
          amountReceived: 1000,
          balance: 0,
          status: 'Completed',
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addEntry(SalesEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _entries.add(entry);
    notifyListeners();
  }

  Future<void> updateEntry(SalesEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
