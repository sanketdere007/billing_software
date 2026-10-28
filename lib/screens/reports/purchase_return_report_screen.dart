import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_return.dart';
import '../../services/purchase_return_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/custom_date_picker_field.dart';
import '../../widgets/direct_back_scope.dart';
import 'purchase_return_detail_report_screen.dart';

class PurchaseReturnReportScreen extends StatefulWidget {
  const PurchaseReturnReportScreen({super.key});

  @override
  State<PurchaseReturnReportScreen> createState() =>
      _PurchaseReturnReportScreenState();
}

class _PurchaseReturnReportScreenState
    extends State<PurchaseReturnReportScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _isExporting = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 20;

  String _searchQuery = '';
  String? _errorMessage;
  List<PurchaseReturnMasterViewItem> _reportData = [];
  int _highlightedIndex = 0;

  // Date filters
  DateTime? _fromDate;
  DateTime? _toDate;
  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  // Summary aggregates calculated from loaded data
  int _totalRecords = 0;
  double _sumSubTotal = 0.0;
  double _sumDiscount = 0.0;
  double _sumGST = 0.0;
  double _sumNetAmount = 0.0;
  double _sumRefundAmount = 0.0;
  double _sumBalanceAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);

    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

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
      final compId = sessionService.selectedCompId ?? 1;
      final branchId = sessionService.selectedBranchId ?? 1;

      final fromDateIso = (_fromDate ?? DateTime.now()).toIso8601String();
      final toDateIso = (_toDate ?? DateTime.now())
          .add(const Duration(hours: 23, minutes: 59, seconds: 59))
          .toIso8601String();

      final response = await purchaseReturnService
          .getPurchaseReturnMasterViewList(
            compId: compId,
            branchId: branchId,
            fromDate: fromDateIso,
            toDate: toDateIso,
            search: _searchQuery,
            page: nextPage,
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
        _sumSubTotal = 0.0;
        _sumDiscount = 0.0;
        _sumGST = 0.0;
        _sumNetAmount = 0.0;
        _sumRefundAmount = 0.0;
        _sumBalanceAmount = 0.0;
        _highlightedIndex = 0;
      }
    });

    try {
      final compId = sessionService.selectedCompId ?? 1;
      final branchId = sessionService.selectedBranchId ?? 1;

      final fromDateIso = (_fromDate ?? DateTime.now()).toIso8601String();
      final toDateIso = (_toDate ?? DateTime.now())
          .add(const Duration(hours: 23, minutes: 59, seconds: 59))
          .toIso8601String();

      final response = await purchaseReturnService
          .getPurchaseReturnMasterViewList(
            compId: compId,
            branchId: branchId,
            fromDate: fromDateIso,
            toDate: toDateIso,
            search: _searchQuery,
            page: 1,
            pageSize: _pageSize,
          );

      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.data?.items ?? [];
            _totalRecords = response.data?.totalRecords ?? _reportData.length;
            _calculateSummary();
            _hasMoreData = _reportData.length >= _pageSize;
          } else {
            _errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Failed to load purchase return report';
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

  void _calculateSummary() {
    double subTotal = 0.0;
    double discount = 0.0;
    double gst = 0.0;
    double net = 0.0;
    double refund = 0.0;
    double balance = 0.0;

    for (final item in _reportData) {
      subTotal += item.subTotal;
      discount += item.discountAmount;
      gst += item.gstAmount;
      net += item.netAmount;
      refund += item.refundAmount;
      balance += item.balanceAmount;
    }

    _sumSubTotal = subTotal;
    _sumDiscount = discount;
    _sumGST = gst;
    _sumNetAmount = net;
    _sumRefundAmount = refund;
    _sumBalanceAmount = balance;
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
        _navigateToDetailScreen(_reportData[_highlightedIndex]);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double rowHeight = 52.0;
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

  void _navigateToDetailScreen(PurchaseReturnMasterViewItem item) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                PurchaseReturnDetailReportScreen(masterItem: item),
          ),
        )
        .then((_) {
          if (mounted) {
            _screenFocusNode.requestFocus();
          }
        });
  }

  Future<void> _exportToExcel() async {
    if (_reportData.isEmpty) {
      await showWarningDialog(context, 'No purchase return records to export.');
      return;
    }

    setState(() => _isExporting = true);
    try {
      final result =
          await ReportExcelExportService.exportPurchaseReturnMasterReport(
            _reportData,
          );

      if (!mounted) return;

      if (result.success) {
        await showSuccessDialog(
          context,
          result.filePath != null && result.filePath!.isNotEmpty
              ? 'Purchase Return Report exported successfully to:\n${result.filePath}'
              : result.message,
        );
      } else {
        await showErrorDialog(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to export purchase return report.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        'Failed to export purchase return report: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return _displayFormat.format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'active':
      case 'approved':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'cancelled':
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
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
                          title: const Text('Purchase Return Report'),
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
                title: const Text('Purchase Return Report'),
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
        //if (_reportData.isNotEmpty) _buildSummaryCards(isDesktop: isDesktop),
        Expanded(
          child: _isLoading && _reportData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && _reportData.isEmpty
              ? _buildErrorView()
              : _reportData.isEmpty
              ? _buildEmptyView()
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

  Widget _buildFilters({required bool isDesktop}) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Return No / Supplier',
                  hintText: 'Type invoice number or supplier name...',
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
            Expanded(
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
            const SizedBox(width: 16),
            Expanded(
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
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Return No / Supplier',
              hintText: 'Type return no or supplier...',
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 10),
              Expanded(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({required bool isDesktop}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _buildStatCard(
            title: 'Invoices',
            value: _totalRecords.toString(),
            color: Colors.blueGrey,
            icon: Icons.receipt_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            title: 'Sub Total',
            value: '₹ ${_sumSubTotal.toStringAsFixed(2)}',
            color: Colors.indigo,
            icon: Icons.inventory_2_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            title: 'Discount',
            value: '₹ ${_sumDiscount.toStringAsFixed(2)}',
            color: Colors.orange,
            icon: Icons.discount_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            title: 'GST Amount',
            value: '₹ ${_sumGST.toStringAsFixed(2)}',
            color: Colors.blue,
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            title: 'Net Amount',
            value: '₹ ${_sumNetAmount.toStringAsFixed(2)}',
            color: Colors.deepPurple,
            icon: Icons.monetization_on_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            title: 'Refund Amount',
            value: '₹ ${_sumRefundAmount.toStringAsFixed(2)}',
            color: Colors.teal,
            icon: Icons.assignment_returned_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required MaterialColor color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? color.shade900.withOpacity(0.3)
            : color.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? color.withOpacity(0.4) : color.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isDark ? color.shade200 : color.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? color.shade200 : color.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsHeader({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.18),
      child: Row(
        children: [
          Text(
            'Showing ${_reportData.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (isDesktop)
            Text(
              'Use ↑ / ↓ arrows to navigate • Enter to view items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Table Header Row
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
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
                    flex: 2,
                    child: Text(
                      'Return Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Return No.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Supplier Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Sub Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'GST Amt',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Net Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Expanded(
                  //   flex: 2,
                  //   child: Text(
                  //     'Refund Amt',
                  //     textAlign: TextAlign.right,
                  //     style: TextStyle(fontWeight: FontWeight.bold),
                  //   ),
                  // ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Center(
                      child: Text(
                        'Action',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable List Rows
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
                      setState(() => _highlightedIndex = index);
                      _navigateToDetailScreen(item);
                    },
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(
                                0.35,
                              )
                            : (index % 2 == 1
                                  ? theme.colorScheme.surfaceVariant
                                        .withOpacity(0.08)
                                  : null),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.3,
                            ),
                          ),
                          left: isSelected
                              ? BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 4,
                                )
                              : BorderSide.none,
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
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatDate(item.returnDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.returnNo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.ledgerName.isNotEmpty
                                      ? item.ledgerName
                                      : 'Supplier #${item.supplierId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.supplierMobile.isNotEmpty)
                                  Text(
                                    item.supplierMobile,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.hintColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.subTotal.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.gstAmount.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.netAmount.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Expanded(
                          //   flex: 2,
                          //   child: Text(
                          //     '₹ ${item.refundAmount.toStringAsFixed(2)}',
                          //     textAlign: TextAlign.right,
                          //     style: TextStyle(
                          //       fontWeight: FontWeight.bold,
                          //       fontSize: 13,
                          //       color: Colors.teal.shade700,
                          //     ),
                          //   ),
                          // ),
                          SizedBox(
                            width: 90,
                            child: Center(
                              child: item.status.isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          item.status,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _getStatusColor(item.status),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(item.status),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : const Text('-'),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                tooltip: 'View Return Details',
                                onPressed: () {
                                  setState(() => _highlightedIndex = index);
                                  _navigateToDetailScreen(item);
                                },
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

            // Summary Totals Footer Row
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.28),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 45),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total (${_reportData.length} records):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                  const Expanded(flex: 3, child: SizedBox()),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_sumSubTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_sumGST.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_sumNetAmount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_sumRefundAmount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 90),
                  const SizedBox(width: 70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          elevation: isSelected ? 3 : 1,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor.withOpacity(0.4),
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => _highlightedIndex = index);
              _navigateToDetailScreen(item);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.returnNo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.ledgerName.isNotEmpty
                                  ? item.ledgerName
                                  : 'Supplier #${item.supplierId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹ ${item.netAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDate(item.returnDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refund Amount',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹ ${item.refundAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (item.status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              item.status,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(item.status),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(item.status),
                            ),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => _navigateToDetailScreen(item),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Details'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 52, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load purchase return report',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'An error occurred while fetching report data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _fetchReport(refresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 56,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 14),
          Text(
            'No purchase return records found.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting the date range or search query.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
