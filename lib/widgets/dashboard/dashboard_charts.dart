import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard_charts_model.dart';
import '../../services/dashboard_service.dart';
import 'dashboard_shimmer.dart';

class DashboardCharts extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final int topProducts;

  const DashboardCharts({
    super.key,
    this.fromDate,
    this.toDate,
    this.topProducts = 5,
  });

  @override
  State<DashboardCharts> createState() => DashboardChartsState();
}

class DashboardChartsState extends State<DashboardCharts> {
  DashboardChartsData? _chartsData;
  bool _isLoading = true;
  String? _errorMessage;
  int _touchedPieIndex = -1;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );
  final NumberFormat _compactNumberFormat = NumberFormat.compact();
  String _formatCompactCurrency(num value) =>
      '₹${_compactNumberFormat.format(value)}';

  static const List<Color> _chartPalette = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();
    fetchChartsData();
  }

  @override
  void didUpdateWidget(DashboardCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromDate != oldWidget.fromDate ||
        widget.toDate != oldWidget.toDate ||
        widget.topProducts != oldWidget.topProducts) {
      fetchChartsData();
    }
  }

  /// Public method callable via GlobalKey to refresh chart data
  Future<void> fetchChartsData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await dashboardService.getCharts(
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        topProducts: widget.topProducts,
      );
      if (mounted) {
        setState(() {
          _chartsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Error State: Show user-friendly error message with retry
    if (_errorMessage != null && _chartsData == null) {
      return _buildErrorState(context);
    }

    // 2. Initial Loading State: Display full shimmer skeleton
    if (_isLoading && _chartsData == null) {
      return const DashboardChartsSkeleton();
    }

    // 3. Empty State: When no chart data is available
    if (_chartsData == null && !_isLoading) {
      return _buildOverallEmptyState(context);
    }

    // 4. Success / Refresh State: Display charts layout (with shimmer inside containers if refreshing)
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1000;

        return Column(
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildSalesTrendChart(context)),
                  const SizedBox(width: 24),
                  // Expanded(flex: 1, child: _buildCollectionDonutChart(context)),
                ],
              )
            else ...[
              _buildSalesTrendChart(context),
              const SizedBox(height: 24),
             // _buildCollectionDonutChart(context),
            ],
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildMonthlySalesVsPurchaseChart(context),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildTopSellingProductsChart(context),
                  ),
                ],
              )
            else ...[
              _buildMonthlySalesVsPurchaseChart(context),
              const SizedBox(height: 24),
              _buildTopSellingProductsChart(context),
            ],
          ],
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load charts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ??
                  'An error occurred while loading dashboard charts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchChartsData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No chart data available',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'No sales or product trends recorded for the selected period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: fetchChartsData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(
    BuildContext context,
    String title,
    Widget chart, {
    double height = 320,
    Widget? trailing,
    ChartSkeletonType skeletonType = ChartSkeletonType.bar,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? Shimmer(child: ChartGraphicSkeleton(type: skeletonType))
                : chart,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 38, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. DAILY SALES TREND CHART
  // ==========================================
  Widget _buildSalesTrendChart(BuildContext context) {
    final trendList = _chartsData?.dailySalesTrend ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (trendList.isEmpty && !_isLoading) {
      return _buildChartContainer(
        context,
        'Daily Sales Trend',
        _buildEmptyPlaceholder(
          'No sales trend data available for this range',
          Icons.show_chart_rounded,
        ),
        skeletonType: ChartSkeletonType.line,
      );
    }

    final List<FlSpot> spots = [];
    double maxSales = 0;
    double totalSales = 0;

    for (int i = 0; i < trendList.length; i++) {
      final amt = trendList[i].salesAmount;
      if (amt > maxSales) maxSales = amt;
      totalSales += amt;
      spots.add(FlSpot(i.toDouble(), amt));
    }

    final double effectiveMaxY = maxSales > 0 ? maxSales * 1.2 : 100;
    final int interval = trendList.length > 7
        ? (trendList.length / 5).ceil()
        : 1;

    return _buildChartContainer(
      context,
      'Daily Sales Trend',
      LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      _formatCompactCurrency(value),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index >= 0 && index < trendList.length) {
                    if (index % interval != 0 &&
                        index != trendList.length - 1) {
                      return const SizedBox.shrink();
                    }
                    final item = trendList[index];
                    String label = item.dayName.trim();
                    if (label.isEmpty && item.salesDate != null) {
                      label = DateFormat('dd MMM').format(item.salesDate!);
                    } else if (label.length > 3) {
                      label = label.substring(0, 3);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          minX: 0,
          maxX: max(0, (trendList.length - 1).toDouble()),
          minY: 0,
          maxY: effectiveMaxY,
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade900,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final int index = spot.x.toInt();
                  if (index >= 0 && index < trendList.length) {
                    final item = trendList[index];
                    final dateStr = item.salesDate != null
                        ? DateFormat('dd MMM yyyy').format(item.salesDate!)
                        : item.dayName;
                    return LineTooltipItem(
                      '$dateStr\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'Bills: ${item.totalBills}\n',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Sales: ${_currencyFormat.format(item.salesAmount)}',
                          style: const TextStyle(
                            color: Colors.lightGreenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots.isNotEmpty ? spots : const [FlSpot(0, 0)],
              isCurved: spots.length > 1,
              color: Colors.blue.shade600,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length <= 15,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue.shade700,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.35),
                    Colors.blue.withOpacity(0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      skeletonType: ChartSkeletonType.line,
      trailing: Text(
        'Total: ${_formatCompactCurrency(totalSales)}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        ),
      ),
    );
  }

  // ==========================================
  // 2. PAYMENT COLLECTION DONUT CHART
  // ==========================================
  Widget _buildCollectionDonutChart(BuildContext context) {
    final collections = _chartsData?.paymentCollection ?? [];

    if (collections.isEmpty && !_isLoading) {
      return _buildChartContainer(
        context,
        'Payment Collection',
        _buildEmptyPlaceholder(
          'No collection data available',
          Icons.pie_chart_outline_rounded,
        ),
      );
    }

    final double totalAmount = collections.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final List<PieChartSectionData> sections = [];
    for (int i = 0; i < collections.length; i++) {
      final item = collections[i];
      final color = _chartPalette[i % _chartPalette.length];
      final isTouched = i == _touchedPieIndex;
      final double pct = item.percentage > 0
          ? item.percentage
          : (totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0.0);

      sections.add(
        PieChartSectionData(
          color: color,
          value: item.amount > 0
              ? item.amount
              : (item.percentage > 0 ? item.percentage : 1.0),
          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
          radius: isTouched ? 55 : 45,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return _buildChartContainer(
      context,
      'Payment Collection',
      trailing: Text(
        'Total: ${_formatCompactCurrency(totalAmount)}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.teal,
        ),
      ),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: sections.isNotEmpty
                    ? sections
                    : [
                        PieChartSectionData(
                          color: Colors.grey.shade400,
                          value: 1,
                          title: '',
                          radius: 40,
                        ),
                      ],
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: collections.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final color = _chartPalette[idx % _chartPalette.length];
                  final double pct = item.percentage > 0
                      ? item.percentage
                      : (totalAmount > 0
                            ? (item.amount / totalAmount) * 100
                            : 0.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.collectionType.isNotEmpty
                                ? item.collectionType
                                : 'Other',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. MONTHLY SALES VS PURCHASE CHART
  // ==========================================
  Widget _buildMonthlySalesVsPurchaseChart(BuildContext context) {
    final monthlyList = _chartsData?.monthlySalesVsPurchase ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (monthlyList.isEmpty && !_isLoading) {
      return _buildChartContainer(
        context,
        'Monthly Sales vs Purchase',
        _buildEmptyPlaceholder(
          'No monthly sales vs purchase data available',
          Icons.bar_chart_rounded,
        ),
        skeletonType: ChartSkeletonType.bar,
      );
    }

    double maxVal = 0;
    for (final item in monthlyList) {
      if (item.salesAmount > maxVal) maxVal = item.salesAmount;
      if (item.purchaseAmount > maxVal) maxVal = item.purchaseAmount;
    }
    final double effectiveMaxY = maxVal > 0 ? maxVal * 1.2 : 1000;

    final barGroups = monthlyList.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      return BarChartGroupData(
        x: idx,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: item.salesAmount,
            color: const Color(0xFF10B981), // Emerald
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
          BarChartRodData(
            toY: item.purchaseAmount,
            color: const Color(0xFF3B82F6), // Royal Blue
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return _buildChartContainer(
      context,
      'Monthly Sales vs Purchase',
      BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: effectiveMaxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade900,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex >= 0 && groupIndex < monthlyList.length) {
                  final item = monthlyList[groupIndex];
                  final isSales = rodIndex == 0;
                  final typeName = isSales ? 'Sales' : 'Purchase';
                  final amount = isSales
                      ? item.salesAmount
                      : item.purchaseAmount;
                  return BarTooltipItem(
                    '${item.monthName} ${item.year}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '$typeName: ${_currencyFormat.format(amount)}',
                        style: TextStyle(
                          color: isSales
                              ? Colors.lightGreenAccent
                              : Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }
                return null;
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      _formatCompactCurrency(value),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index >= 0 && index < monthlyList.length) {
                    final item = monthlyList[index];
                    String label = item.monthName.trim();
                    if (label.length > 3) {
                      label = label.substring(0, 3);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
      skeletonType: ChartSkeletonType.bar,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBadge(const Color(0xFF10B981), 'Sales'),
          const SizedBox(width: 8),
          _buildBadge(const Color(0xFF3B82F6), 'Purchase'),
        ],
      ),
    );
  }

  // ==========================================
  // 4. TOP SELLING PRODUCTS CHART
  // ==========================================
  Widget _buildTopSellingProductsChart(BuildContext context) {
    final products = _chartsData?.topSellingProducts ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (products.isEmpty && !_isLoading) {
      return _buildChartContainer(
        context,
        'Top Selling Products',
        _buildEmptyPlaceholder(
          'No top selling products data available',
          Icons.inventory_2_outlined,
        ),
        skeletonType: ChartSkeletonType.bar,
      );
    }

    double maxQty = 0;
    for (final p in products) {
      if (p.totalQty > maxQty) maxQty = p.totalQty;
    }
    final double effectiveMaxY = maxQty > 0 ? maxQty * 1.2 : 100;

    final barGroups = products.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final color = _chartPalette[idx % _chartPalette.length];
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: item.totalQty,
            color: color,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      );
    }).toList();

    return _buildChartContainer(
      context,
      'Top Selling Products',
      BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: effectiveMaxY,
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      NumberFormat.compact().format(value),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index >= 0 && index < products.length) {
                    final item = products[index];
                    String label = item.productName.trim();
                    if (label.length > 8) {
                      label = '${label.substring(0, 7)}…';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade900,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex >= 0 && groupIndex < products.length) {
                  final item = products[groupIndex];
                  return BarTooltipItem(
                    '${item.productName}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Quantity: ${NumberFormat('#,##0.##').format(item.totalQty)}\n',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Amount: ${_currencyFormat.format(item.totalAmount)}\n',
                        style: const TextStyle(
                          color: Colors.lightGreenAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: 'Bills: ${item.totalBills}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  );
                }
                return null;
              },
            ),
          ),
          barGroups: barGroups,
        ),
      ),
      skeletonType: ChartSkeletonType.bar,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'By Quantity',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
