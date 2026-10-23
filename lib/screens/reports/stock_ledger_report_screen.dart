import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../models/stock_ledger_report.dart';
import '../../services/product_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../services/session_service.dart';
import '../../services/stock_ledger_report_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/custom_date_picker_field.dart';
import '../../widgets/direct_back_scope.dart';

class StockLedgerReportScreen extends StatefulWidget {
  const StockLedgerReportScreen({super.key});

  @override
  State<StockLedgerReportScreen> createState() =>
      _StockLedgerReportScreenState();
}

class _StockLedgerReportScreenState extends State<StockLedgerReportScreen> {
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
  String? _errorMessage;
  List<StockLedgerItem> _reportData = [];
  int _highlightedIndex = 0;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedProductId;
  String _selectedTransactionType = 'All';
  String _selectedType = 'All';

  // Products for dropdown filter
  List<ProductListItem> _productList = [];
  bool _isLoadingProducts = false;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  // Summary totals
  int _totalRecords = 0;
  double _totalInQty = 0.0;
  double _totalOutQty = 0.0;

  @override
  void initState() {
    super.initState();
    sessionService.addListener(_onSessionChanged);
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);

    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

    _loadProducts();
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
    _debounce?.cancel();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      _loadProducts();
      _fetchReport(refresh: true);
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);
    try {
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;
      final products = await productService.getAllProducts(
        compId: compId,
        branchId: branchId,
        isActive: true,
      );
      if (mounted) {
        setState(() {
          _productList = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [StockLedger] Failed to load products: $e');
      if (mounted) setState(() => _isLoadingProducts = false);
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

  Future<void> _fetchMoreData() async {
    if (_isLoading || _isFetchingMore || !_hasMoreData) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _pageNumber + 1;
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await stockLedgerReportService.getStockLedgerReport(
        compId: compId,
        branchId: branchId,
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        productId: _selectedProductId,
        transactionType:
            _selectedTransactionType == 'All' ? null : _selectedTransactionType,
        type: _selectedType == 'All' ? null : _selectedType,
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
            _calculateSummary();
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
        _totalInQty = 0.0;
        _totalOutQty = 0.0;
        _highlightedIndex = 0;
      }
    });

    try {
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await stockLedgerReportService.getStockLedgerReport(
        compId: compId,
        branchId: branchId,
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        productId: _selectedProductId,
        transactionType:
            _selectedTransactionType == 'All' ? null : _selectedTransactionType,
        type: _selectedType == 'All' ? null : _selectedType,
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
            _calculateSummary();
          } else {
            _errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Failed to load stock ledger report';
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

  void _calculateSummary() {
    double inQty = 0.0;
    double outQty = 0.0;

    for (final item in _reportData) {
      final typeUpper = item.stockLedgerType.trim().toUpperCase();
      if (typeUpper == 'IN') {
        inQty += item.quantity.abs();
      } else if (typeUpper == 'OUT') {
        outQty += item.quantity.abs();
      } else {
        if (item.quantity >= 0) {
          inQty += item.quantity;
        } else {
          outQty += item.quantity.abs();
        }
      }
    }

    _totalInQty = inQty;
    _totalOutQty = outQty;
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

  Future<List<StockLedgerItem>> _collectAllReportData() async {
    final allRecords = List<StockLedgerItem>.from(_reportData);
    if (!_hasMoreData) return allRecords;

    var page = _pageNumber + 1;
    const exportPageSize = 200;
    final compId = sessionService.selectedCompId ?? 0;
    final branchId = sessionService.selectedBranchId ?? 0;

    for (var safety = 0; safety < 200; safety++) {
      final response = await stockLedgerReportService.getStockLedgerReport(
        compId: compId,
        branchId: branchId,
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        productId: _selectedProductId,
        transactionType:
            _selectedTransactionType == 'All' ? null : _selectedTransactionType,
        type: _selectedType == 'All' ? null : _selectedType,
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
          'No stock ledger records available to export.',
        );
        return;
      }

      final result = await ReportExcelExportService.exportStockLedger(records);
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
        'Failed to export stock ledger report: $e',
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
    final now = DateTime.now();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _fromDate = DateTime(now.year, now.month, 1);
      _toDate = now;
      _selectedProductId = null;
      _selectedTransactionType = 'All';
      _selectedType = 'All';
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
                              Icon(Icons.history_edu_rounded, size: 22),
                              SizedBox(width: 10),
                              Text('Stock Ledger Report'),
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
                title: const Text('Stock Ledger Report'),
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
                                Icons.history_edu_outlined,
                                size: 54,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No stock ledger transactions found.',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Theme.of(context).hintColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try adjusting the date range or filters.',
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
    final netMovement = _totalInQty - _totalOutQty;

    final cards = [
      _buildCardItem(
        label: 'Total Records',
        value: _totalRecords.toString(),
        icon: Icons.list_alt_rounded,
        color: Colors.indigo,
        isDark: isDark,
      ),
      _buildCardItem(
        label: 'Total IN Qty',
        value: _totalInQty.toStringAsFixed(2),
        icon: Icons.arrow_downward_rounded,
        color: Colors.green,
        isDark: isDark,
      ),
      _buildCardItem(
        label: 'Total OUT Qty',
        value: _totalOutQty.toStringAsFixed(2),
        icon: Icons.arrow_upward_rounded,
        color: Colors.red,
        isDark: isDark,
      ),
      _buildCardItem(
        label: 'Net Movement',
        value: (netMovement >= 0 ? '+' : '') + netMovement.toStringAsFixed(2),
        icon: Icons.swap_vert_rounded,
        color: netMovement >= 0 ? Colors.teal : Colors.deepOrange,
        isDark: isDark,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: isDesktop
          ? Row(
              children: cards
                  .map((c) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: c,
                        ),
                      ))
                  .toList(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: cards
                    .map((c) => SizedBox(
                          width: 170,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: c,
                          ),
                        ))
                    .toList(),
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
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Product / Ref No / Batch',
                          hintText: 'Type to search...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
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
                    Expanded(
                      flex: 1,
                      child: CustomDatePickerField(
                        labelText: 'From Date',
                        initialDate: _fromDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateSelected: (date) {
                          if (_toDate != null && date.isAfter(_toDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'From Date cannot be later than To Date.',
                                ),
                              ),
                            );
                          } else {
                            setState(() => _fromDate = date);
                            _fetchReport(refresh: true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: CustomDatePickerField(
                        labelText: 'To Date',
                        initialDate: _toDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateSelected: (date) {
                          if (_fromDate != null && date.isBefore(_fromDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'To Date cannot be earlier than From Date.',
                                ),
                              ),
                            );
                          } else {
                            setState(() => _toDate = date);
                            _fetchReport(refresh: true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildProductDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTransactionTypeDropdown(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeDropdown(),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset Filters'),
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
            )
          : Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Product / Ref / Batch',
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
                      child: CustomDatePickerField(
                        labelText: 'From Date',
                        initialDate: _fromDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateSelected: (date) {
                          setState(() => _fromDate = date);
                          _fetchReport(refresh: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomDatePickerField(
                        labelText: 'To Date',
                        initialDate: _toDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateSelected: (date) {
                          setState(() => _toDate = date);
                          _fetchReport(refresh: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProductDropdown(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTransactionTypeDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTypeDropdown()),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildProductDropdown() {
    return DropdownButtonFormField<int?>(
      value: _selectedProductId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Filter by Product',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: _isLoadingProducts
            ? const Padding(
                padding: EdgeInsets.all(10.0),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All Products'),
        ),
        ..._productList.map(
          (p) => DropdownMenuItem<int?>(
            value: p.prodId,
            child: Text(
              p.prodName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (val) {
        setState(() => _selectedProductId = val);
        _fetchReport(refresh: true);
      },
    );
  }

  Widget _buildTransactionTypeDropdown() {
    const types = [
      'All',
      'Purchase',
      'Sales',
      'Sales Return',
      'Purchase Return',
      'Stock Adjustment',
    ];

    return DropdownButtonFormField<String>(
      value: _selectedTransactionType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Transaction Type',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: types
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedTransactionType = val);
          _fetchReport(refresh: true);
        }
      },
    );
  }

  Widget _buildTypeDropdown() {
    const types = ['All', 'IN', 'OUT'];

    return DropdownButtonFormField<String>(
      value: _selectedType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Movement Type',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: types
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedType = val);
          _fetchReport(refresh: true);
        }
      },
    );
  }

  Widget _buildRecordsHeader({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_reportData.length} of $_totalRecords records',
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
                    width: 40,
                    child: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product Name',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Batch No',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Transaction Type',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Type',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Ref No.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Before',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'After',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Remark',
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
                  final isTypeIn =
                      item.stockLedgerType.trim().toUpperCase() == 'IN';

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
                            width: 40,
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
                          SizedBox(
                            width: 140,
                            child: Text(
                              item.stockLedgerDate != null
                                  ? _dateFormat.format(item.stockLedgerDate!)
                                  : '-',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.prodName.isNotEmpty
                                  ? item.prodName
                                  : 'Product #${item.stockLedgerProductId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.batchNumber.isNotEmpty
                                  ? item.batchNumber
                                  : '-',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                label: Text(
                                  item.stockLedgerTransactionType.isNotEmpty
                                      ? item.stockLedgerTransactionType
                                      : '-',
                                  style: const TextStyle(fontSize: 10.5),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isTypeIn
                                      ? Colors.green.withOpacity(0.18)
                                      : Colors.red.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.stockLedgerType.isNotEmpty
                                      ? item.stockLedgerType.toUpperCase()
                                      : '-',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isTypeIn
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.stockLedgerReferenceNo.isNotEmpty
                                  ? item.stockLedgerReferenceNo
                                  : '-',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.quantity.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: isTypeIn
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.beforeStock.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.afterStock.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.stockLedgerRemark.isNotEmpty
                                  ? item.stockLedgerRemark
                                  : '-',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
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
        final isTypeIn = item.stockLedgerType.trim().toUpperCase() == 'IN';

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
                        item.prodName.isNotEmpty
                            ? item.prodName
                            : 'Product #${item.stockLedgerProductId}',
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
                        color: isTypeIn
                            ? Colors.green.withOpacity(0.18)
                            : Colors.red.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.stockLedgerType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isTypeIn
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      item.stockLedgerDate != null
                          ? _dateFormat.format(item.stockLedgerDate!)
                          : '-',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (item.batchNumber.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.layers_rounded,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Batch: ${item.batchNumber}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction / Ref',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.stockLedgerTransactionType} ${item.stockLedgerReferenceNo.isNotEmpty ? '(${item.stockLedgerReferenceNo})' : ''}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.quantity.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isTypeIn
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Before: ${item.beforeStock.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 14),
                      Text(
                        'After: ${item.afterStock.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.stockLedgerRemark.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Remark: ${item.stockLedgerRemark}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
