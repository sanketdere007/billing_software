import 'package:flutter/foundation.dart';
import '../models/customer.dart';

class CustomerService extends ChangeNotifier {
  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  // In-memory list of customers
  final List<Customer> _customers = [];

  List<Customer> get customers => List.unmodifiable(_customers);

  // Initialize with some dummy data for testing
  void initializeDummyData() {
    if (_customers.isEmpty) {
      _customers.addAll([
        Customer(
          id: 'CUST-001',
          name: 'Acme Corp',
          mobile: '9876543210',
          email: 'contact@acme.com',
          city: 'Mumbai',
          state: 'Maharashtra',
          isActive: true,
          creditLimit: 50000.0,
        ),
        Customer(
          id: 'CUST-002',
          name: 'Global Industries',
          mobile: '9876543211',
          email: 'info@globalind.com',
          city: 'Delhi',
          state: 'Delhi',
          isActive: true,
          openingBalance: 1500.50,
        ),
        Customer(
          id: 'CUST-003',
          name: 'Tech Solutions',
          mobile: '9876543212',
          city: 'Bangalore',
          state: 'Karnataka',
          isActive: false,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _customers.add(customer);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
