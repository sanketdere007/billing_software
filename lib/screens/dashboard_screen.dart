import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dashboard/dashboard_filters.dart';
import '../widgets/dashboard/quick_actions.dart';
import '../widgets/dashboard/summary_cards.dart';
import '../widgets/dashboard/dashboard_charts.dart';
import '../widgets/dashboard/dashboard_sections.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _handleRefresh() async {
    // Simulate a network request
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard refreshed successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        if (isDesktop) {
          // Web / Desktop Layout (Permanent Drawer)
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
                    appBar: AppBar(
                      title: const Text('Overview'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _handleRefresh,
                          tooltip: 'Refresh Dashboard',
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    body: _buildDashboardContent(context, isDesktop, isDark),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Layout (Collapsible Drawer)
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              backgroundColor: isDark ? Colors.grey[900] : Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            drawer: const AppDrawer(isPermanent: false),
            body: _buildDashboardContent(context, isDesktop, isDark),
          );
        }
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, bool isDesktop, bool isDark) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DashboardFilters(
              onDateRangeChanged: (val) {
                // Handle date range change
              },
              onBranchChanged: (val) {
                // Handle branch change
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiding quick action section as requested
                    // const QuickActions(),
                    // const SizedBox(height: 32),
                    
                    const SummaryCards(),
                    const SizedBox(height: 32),
                    
                    const DashboardCharts(),
                    const SizedBox(height: 32),
                    
                    const DashboardSections(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
