import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_shimmer.dart';

class SummaryCards extends StatelessWidget {
  final Map<String, dynamic>? summaryData;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const SummaryCards({
    super.key,
    this.summaryData,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Loading State: Display smooth Shimmer Skeleton UI matching 8 cards layout
    if (isLoading) {
      return const SummaryCardsSkeleton();
    }

    // 2. Error State: Display user-friendly error card with retry option instead of infinite shimmer
    if (errorMessage != null && summaryData == null) {
      return _buildErrorState(context);
    }

    // 3. Empty State: When no summary data exists or is returned null
    if (summaryData == null) {
      return _buildEmptyState(context);
    }

    // 4. Success State: Display actual dashboard summary cards
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

        final double totalSales = (summaryData?['totalSales'] ?? 0).toDouble();
        final double totalPurchase = (summaryData?['totalPurchase'] ?? 0)
            .toDouble();
        final double collection = (summaryData?['collection'] ?? 0).toDouble();
        final double pendingAmount = (summaryData?['pendingAmount'] ?? 0)
            .toDouble();

        final int totalProducts = (summaryData?['totalProducts'] ?? 0).toInt();
        final int lowStockProducts = (summaryData?['lowStockProducts'] ?? 0)
            .toInt();
        final int outOfStockProducts = (summaryData?['outOfStockProducts'] ?? 0)
            .toInt();
        final int totalOrders = (summaryData?['totalSalesOrders'] ?? 0).toInt();

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
              totalSales,
              Icons.trending_up,
              Colors.green,
              true,
            ),
            _buildKpiCard(
              context,
              "Purchase",
              totalPurchase,
              Icons.shopping_bag,
              Colors.blue,
              false,
            ),
            _buildKpiCard(
              context,
              "Collection",
              collection,
              Icons.account_balance_wallet,
              Colors.teal,
              true,
            ),
            _buildKpiCard(
              context,
              "Pending Amount",
              pendingAmount,
              Icons.hourglass_empty,
              Colors.orange,
              false,
            ),

            _buildCountCard(
              context,
              "Total Products",
              totalProducts,
              Icons.inventory_2,
              Colors.cyan,
            ),
            _buildCountCard(
              context,
              "Low Stock Items",
              lowStockProducts,
              Icons.warning_amber,
              Colors.orange,
            ),
            _buildCountCard(
              context,
              "Out of Stock",
              outOfStockProducts,
              Icons.error_outline,
              Colors.red,
            ),
            _buildCountCard(
              context,
              "Total Orders",
              totalOrders,
              Icons.receipt_long,
              Colors.blueGrey,
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(
            'Unable to load summary metrics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage ??
                'An error occurred while loading dashboard metrics.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 44,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No summary metrics available',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'No transactions or inventory data recorded for the selected date range.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
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
