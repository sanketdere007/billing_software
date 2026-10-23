import 'package:flutter/material.dart';
import '../../services/shortcut_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import 'supplier_outstanding_report_screen.dart';
import 'product_wise_purchase_report_screen.dart';
import 'customer_wise_sales_report_screen.dart';
import 'outstanding_receivable_report_screen.dart';
import 'collection_report_screen.dart';
import 'payment_entry_report_screen.dart';
import 'current_stock_report_screen.dart';
import 'batch_wise_stock_report_screen.dart';
import 'stock_ledger_report_screen.dart';
import 'low_stock_report_screen.dart';
import 'customer_list_report_screen.dart';
import 'product_wise_sales_report_screen.dart';
import 'product_wise_sales_return_report_screen.dart';
import 'customer_wise_sales_return_report_screen.dart';

/// Representation of a single report in the Reports Screen.
class ReportItem {
  final String title;
  final String description;
  final IconData icon;
  final MaterialColor color;
  final Widget Function() screenBuilder;
  final String? routeName;

  const ReportItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screenBuilder,
    this.routeName,
  });
}

/// Representation of a categorized collection of reports.
class ReportCategory {
  final String id;
  final String title;
  final IconData icon;
  final MaterialColor color;
  final List<ReportItem> reports;

  const ReportCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.reports,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  List<ReportCategory> get _categories => [
        ReportCategory(
          id: 'sales',
          title: 'Sales Reports',
          icon: Icons.point_of_sale_rounded,
          color: Colors.cyan,
          reports: [
            ReportItem(
              title: 'Customer Wise Sales',
              description:
                  'Customer sales totals, bill counts, paid amounts & pending balances.',
              icon: Icons.assignment_ind_rounded,
              color: Colors.cyan,
              screenBuilder: () => const CustomerWiseSalesReportScreen(),
            ),
            ReportItem(
              title: 'Product Wise Sales',
              description:
                  'Product-level turnover, quantities sold, and performance statistics.',
              icon: Icons.shopping_bag_rounded,
              color: Colors.cyan,
              screenBuilder: () => const ProductWiseSalesReportScreen(),
            ),
            ReportItem(
              title: 'Customer Wise Sales Return',
              description:
                  'Sales returns, credit notes and returned items broken down by customer.',
              icon: Icons.assignment_return_outlined,
              color: Colors.cyan,
              routeName: AppRoutes.customerWiseSalesReturnReport,
              screenBuilder: () => const CustomerWiseSalesReturnReportScreen(),
            ),
            ReportItem(
              title: 'Product Wise Sales Return',
              description:
                  'Item-wise return quantities, refund totals and return reasons.',
              icon: Icons.assignment_return_rounded,
              color: Colors.cyan,
              screenBuilder: () => const ProductWiseSalesReturnReportScreen(),
            ),
          ],
        ),
        ReportCategory(
          id: 'purchase',
          title: 'Purchase Reports',
          icon: Icons.shopping_cart_checkout_rounded,
          color: Colors.indigo,
          reports: [
            ReportItem(
              title: 'Supplier Outstanding',
              description:
                  'Supplier payables, outstanding dues, credit terms & pending bills.',
              icon: Icons.pie_chart_rounded,
              color: Colors.indigo,
              screenBuilder: () => const SupplierOutstandingReportScreen(),
            ),
            ReportItem(
              title: 'Product Wise Purchase',
              description:
                  'Product purchase totals, quantities, GST, discounts & invoice records.',
              icon: Icons.inventory_2_rounded,
              color: Colors.indigo,
              routeName: AppRoutes.productWisePurchaseReport,
              screenBuilder: () => const ProductWisePurchaseReportScreen(),
            ),
          ],
        ),
        ReportCategory(
          id: 'account',
          title: 'Account Reports',
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.orange,
          reports: [
            ReportItem(
              title: 'Customer Outstanding',
              description:
                  'Accounts receivable statement, aging balances, and customer credit status.',
              icon: Icons.receipt_long_rounded,
              color: Colors.orange,
              screenBuilder: () => const OutstandingReceivableReportScreen(),
            ),
            ReportItem(
              title: 'Collection Report',
              description:
                  'Receipt logs, collections by payment mode, and daily cash/bank inflows.',
              icon: Icons.receipt_long_rounded,
              color: Colors.orange,
              screenBuilder: () => const CollectionReportScreen(),
            ),
            ReportItem(
              title: 'Payment Entry Report',
              description:
                  'Vendor payments, voucher records, payout history and cash disbursements.',
              icon: Icons.payment_rounded,
              color: Colors.orange,
              screenBuilder: () => const PaymentEntryReportScreen(),
            ),
          ],
        ),
        ReportCategory(
          id: 'stock',
          title: 'Stock Reports',
          icon: Icons.inventory_2_rounded,
          color: Colors.teal,
          reports: [
            ReportItem(
              title: 'Current Stock',
              description:
                  'Real-time available stock, warehouse inventory levels, and valuations.',
              icon: Icons.inventory_2_rounded,
              color: Colors.teal,
              screenBuilder: () => const CurrentStockReportScreen(),
            ),
            ReportItem(
              title: 'Batch Wise Stock',
              description:
                  'Stock tracked by batch number, manufacturing date and expiry date.',
              icon: Icons.layers_rounded,
              color: Colors.teal,
              screenBuilder: () => const BatchWiseStockReportScreen(),
            ),
            ReportItem(
              title: 'Stock Ledger Report',
              description:
                  'Detailed audit trail of stock movements, adjustments, purchases and sales.',
              icon: Icons.history_edu_rounded,
              color: Colors.teal,
              routeName: AppRoutes.stockLedgerReport,
              screenBuilder: () => const StockLedgerReportScreen(),
            ),
            ReportItem(
              title: 'Low Stock Report',
              description:
                  'Reorder level alerts, stock shortage, and inventory falling below minimum thresholds.',
              icon: Icons.production_quantity_limits_rounded,
              color: Colors.teal,
              routeName: AppRoutes.lowStockReport,
              screenBuilder: () => const LowStockReportScreen(),
            ),
          ],
        ),
        ReportCategory(
          id: 'other',
          title: 'Other Reports',
          icon: Icons.folder_shared_rounded,
          color: Colors.blueGrey,
          reports: [
            ReportItem(
              title: 'Customer List',
              description:
                  'Complete directory of registered customers with city, area, and route info.',
              icon: Icons.people_alt_rounded,
              color: Colors.blueGrey,
              screenBuilder: () => const CustomerListReportScreen(),
            ),
          ],
        ),
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openReport(ReportItem report) {
    if (report.routeName != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: RouteSettings(name: report.routeName),
          builder: (context) => report.screenBuilder(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => report.screenBuilder(),
        ),
      );
    }
  }

