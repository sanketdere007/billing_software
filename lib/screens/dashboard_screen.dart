import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_date_picker_field.dart';
import '../widgets/dashboard/quick_actions.dart';
import '../widgets/dashboard/summary_cards.dart';
import '../widgets/dashboard/dashboard_charts.dart';
import '../widgets/dashboard/dashboard_sections.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/api_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<DashboardChartsState> _dashboardChartsKey =
      GlobalKey<DashboardChartsState>();
  Map<String, dynamic>? _summaryData;
  bool _isLoading = true;
  String? _summaryError;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchDashboardSummary();
  }

  Future<void> _fetchDashboardSummary() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _summaryError = null;
    });

    try {
      final compId = sessionService.selectedCompId ?? 0;

      // We set fromDate to the start of the day and toDate to the end of the day
      DateTime fromDateApi = DateTime(
        _fromDate.year,
        _fromDate.month,
        _fromDate.day,
      );

      DateTime toDateApi = DateTime(
        _toDate.year,
        _toDate.month,
        _toDate.day,
        23,
        59,
        59,
        999,
      );

      final queryParameters = {
        'CompId': compId.toString(),
        'FromDate': fromDateApi.toIso8601String(),
        'ToDate': toDateApi.toIso8601String(),
        'LowStockQty': '10',
      };

      final response = await apiService.get(
        ApiConstants.getDashboardSummaryEndpoint,
        queryParameters: queryParameters,
      );

      if (mounted) {
        if (response != null && response['status'] == true) {
          setState(() {
            _summaryData = response['data'] is Map<String, dynamic>
                ? response['data']
                : null;
            _summaryError = null;
          });
        } else {
          setState(() {
            _summaryError = response?['message']?.toString() ??
                'Failed to load dashboard summary';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard summary: $e');
      if (mounted) {
        setState(() {
          _summaryError = 'Unable to connect to server. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchDashboardSummary(),
      _dashboardChartsKey.currentState?.fetchChartsData() ?? Future.value(),
    ]);
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
                const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Overview'),
                      actions: [
                        Center(
                          child: SizedBox(
                            width: 140,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: CustomDatePickerField(
                                initialDate: _fromDate,
                                lastDate: DateTime.now(),
                                labelText: 'From Date',
                                onDateSelected: (date) {
                                  if (date.isAfter(_toDate)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'From Date cannot be greater than To Date.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _fromDate = date;
                                  });
                                  _fetchDashboardSummary();
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Center(
                          child: SizedBox(
                            width: 140,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: CustomDatePickerField(
                                initialDate: _toDate,
                                lastDate: DateTime.now(),
                                labelText: 'To Date',
                                onDateSelected: (date) {
                                  if (date.isBefore(_fromDate)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'To Date cannot be smaller than From Date.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _toDate = date;
                                  });
                                  _fetchDashboardSummary();
                                },
                              ),
                            ),
                          ),
                        ),
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
              actions: [
                Center(
                  child: SizedBox(
                    width: 110,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CustomDatePickerField(
                        initialDate: _fromDate,
                        lastDate: DateTime.now(),
                        labelText: 'From',
                        onDateSelected: (date) {
                          if (date.isAfter(_toDate)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'From Date cannot be greater than To Date.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _fromDate = date;
                          });
                          _fetchDashboardSummary();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Center(
                  child: SizedBox(
                    width: 110,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CustomDatePickerField(
                        initialDate: _toDate,
                        lastDate: DateTime.now(),
                        labelText: 'To',
                        onDateSelected: (date) {
                          if (date.isBefore(_fromDate)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'To Date cannot be smaller than From Date.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _toDate = date;
                          });
                          _fetchDashboardSummary();
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _handleRefresh,
                  tooltip: 'Refresh Dashboard',
                ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            body: _buildDashboardContent(context, isDesktop, isDark),
          );
        }
      },
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    bool isDesktop,
    bool isDark,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    SummaryCards(
                      summaryData: _summaryData,
                      isLoading: _isLoading,
                      errorMessage: _summaryError,
                      onRetry: _fetchDashboardSummary,
                    ),
                    const SizedBox(height: 32),

                    DashboardCharts(
                      key: _dashboardChartsKey,
                      fromDate: _fromDate,
                      toDate: _toDate,
                    ),
                    // const SizedBox(height: 32),

                    // const DashboardSections(),
                    // const SizedBox(height: 32),
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
