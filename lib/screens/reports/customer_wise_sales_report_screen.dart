import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/customer_wise_sales_report.dart';
import '../../services/customer_wise_sales_report_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/custom_date_picker_field.dart';

class CustomerWiseSalesReportScreen extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const CustomerWiseSalesReportScreen({
    super.key,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  State<CustomerWiseSalesReportScreen> createState() =>
      _CustomerWiseSalesReportScreenState();
}

class _CustomerWiseSalesReportScreenState
    extends State<CustomerWiseSalesReportScreen> {
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
  bool _onlyOutstanding = false;
  String? _errorMessage;
  List<CustomerWiseSalesReportItem> _reportData = [];
  int _highlightedIndex = 0;

  int _totalRecords = 0;
  double _totalSales = 0.0;
  double _totalReceived = 0.0;
  double _totalOutstanding = 0.0;
  int _totalInvoicesCount = 0;

  DateTime? _fromDate;
  DateTime? _toDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);

    final now = DateTime.now();
    _toDate = widget.initialToDate != null
        ? DateTime(widget.initialToDate!.year, widget.initialToDate!.month, widget.initialToDate!.day)
        : DateTime(now.year, now.month, now.day);
    _fromDate = widget.initialFromDate != null
        ? DateTime(widget.initialFromDate!.year, widget.initialFromDate!.month, widget.initialFromDate!.day)
        : DateTime(_toDate!.year, _toDate!.month, _toDate!.day - 7);

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

  CustomerWiseSalesReportRequest _buildRequest({required int page, int pageSize = _pageSize}) {
    final compId = sessionService.selectedCompId ?? 0;
    final branchId = sessionService.selectedBranchId ?? 0;

    return CustomerWiseSalesReportRequest(
      compId: compId,
      branchId: branchId,
      fromDate: _fromDate != null ? _dateFormat.format(_fromDate!) : '',
      toDate: _toDate != null ? _dateFormat.format(_toDate!) : '',
      searchText: _searchQuery,
      onlyOutstanding: _onlyOutstanding,
      pageNumber: page,
      pageSize: pageSize,
    );
  }

  Future<void> _fetchMoreData() async {
    if (_isLoading || _isFetchingMore || !_hasMoreData) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _pageNumber + 1;
      final request = _buildRequest(page: nextPage);
      final response =
          await customerWiseSalesReportService.getCustomerWiseSalesReport(request);

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
        _totalSales = 0.0;
        _totalReceived = 0.0;
        _totalOutstanding = 0.0;
        _totalInvoicesCount = 0;
        _highlightedIndex = 0;
      }
    });

    try {
      final request = _buildRequest(page: 1);
      final response =
          await customerWiseSalesReportService.getCustomerWiseSalesReport(request);

      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.data?.items ?? [];
            _totalRecords = response.data?.totalRecords ?? _reportData.length;
            _calculateSummary();
            _hasMoreData = _reportData.length == _pageSize;
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

  void _calculateSummary() {
    double sales = 0.0;
    double received = 0.0;
    double outstanding = 0.0;
    int invoices = 0;

    for (final item in _reportData) {
      sales += item.totalSales;
      received += item.totalReceived;
      outstanding += item.totalOutstanding;
      invoices += item.totalInvoices;
    }

    _totalSales = sales;
    _totalReceived = received;
    _totalOutstanding = outstanding;
    _totalInvoicesCount = invoices;
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

    if (key == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _reportData.length) {
        _showCustomerDetailsDialog(_reportData[_highlightedIndex]);
        return KeyEventResult.handled;
      }
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

  Future<List<CustomerWiseSalesReportItem>> _collectAllReportData() async {
    final allRecords = List<CustomerWiseSalesReportItem>.from(_reportData);
    if (!_hasMoreData) return allRecords;

    var page = _pageNumber + 1;
    const exportPageSize = 200;
    for (var safety = 0; safety < 200; safety++) {
      final request = _buildRequest(page: page, pageSize: exportPageSize);
      final response =
          await customerWiseSalesReportService.getCustomerWiseSalesReport(request);
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
          'No customer sales records available to export.',
        );
        return;
      }

      final result =
          await ReportExcelExportService.exportCustomerWiseSalesReport(records);
      if (!mounted) return;

      if (result.success) {
        await showSuccessDialog(context, result.message);
      } else {
        await showErrorDialog(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
          context, 'Failed to export customer sales report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showCustomerDetailsDialog(CustomerWiseSalesReportItem item) {
    final theme = Theme.of(context);

    Widget buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.mobileNo.isNotEmpty)
                      Text(
                        item.mobileNo,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.billingAddress.isNotEmpty)
                    buildRow('Billing Address', item.billingAddress),
                  if (item.gstNo.isNotEmpty)
                    buildRow('GST No', item.gstNo),
                  const Divider(height: 16),
                  buildRow('Total Invoices', '${item.totalInvoices}'),
                  buildRow('Total Quantity', item.totalQty.toStringAsFixed(2)),
                  buildRow('Sub Total', '₹ ${item.subTotal.toStringAsFixed(2)}'),
                  if (item.itemDiscount > 0)
                    buildRow('Item Discount', '₹ ${item.itemDiscount.toStringAsFixed(2)}'),
                  if (item.billWiseDiscount > 0)
                    buildRow('Bill Discount', '₹ ${item.billWiseDiscount.toStringAsFixed(2)}'),
                  if (item.totalCGST > 0)
                    buildRow('CGST', '₹ ${item.totalCGST.toStringAsFixed(2)}'),
                  if (item.totalSGST > 0)
                    buildRow('SGST', '₹ ${item.totalSGST.toStringAsFixed(2)}'),
                  if (item.totalIGST > 0)
                    buildRow('IGST', '₹ ${item.totalIGST.toStringAsFixed(2)}'),
                  if (item.totalCESS > 0)
                    buildRow('CESS', '₹ ${item.totalCESS.toStringAsFixed(2)}'),
                  if (item.totalRoundOff != 0)
                    buildRow('Round Off', '₹ ${item.totalRoundOff.toStringAsFixed(2)}'),
                  const Divider(height: 16),
                  buildRow(
                    'Total Sales',
                    '₹ ${item.totalSales.toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: theme.colorScheme.primary,
                  ),
                  buildRow(
                    'Total Received',
                    '₹ ${item.totalReceived.toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: Colors.green.shade700,
                  ),
                  buildRow(
                    'Total Outstanding',
                    '₹ ${item.totalOutstanding.toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: item.totalOutstanding > 0 ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                  const Divider(height: 16),
                  if (item.firstSaleDate != null)
                    buildRow('First Sale Date', _displayFormat.format(item.firstSaleDate!)),
                  if (item.lastSaleDate != null)
                    buildRow('Last Sale Date', _displayFormat.format(item.lastSaleDate!)),
                  if (item.salesMasterInvoiceDate != null)
                    buildRow('Last Invoice Date', _displayFormat.format(item.salesMasterInvoiceDate!)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
                          title: const Text('Customer Wise Sales Report'),
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
                title: const Text('Customer Wise Sales Report'),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
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
                          child: Text('No customer sales records found.'),
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
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Customer / Mobile',
                  hintText: 'Type customer name or mobile...',
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
              flex: 2,
              child: CustomDatePickerField(
                labelText: 'From Date',
                initialDate: _fromDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
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
              flex: 2,
              child: CustomDatePickerField(
                labelText: 'To Date',
                initialDate: _toDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  if (_fromDate != null && date.isBefore(_fromDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('To Date cannot be earlier than From Date.'),
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
            const SizedBox(width: 16),
            FilterChip(
              label: const Text('Only Outstanding'),
              selected: _onlyOutstanding,
              avatar: Icon(
                _onlyOutstanding
                    ? Icons.check_circle_rounded
                    : Icons.account_balance_wallet_outlined,
                size: 18,
              ),
              onSelected: (selected) {
                setState(() {
                  _onlyOutstanding = selected;
                });
                _fetchReport(refresh: true);
              },
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
              labelText: 'Search Customer / Mobile',
              hintText: 'Type customer name...',
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
          const SizedBox(height: 12),
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
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onDateSelected: (date) {
                    if (_fromDate != null && date.isBefore(_fromDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('To Date cannot be earlier than From Date.'),
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
          const SizedBox(height: 8),
          FilterChip(
            label: const Text('Only Outstanding'),
            selected: _onlyOutstanding,
            avatar: Icon(
              _onlyOutstanding
                  ? Icons.check_circle_rounded
                  : Icons.account_balance_wallet_outlined,
              size: 18,
            ),
            onSelected: (selected) {
              setState(() {
                _onlyOutstanding = selected;
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
            // Header
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
                    flex: 2,
                    child: Text(
                      'Invoice Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Customer Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Mobile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total Qty',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total Sales',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Received',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Outstanding',
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

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _highlightedIndex = index;
                      });
                    },
                    onDoubleTap: () => _showCustomerDetailsDialog(item),
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
                            flex: 2,
                            child: Text(
                              item.salesMasterInvoiceDate != null
                                  ? _displayFormat.format(item.salesMasterInvoiceDate!)
                                  : (item.lastSaleDate != null
                                      ? _displayFormat.format(item.lastSaleDate!)
                                      : '-'),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.gstNo.isNotEmpty)
                                  Text(
                                    'GST: ${item.gstNo}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.mobileNo.isNotEmpty ? item.mobileNo : '-',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.totalQty.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.totalSales.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.totalReceived.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${item.totalOutstanding.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: item.totalOutstanding > 0
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
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
            // Footer
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 45,
                    child: Text(
                      '$_totalRecords',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                  const Expanded(
                    flex: 4,
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                  const Expanded(flex: 2, child: SizedBox()),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_totalSales.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_totalReceived.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_totalOutstanding.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _totalOutstanding > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
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
                    _showCustomerDetailsDialog(item);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                item.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.mobileNo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Mobile: ${item.mobileNo}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Date: ${item.salesMasterInvoiceDate != null ? _displayFormat.format(item.salesMasterInvoiceDate!) : (item.lastSaleDate != null ? _displayFormat.format(item.lastSaleDate!) : '-')}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Text(' • '),
                            Text(
                              'Qty: ${item.totalQty.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
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
                                  'Sales',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹ ${item.totalSales.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Received',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹ ${item.totalReceived.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Outstanding',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹ ${item.totalOutstanding.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: item.totalOutstanding > 0
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
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
            color: theme.colorScheme.primaryContainer.withOpacity(0.35),
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Records: $_totalRecords',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Sales: ₹ ${_totalSales.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Due: ₹ ${_totalOutstanding.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _totalOutstanding > 0 ? Colors.red.shade700 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
