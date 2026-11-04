import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_wise_sales_return_report.dart';
import '../../services/product_wise_sales_return_report_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/custom_date_picker_field.dart';
import 'product_wise_sales_return_detail_report_screen.dart';

class ProductWiseSalesReturnReportScreen extends StatefulWidget {
  const ProductWiseSalesReturnReportScreen({super.key});

  @override
  State<ProductWiseSalesReturnReportScreen> createState() =>
      _ProductWiseSalesReturnReportScreenState();
}

class _ProductWiseSalesReturnReportScreenState
    extends State<ProductWiseSalesReturnReportScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 15;

  String? _errorMessage;
  List<ProductWiseSalesReturnItem> _reportData = [];
  int _highlightedIndex = 0;

  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate = DateTime.now();

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
          .getProductWiseSalesReturnReport(
        compId: compId,
        branchId: branchId,
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        search: _searchController.text.trim(),
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

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _reportData.length) {
        _navigateToDetails(_reportData[_highlightedIndex]);
        return KeyEventResult.handled;
      }
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
          .getProductWiseSalesReturnReport(
        compId: compId,
        branchId: branchId,
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        search: _searchController.text.trim(),
        pageNumber: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.items;
            _hasMoreData = response.items.length == _pageSize;
          } else {
            _errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Unknown error';
          }
          _isLoading = false;

          if (_reportData.isNotEmpty) {
            _highlightedIndex =
                _highlightedIndex.clamp(0, _reportData.length - 1);
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

  void _navigateToDetails(ProductWiseSalesReturnItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductWiseSalesReturnDetailReportScreen(
          productId: item.productId,
          productName: item.productName,
          fromDate: _fromDate ?? DateTime.now(),
          toDate: _toDate ?? DateTime.now(),
        ),
      ),
    );
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
                          title: const Text('Product Wise Sales Return Report'),
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
                            _buildFilterRow(isDesktop: true),
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
                title: const Text('Product Wise Sales Return'),
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
                  _buildFilterRow(isDesktop: false),
                  Expanded(child: _buildBodyContent(isDesktop: false)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterRow({required bool isDesktop}) {
    if (!isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchReport(refresh: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _fetchReport(refresh: true);
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomDatePickerField(
                    labelText: 'From Date',
                    initialDate: _fromDate,
                    lastDate: DateTime.now(),
                    onDateSelected: (date) {
                      if (_toDate != null && date.isAfter(_toDate!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('From Date cannot be later than To Date.'),
                          ),
                        );
                      } else {
                        setState(() {
                          _fromDate = date;
                        });
                        _fetchReport(refresh: true);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDatePickerField(
                    labelText: 'To Date',
                    initialDate: _toDate,
                    lastDate: DateTime.now(),
                    onDateSelected: (date) {
                      if (_fromDate != null && date.isBefore(_fromDate!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'To Date cannot be earlier than From Date.'),
                          ),
                        );
                      } else {
                        setState(() {
                          _toDate = date;
                        });
                        _fetchReport(refresh: true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Product',
                hintText: 'Search by product name...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _fetchReport(refresh: true);
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomDatePickerField(
              labelText: 'From Date',
              initialDate: _fromDate,
              lastDate: DateTime.now(),
              onDateSelected: (date) {
                if (_toDate != null && date.isAfter(_toDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('From Date cannot be later than To Date.'),
                    ),
                  );
                } else {
                  setState(() {
                    _fromDate = date;
                  });
                  _fetchReport(refresh: true);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomDatePickerField(
              labelText: 'To Date',
              initialDate: _toDate,
              lastDate: DateTime.now(),
              onDateSelected: (date) {
                if (_fromDate != null && date.isBefore(_fromDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('To Date cannot be earlier than From Date.'),
                    ),
                  );
                } else {
                  setState(() {
                    _toDate = date;
                  });
                  _fetchReport(refresh: true);
                }
              },
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
                const Spacer(),
                Text(
                  'Use ↑ / ↓ arrows to navigate, Enter to view details',
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
                    flex: 3,
                    child: Text(
                      'Product Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Return Entries',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Return Qty',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total Return Amount',
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
                      _navigateToDetails(item);
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
                            flex: 3,
                            child: Text(
                              item.productName.isNotEmpty
                                  ? item.productName
                                  : 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${item.totalReturnEntries}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.totalReturnQty.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.totalReturnAmount.toStringAsFixed(2)}',
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

    double totalQty = 0;
    double totalAmount = 0;
    for (var item in _reportData) {
      totalQty += item.totalReturnQty;
      totalAmount += item.totalReturnAmount;
    }

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
                    _navigateToDetails(item);
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
                                    item.productName.isNotEmpty
                                        ? item.productName
                                        : 'Unknown Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Entries: ${item.totalReturnEntries} • Batches: ${item.totalBatches}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
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
                                  'Return Qty',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.totalReturnQty.toStringAsFixed(2),
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
                                  'Return Amount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹ ${item.totalReturnAmount.toStringAsFixed(2)}',
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
                      'Records: ${_reportData.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Total Qty: ${totalQty.toStringAsFixed(2)}',
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
                      'Total Return',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹ ${totalAmount.toStringAsFixed(2)}',
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
