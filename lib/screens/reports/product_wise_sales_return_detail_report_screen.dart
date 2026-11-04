import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/product_wise_sales_return_report.dart';
import '../../services/product_wise_sales_return_report_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';

class ProductWiseSalesReturnDetailReportScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final DateTime fromDate;
  final DateTime toDate;

  const ProductWiseSalesReturnDetailReportScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<ProductWiseSalesReturnDetailReportScreen> createState() =>
      _ProductWiseSalesReturnDetailReportScreenState();
}

class _ProductWiseSalesReturnDetailReportScreenState
    extends State<ProductWiseSalesReturnDetailReportScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 15;

  String _searchQuery = '';
  String? _errorMessage;
  List<ProductWiseSalesReturnDetailItem> _reportData = [];
  int _highlightedIndex = 0;

  int _totalRecords = 0;
  double _totalReturnQty = 0.0;
  double _totalFreeQty = 0.0;
  double _totalReturnAmount = 0.0;

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

      final response = await productWiseSalesReturnReportService
          .getProductWiseSalesReturnDetailReport(
        compId: compId,
        branchId: branchId,
        productId: widget.productId,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        search: _searchQuery,
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (response.items.isEmpty) {
            _hasMoreData = false;
          } else {
            _pageNumber = nextPage;
            _reportData.addAll(response.items);
            if (response.items.length < _pageSize) {
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
      const double rowHeight = 58.0;
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

  Future<void> _fetchReport({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _pageNumber = 1;
        _hasMoreData = true;
        _reportData.clear();
        _highlightedIndex = 0;
      }
    });

    try {
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await productWiseSalesReturnReportService
          .getProductWiseSalesReturnDetailReport(
        compId: compId,
        branchId: branchId,
        productId: widget.productId,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        search: _searchQuery,
        pageNumber: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.items;
            _totalRecords = response.totalRecords;
            _totalReturnQty = response.totalReturnQty;
            _totalFreeQty = response.totalFreeQty;
            _totalReturnAmount = response.totalReturnAmount;
            _hasMoreData = response.items.length == _pageSize;
          } else {
            _errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Unknown error';
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

            final appBarTitle = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sales Return Detail: ${widget.productName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${DateFormat('dd MMM yyyy').format(widget.fromDate)} - ${DateFormat('dd MMM yyyy').format(widget.toDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );

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
                          title: appBarTitle,
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                              onPressed: _isLoading
                                  ? null
                                  : () => _fetchReport(refresh: true),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                        body: Column(
                          children: [
                            _buildDesktopFilterBar(),
                            Expanded(child: _buildBodyContent(isDesktop: true)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: appBarTitle,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading
                        ? null
                        : () => _fetchReport(refresh: true),
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: Column(
                children: [
                  _buildMobileFilterBar(),
                  Expanded(child: _buildBodyContent(isDesktop: false)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopFilterBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by Customer, Invoice No, Remark...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                      : Colors.grey.shade50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search customer, invoice, remark...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading && _reportData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _reportData.isEmpty) {
      return Center(
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
            Text(_errorMessage!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _fetchReport(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reportData.isEmpty) {
      return const Center(child: Text('No return records found.'));
    }

    return Column(
      children: [
        if (isDesktop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
            child: Row(
              children: [
                Text(
                  'Showing ${_reportData.length} records',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (_totalReturnQty > 0 || _totalReturnAmount > 0) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Total Qty: ${_totalReturnQty.toStringAsFixed(2)} | Total Amt: ₹ ${_totalReturnAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Use ↑ / ↓ arrows to navigate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        Expanded(
          child: isDesktop ? _buildDesktopDataTable() : _buildMobileList(),
        ),
      ],
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
            // Header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Invoice No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Customer Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Return Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Quantity',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Rate',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // List
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

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _highlightedIndex = index;
                      });
                    },
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(
                                0.3,
                              )
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
                          SizedBox(width: 50, child: Text('${index + 1}')),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.salesReturnMasterInvoiceNo.isNotEmpty
                                      ? item.salesReturnMasterInvoiceNo
                                      : '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.salesReturnMasterRemark.isNotEmpty)
                                  Text(
                                    item.salesReturnMasterRemark,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.customerName.isNotEmpty
                                  ? item.customerName
                                  : 'N/A',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.salesReturnMasterDate != null
                                  ? DateFormat('dd MMM yyyy').format(
                                      item.salesReturnMasterDate!,
                                    )
                                  : '-',
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.salesReturnDetailQty.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '₹ ${item.salesReturnDetailSellingPrice.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.salesReturnDetailTotalAmount.toStringAsFixed(2)}',
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
    final colorScheme = theme.colorScheme;

    double runningQty = 0;
    double runningAmount = 0;
    for (var item in _reportData) {
      runningQty += item.salesReturnDetailQty;
      runningAmount += item.salesReturnDetailTotalAmount;
    }
    final displayQty = _totalReturnQty > 0 ? _totalReturnQty : runningQty;
    final displayAmount = _totalReturnAmount > 0 ? _totalReturnAmount : runningAmount;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withOpacity(0.6),
                  ),
                ),
                color: isSelected
                    ? colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
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
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.salesReturnMasterInvoiceNo.isNotEmpty
                                        ? item.salesReturnMasterInvoiceNo
                                        : 'Return #${item.salesReturnMasterId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.customerName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.customerName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (item.salesReturnMasterDate != null)
                              Text(
                                DateFormat('dd MMM yyyy').format(
                                  item.salesReturnMasterDate!,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        if (item.salesReturnMasterRemark.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.salesReturnMasterRemark,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.salesReturnDetailQty.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rate',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹ ${item.salesReturnDetailSellingPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹ ${item.salesReturnDetailTotalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
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
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.35),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Records: ${_totalRecords > 0 ? _totalRecords : _reportData.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Total Qty: ${displayQty.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹ ${displayAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
