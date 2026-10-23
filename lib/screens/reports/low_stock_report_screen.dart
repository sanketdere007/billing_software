import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/low_stock_report.dart';
import '../../services/low_stock_report_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class LowStockReportScreen extends StatefulWidget {
  const LowStockReportScreen({super.key});

  @override
  State<LowStockReportScreen> createState() => _LowStockReportScreenState();
}

class _LowStockReportScreenState extends State<LowStockReportScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _thresholdController =
      TextEditingController(text: '10');
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _isExporting = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 30;

  String _searchQuery = '';
  double _lowStockQty = 10.0;
  String? _errorMessage;
  List<LowStockItem> _reportData = [];
  int _highlightedIndex = 0;

  // Summary
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    sessionService.addListener(_onSessionChanged);
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);

    _fetchReport(refresh: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    sessionService.removeListener(_onSessionChanged);
    _screenFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _thresholdController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      _fetchReport(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreData();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchReport(refresh: true);
      }
    });
  }

  void _onThresholdChanged(String val) {
    final parsed = double.tryParse(val.trim());
    if (parsed != null && parsed >= 0) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        setState(() {
          _lowStockQty = parsed;
        });
        _fetchReport(refresh: true);
      });
    }
  }

  Future<void> _fetchMoreData() async {
    if (_isLoading || _isFetchingMore || !_hasMoreData) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _pageNumber + 1;
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await lowStockReportService.getLowStockReport(
        compId: compId,
        branchId: branchId,
        lowStockQty: _lowStockQty,
        search: _searchQuery,
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          final newItems = response.data?.items ?? [];
          if (newItems.isEmpty) {
            _hasMoreData = false;
          } else {
            _pageNumber = nextPage;
            _reportData.addAll(newItems);
            if (newItems.length < _pageSize) {
              _hasMoreData = false;
            }
          }
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  Future<void> _fetchReport({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _pageNumber = 1;
        _hasMoreData = true;
        _reportData.clear();
        _totalRecords = 0;
        _highlightedIndex = 0;
      }
    });

    try {
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await lowStockReportService.getLowStockReport(
        compId: compId,
        branchId: branchId,
        lowStockQty: _lowStockQty,
        search: _searchQuery,
        pageNumber: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.data?.items ?? [];
            _totalRecords = response.data?.totalRecords ?? _reportData.length;
            _hasMoreData = _reportData.length == _pageSize;
          } else {
            _errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Failed to load low stock report';
          }
          _isLoading = false;

          if (_reportData.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(
              0,
              _reportData.length - 1,
            );
          } else {
            _highlightedIndex = 0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _reportData.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _reportData.length;
        }
      });
      _scrollToIndex(_highlightedIndex);

      if (_highlightedIndex >= _reportData.length - 5) {
        _fetchMoreData();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _reportData.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double rowHeight = 48.0;
      final targetOffset = index * rowHeight;
      final currentOffset = _scrollController.offset;
      final viewportHeight = _scrollController.position.viewportDimension;
      final maxOffset = _scrollController.position.maxScrollExtent;

      if (targetOffset < currentOffset) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxOffset),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      } else if (targetOffset + rowHeight > currentOffset + viewportHeight) {
        _scrollController.animateTo(
          (targetOffset + rowHeight - viewportHeight).clamp(0.0, maxOffset),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<List<LowStockItem>> _collectAllReportData() async {
    final allRecords = List<LowStockItem>.from(_reportData);
    if (!_hasMoreData) return allRecords;

    var page = _pageNumber + 1;
    const exportPageSize = 200;
    final compId = sessionService.selectedCompId ?? 0;
    final branchId = sessionService.selectedBranchId ?? 0;

    for (var safety = 0; safety < 200; safety++) {
      final response = await lowStockReportService.getLowStockReport(
        compId: compId,
        branchId: branchId,
        lowStockQty: _lowStockQty,
        search: _searchQuery,
        pageNumber: page,
        pageSize: exportPageSize,
      );
      final newItems = response.data?.items ?? [];
      if (newItems.isEmpty) break;
      allRecords.addAll(newItems);
      if (newItems.length < exportPageSize) break;
      page++;
    }
    return allRecords;
  }

  Future<void> _exportToExcel() async {
    if (_isExporting || _isLoading) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final records = await _collectAllReportData();
      if (!mounted) return;

      if (records.isEmpty) {
        await showWarningDialog(
          context,
          'No low stock records available to export.',
        );
        return;
      }

      final result = await ReportExcelExportService.exportLowStock(records);
      if (!mounted) return;

      if (result.success) {
        await showSuccessDialog(context, result.message);
      } else {
        await showErrorDialog(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        'Failed to export low stock report: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _thresholdController.text = '10';
      _lowStockQty = 10.0;
    });
    _fetchReport(refresh: true);
  }

  List<Widget> _exportActions({required bool isDesktop}) {
    if (isDesktop) {
      return [
        OutlinedButton.icon(
          onPressed: _isExporting || _isLoading ? null : _exportToExcel,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.table_view_outlined, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Export to Excel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ];
    }

    return [
      IconButton(
        icon: _isExporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_rounded),
        tooltip: 'Export to Excel',
        onPressed: _isExporting || _isLoading ? null : _exportToExcel,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: DirectBackScope(
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
                        appBar: AppBar(
                          title: const Row(
                            children: [
                              Icon(Icons.production_quantity_limits_rounded,
                                  size: 22),
                              SizedBox(width: 10),
                              Text('Low Stock Report'),
                            ],
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                              onPressed: _isLoading
                                  ? null
                                  : () => _fetchReport(refresh: true),
                            ),
                            const SizedBox(width: 8),
                            ..._exportActions(isDesktop: true),
                            const SizedBox(width: 8),
                          ],
                        ),
                        body: _buildBodyContent(isDesktop: true),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Low Stock Report'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading
                        ? null
                        : () => _fetchReport(refresh: true),
                  ),
                  ..._exportActions(isDesktop: false),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: _buildBodyContent(isDesktop: false),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBodyContent({required bool isDesktop}) {
    return Column(
      children: [
        _buildFilters(isDesktop: isDesktop),
        _buildSummaryCards(isDesktop: isDesktop),
        Expanded(
          child: _isLoading && _reportData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && _reportData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load report',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _fetchReport(refresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _reportData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 54,
                                color: Colors.green.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No low stock products found!',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All inventory levels are above $_lowStockQty units.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            _buildRecordsHeader(isDesktop: isDesktop),
                            Expanded(
                              child: isDesktop
                                  ? _buildDesktopDataTable()
                                  : _buildMobileList(),
                            ),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards({required bool isDesktop}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = _buildCardItem(
      label: 'Low Stock Items',
      value: _totalRecords.toString(),
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
      isDark: isDark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: isDesktop ? 240 : double.infinity,
          child: card,
        ),
      ),
    );
  }

  Widget _buildCardItem({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      color: isDark ? color.shade900.withOpacity(0.25) : color.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? color.shade800.withOpacity(0.4)
                    : color.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? color.shade300 : color.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? color.shade200 : color.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Product',
                      hintText: 'Type to search...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _thresholdController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Threshold Qty',
                      hintText: 'e.g. 10',
                      prefixIcon: Icon(
                        Icons.filter_alt_outlined,
                        size: 18,
                      ),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: _onThresholdChanged,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Product',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _thresholdController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Threshold Qty',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: _onThresholdChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildRecordsHeader({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_reportData.length} of $_totalRecords low stock items',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
          ),
          if (_isFetchingMore)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 6),
                Text('Loading more...', style: TextStyle(fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header Row
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 45,
                    child: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Product Name',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Unit',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Unit Value',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Available Stock',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      'Status',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Data List
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                itemCount: _reportData.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
                itemBuilder: (context, index) {
                  final item = _reportData[index];
                  final isHighlighted = index == _highlightedIndex;
                  final isOutOfStock = item.availableStock <= 0;

                  return InkWell(
                    onTap: () {
                      setState(() => _highlightedIndex = index);
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      color: isHighlighted
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : index.isEven
                              ? (isDark
                                  ? Colors.white.withOpacity(0.015)
                                  : Colors.grey.shade50.withOpacity(0.5))
                              : Colors.transparent,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 45,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              item.productName.isNotEmpty
                                  ? item.productName
                                  : 'Product #${item.batchProductId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.unitShortName.isNotEmpty
                                  ? item.unitShortName
                                  : '-',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.unitValue > 0
                                  ? item.unitValue.toStringAsFixed(2)
                                  : '-',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.availableStock.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isOutOfStock
                                    ? Colors.red.shade700
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? Colors.red.withOpacity(0.18)
                                      : Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOutOfStock
                                        ? Colors.red.withOpacity(0.4)
                                        : Colors.amber.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOutOfStock
                                        ? Colors.red.shade700
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _reportData.length,
      itemBuilder: (context, index) {
        final item = _reportData[index];
        final isOutOfStock = item.availableStock <= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName.isNotEmpty
                            ? item.productName
                            : 'Product #${item.batchProductId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red.withOpacity(0.18)
                            : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock
                              ? Colors.red.shade700
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Unit: ${item.unitShortName} ${item.unitValue > 0 ? '(Val: ${item.unitValue})' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Available: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          item.availableStock.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? Colors.red.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