  int get _totalReportsCount {
    int count = 0;
    for (final cat in _categories) {
      count += cat.reports.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            return Scaffold(
              body: Row(
                children: [
                  const SizedBox(
                    width: 250,
                    child: AppDrawer(isPermanent: true),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Scaffold(
                      appBar: _buildAppBar(isDesktop: true),
                      body: _buildBody(isDesktop: true),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: _buildAppBar(isDesktop: false),
            drawer: const AppDrawer(isPermanent: false),
            body: _buildBody(isDesktop: false),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar({required bool isDesktop}) {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.bar_chart_rounded, size: 24),
          SizedBox(width: 10),
          Text(
            'Reports & Analytics',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          Container(
            width: 260,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search all reports...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Colors.white.withOpacity(0.8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody({required bool isDesktop}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter categories and reports
    final filteredCategories = <ReportCategory>[];

    for (final category in _categories) {
      if (_selectedCategoryId != 'all' && category.id != _selectedCategoryId) {
        continue;
      }

      final matchingReports = category.reports.where((r) {
        if (_searchQuery.isEmpty) return true;
        return r.title.toLowerCase().contains(_searchQuery) ||
            r.description.toLowerCase().contains(_searchQuery) ||
            category.title.toLowerCase().contains(_searchQuery);
      }).toList();

      if (matchingReports.isNotEmpty) {
        filteredCategories.add(
          ReportCategory(
            id: category.id,
            title: category.title,
            icon: category.icon,
            color: category.color,
            reports: matchingReports,
          ),
        );
      }
    }

    return Column(
      children: [
        // Top filter header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).cardColor
                : Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDesktop) ...[
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryFilterChip(
                      id: 'all',
                      label: 'All Reports',
                      count: _totalReportsCount,
                      icon: Icons.dashboard_customize_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildCategoryFilterChip(
                          id: cat.id,
                          label: cat.title,
                          count: cat.reports.length,
                          icon: cat.icon,
                          color: cat.color,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reports grid / list
        Expanded(
          child: filteredCategories.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    return _buildCategorySection(
                      context,
                      category,
                      isDesktop: isDesktop,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip({
    required String id,
    required String label,
    required int count,
    required IconData icon,
    required MaterialColor color,
  }) {
    final isSelected = _selectedCategoryId == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? Colors.white
            : (isDark ? color.shade300 : color.shade700),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.25)
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
      selectedColor: color.shade700,
      backgroundColor: isDark
          ? color.shade900.withOpacity(0.2)
          : color.shade50.withOpacity(0.7),
      side: BorderSide(
        color: isSelected
            ? color.shade700
            : (isDark ? color.withOpacity(0.3) : color.shade200),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        setState(() {
          _selectedCategoryId = id;
        });
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ReportCategory category, {
    required bool isDesktop,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? category.color.shade900.withOpacity(0.4)
                      : category.color.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? category.color.withOpacity(0.4)
                        : category.color.shade200,
                  ),
                ),
                child: Icon(
                  category.icon,
                  size: 20,
                  color: isDark
                      ? category.color.shade300
                      : category.color.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.reports.length} ${category.reports.length == 1 ? 'Report' : 'Reports'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cards grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int crossAxisCount = width >= 1200
                  ? 3
                  : (width >= 680 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: category.reports.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 110,
                ),
                itemBuilder: (context, index) {
                  final report = category.reports[index];
                  return _buildReportCard(context, report, category);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    ReportItem report,
    ReportCategory category,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openReport(report),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.25)
                    : Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? report.color.shade900.withOpacity(0.35)
                      : report.color.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? report.color.withOpacity(0.4)
                        : report.color.shade200,
                  ),
                ),
                child: Icon(
                  report.icon,
                  size: 24,
                  color: isDark
                      ? report.color.shade300
                      : report.color.shade700,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      report.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Trailing arrow
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'No reports match "$_searchQuery". Try a different search term.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategoryId = 'all';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}
