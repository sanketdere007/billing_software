import 'package:flutter/material.dart';
import '../../models/customer.dart';
import 'customer_master_screen.dart';

export 'customer_master_screen.dart';

/// Compatibility wrapper for AddCustomerScreen
class AddCustomerScreen extends StatelessWidget {
  final CustomerListItem? customerToEdit;
  final int? customerId;

  const AddCustomerScreen({
    super.key,
    this.customerToEdit,
    this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerMasterScreen(
      customerToEdit: customerToEdit,
      customerId: customerId,
    );
  }
}
