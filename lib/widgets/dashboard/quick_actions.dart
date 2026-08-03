import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionCard(context, 'New Bill', Icons.receipt_long, Colors.blue),
              _buildActionCard(context, 'New Purchase', Icons.shopping_cart, Colors.purple),
              _buildActionCard(context, 'Add Customer', Icons.person_add, Colors.orange),
              _buildActionCard(context, 'Add Product', Icons.add_box, Colors.green),
              _buildActionCard(context, 'Receive Payment', Icons.payments, Colors.teal),
              _buildActionCard(context, 'Pay Supplier', Icons.outbox, Colors.red),
              _buildActionCard(context, 'View Reports', Icons.bar_chart, Colors.indigo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      BuildContext context, String title, IconData icon, MaterialColor color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to $title...')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? color.shade900.withOpacity(0.3) : color.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? color.withOpacity(0.5) : color.shade200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: isDark ? color.shade200 : color.shade700),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
