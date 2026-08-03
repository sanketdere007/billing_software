import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double childAspectRatio = constraints.maxWidth < 600 ? 1.5 : 2.2;

        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspectRatio, // Adjust card height
          children: [
            _buildKpiCard(
              context,
              "Sales",
              12450.50,
              Icons.trending_up,
              Colors.green,
              true,
            ),
            _buildKpiCard(
              context,
              "Purchase",
              5430.00,
              Icons.shopping_bag,
              Colors.blue,
              false,
            ),
            _buildKpiCard(
              context,
              "Collection",
              9800.00,
              Icons.account_balance_wallet,
              Colors.teal,
              true,
            ),
            _buildKpiCard(
              context,
              "Profit",
              2150.75,
              Icons.monetization_on,
              Colors.green,
              true,
            ),

            _buildKpiCard(
              context,
              "Pending Receivables",
              45600.00,
              Icons.hourglass_empty,
              Colors.orange,
              false,
            ),
            _buildKpiCard(
              context,
              "Pending Payables",
              12400.00,
              Icons.money_off,
              Colors.red,
              false,
            ),

            _buildCountCard(
              context,
              "Total Products",
              3450,
              Icons.inventory_2,
              Colors.cyan,
            ),
            _buildCountCard(
              context,
              "Low Stock Items",
              24,
              Icons.warning_amber,
              Colors.orange,
            ),
            _buildCountCard(
              context,
              "Out of Stock",
              5,
              Icons.error_outline,
              Colors.red,
            ),
            _buildCountCard(
              context,
              "Total Orders",
              156,
              Icons.receipt_long,
              Colors.blueGrey,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    MaterialColor color,
    bool isPositive,
  ) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    return _buildCardBase(
      context,
      title,
      currencyFormatter.format(amount),
      icon,
      color,
      trendIcon: isPositive ? Icons.arrow_upward : Icons.arrow_downward,
      trendColor: isPositive ? Colors.green : Colors.red,
    );
  }

  Widget _buildCountCard(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    MaterialColor color,
  ) {
    final numberFormatter = NumberFormat.decimalPattern();
    return _buildCardBase(
      context,
      title,
      numberFormatter.format(count),
      icon,
      color,
    );
  }

  Widget _buildCardBase(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    MaterialColor color, {
    IconData? trendIcon,
    Color? trendColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? color.shade900.withOpacity(0.4) : color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? color.shade200 : color.shade700,
              size: MediaQuery.of(context).size.width > 600 ? 28 : 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (trendIcon != null) ...[
                      const SizedBox(width: 4),
                      if (MediaQuery.of(context).size.width > 600)
                        const Spacer(),
                      Icon(trendIcon, size: 16, color: trendColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
