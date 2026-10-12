import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/batch_wise_stock_report.dart';
import '../../services/batch_wise_stock_report_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class BatchWiseStockReportScreen extends StatefulWidget {
  const BatchWiseStockReportScreen({super.key});

  @override
  State<BatchWiseStockReportScreen> createState() =>
      _BatchWiseStockReportScreenState();
}

class _BatchWiseStockReportScreenState
    extends State<BatchWiseStockReportScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _isExporting = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 30;

  String _searchQuery = '';
  bool _onlyInStock = false;
  int? _selectedProductId;
  String? _errorMessage;
  List<BatchWiseStockItem> _reportData = [];
  int _highlightedIndex = 0;

  int _totalRecords = 0;
  double _totalStock = 0.0;
  double _totalAvailableStock = 0.0;

  @override
  void initState() {
    super.initState();
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
    _screenFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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

  Future<void> _fetchMoreData() async {
    if (_isLoading || _isFetchingMore || !_hasMoreData) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _pageNumber + 1;
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await batchWiseStockReportService.getBatchWiseStockReport(
        compId: compId,
        branchId: branchId,
        productId: _selectedProductId,
        search: _searchQuery,
        onlyInStock: _onlyInStock ? true : null,
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
            _recalculateTotals();
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
        _totalStock = 0.0;
        _totalAvailableStock = 0.0;
        _highlightedIndex = 0;
      }
    });

    try {
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await batchWiseStockReportService.getBatchWiseStockReport(
        compId: compId,
        branchId: branchId,
        productId: _selectedProductId,
        search: _searchQuery,
        onlyInStock: _onlyInStock ? true : null,
        pageNumber: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.data?.items ?? [];
            _totalRecords = response.data?.totalRecords ?? _reportData.length;
            _hasMoreData = _reportData.length == _pageSize;
            _recalculateTotals();
          } else {
            _errorMessage = response.message;
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
        if (!refresh && _reportData.isNotEmpty) {
          _scrollToIndex(_highlightedIndex);
        }
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

  void _recalculateTotals() {
    double stock = 0.0;
    double availableStock = 0.0;
    for (final item in _reportData) {
      stock += item.batchStock;
      availableStock += item.batchAvailableStock;
    }
    _totalStock = stock;
    _totalAvailableStock = availableStock;
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
      const double rowHeight = 53.0;
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

  Future<List<BatchWiseStockItem>> _collectAllReportData() async {
    final allRecords = List<BatchWiseStockItem>.from(_reportData);
    if (!_hasMoreData) return allRecords;

    var page = _pageNumber + 1;
    const exportPageSize = 200;
    final compId = sessionService.selectedCompId ?? 0;
    final branchId = sessionService.selectedBranchId ?? 0;

    for (var safety = 0; safety < 200; safety++) {
      final response =
          await batchWiseStockReportService.getBatchWiseStockReport(
        compId: compId,
        branchId: branchId,
        productId: _selectedProductId,
        search: _searchQuery,
        onlyInStock: _onlyInStock ? true : null,
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
          'No batch stock records available to export.',
        );
        return;
      }

      final result =
          await ReportExcelExportService.exportBatchWiseStock(records);
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
        'Failed to export batch wise stock report: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
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
                          title: const Text('Batch Wise Stock Report'),
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
                title: const Text('Batch Wise Stock Report'),
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
                      ? const Center(
                          child: Text('No batch stock records found.'),
                        )
                      : Column(
                          children: [
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

  Widget _buildFilters({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: isDesktop ? 3 : 2,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('Only In Stock'),
            selected: _onlyInStock,
            avatar: Icon(
              _onlyInStock
                  ? Icons.check_circle_rounded
                  : Icons.inventory_2_outlined,
              size: 18,
            ),
            onSelected: (selected) {
              setState(() {
                _onlyInStock = selected;
              });
              _fetchReport(refresh: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: Column(
          children: [
            // Header Row
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Product Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Unit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total Stock',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Avail Stock',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Landing Price',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Purchase Price',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'MRP',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Selling Price',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Items List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _reportData.length + (_isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _reportData.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = _reportData[index];
                  final isSelected = index == _highlightedIndex;

                  final unitText = item.unitShortName.isNotEmpty
                      ? '${item.prodUnitValue > 0 ? "${item.prodUnitValue} " : ""}${item.unitShortName}'
                      : '-';

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _highlightedIndex = index;
                      });
                    },
                    child: Container(
                      height: 53,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 45,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              item.prodName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              unitText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.batchStock.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.batchStock <= 0
                                    ? Colors.red
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.batchAvailableStock.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.batchAvailableStock <= 0
                                    ? Colors.red
                                    : Colors.teal.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.batchLandingPrice.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.batchPurchasePrice.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.batchMrp.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.batchSellingPrice.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
            itemCount: _reportData.length + (_isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _reportData.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = _reportData[index];
              final isSelected = index == _highlightedIndex;

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _highlightedIndex = index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.prodName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.batchAvailableStock > 0
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: item.batchAvailableStock > 0
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                                ),
                              ),
                              child: Text(
                                'Avail: ${item.batchAvailableStock.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: item.batchAvailableStock > 0
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Batch: ${item.batchNumber.isNotEmpty ? item.batchNumber : "N/A"}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (item.unitShortName.isNotEmpty) ...[
                              const Text(' • '),
                              Text(
                                'Unit: ${item.prodUnitValue > 0 ? "${item.prodUnitValue} " : ""}${item.unitShortName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.batchBarcode.isNotEmpty ||
                            item.batchEanCode.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Barcode: ${item.batchBarcode.isNotEmpty ? item.batchBarcode : item.batchEanCode}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  item.batchStock.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Purchase Price',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹ ${item.batchPurchasePrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MRP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹ ${item.batchMrp.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Selling Price',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹ ${item.batchSellingPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          );
        },
      );
  }
}
