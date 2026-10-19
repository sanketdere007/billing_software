import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/customer_wise_sales_return_report.dart';
import '../../services/report_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/custom_date_picker_field.dart';
import '../../widgets/direct_back_scope.dart';
import 'sales_return_bill_detail_screen.dart';

class CustomerWiseSalesReturnReportScreen extends StatefulWidget {
  const CustomerWiseSalesReturnReportScreen({super.key});

  @override
  State<CustomerWiseSalesReturnReportScreen> createState() =>
      _CustomerWiseSalesReturnReportScreenState();
}

class _CustomerWiseSalesReturnReportScreenState
    extends State<CustomerWiseSalesReturnReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isExporting = false;
  int _selectedIndex = -1;

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool _onlyOutstanding = false;
  int _pageNumber = 1;
  static const int _pageSize = 100;

  CustomerWiseSalesReturnReportData? _reportData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _fetchReport();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_reportData == null || _reportData!.statement.isEmpty) return;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (_selectedIndex < _reportData!.statement.length - 1) {
            _selectedIndex++;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (_selectedIndex > 0) {
            _selectedIndex--;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_selectedIndex >= 0 &&
            _selectedIndex < _reportData!.statement.length) {
          final item = _reportData!.statement[_selectedIndex];
          _navigateToDetailScreen(item);
        }
      }
    }
  }

  void _navigateToDetailScreen(CustomerWiseSalesReturnStatement item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesReturnBillDetailScreen(
          returnId: item.returnId,
          billNo: item.billNo,
          customerName: item.customerName,
          billAmount: item.billAmount,
          paidAmount: item.paidAmount,
          balanceAmount: item.balanceAmount,
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _pageNumber = 1;
      _fetchReport();
    });
  }

  Future<void> _fetchReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fromDateApi = DateTime(
        _fromDate.year,
        _fromDate.month,
        _fromDate.day,
        0,
        0,
        0,
      );
      final toDateApi = DateTime(
        _toDate.year,
        _toDate.month,
        _toDate.day,
        23,
        59,
        59,
        999,
      );

      final response = await reportService.getCustomerWiseSalesReturnReport(
        fromDate: fromDateApi.toIso8601String(),
        toDate: toDateApi.toIso8601String(),
        search: _searchController.text.trim(),
        onlyOutstanding: _onlyOutstanding,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _reportData = response.data;
          _selectedIndex = -1;
          _isLoading = false;
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

  Future<void> _exportToExcel() async {
    if (_isExporting || _isLoading || _reportData == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final result =
          await ReportExcelExportService.exportCustomerWiseSalesReturn(
        _reportData!,
      );
      if (!mounted) return;

      if (result.success) {
        await showSuccessDialog(context, result.message);
      } else {
        await showErrorDialog(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Failed to export report: $e');
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
          onPressed: _isExporting || _isLoading || _reportData == null
              ? null
              : _exportToExcel,
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
        onPressed: _isExporting || _isLoading || _reportData == null
            ? null
            : _exportToExcel,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              _handleKeyEvent(event);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
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
                          title:
                              const Text('Customer Wise Sales Return Report'),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                              onPressed: _isLoading ? null : _fetchReport,
                            ),
                            const SizedBox(width: 8),
                            ..._exportActions(isDesktop: true),
                            const SizedBox(width: 8),
                          ],
                        ),
                        body: Column(
                          children: [
                            _buildFilters(isDesktop: true),
                            Expanded(child: _buildBodyContent()),
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
                title: const Text('Sales Return Report'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : _fetchReport,
                  ),
                  ..._exportActions(isDesktop: false),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: Column(
                children: [
                  _buildFilters(isDesktop: false),
                  Expanded(child: _buildBodyContent()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters({required bool isDesktop}) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Customer / Bill No',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _pageNumber = 1;
                            _fetchReport();
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
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                onDateSelected: (date) {
                  if (date.isAfter(_toDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('From Date cannot be later than To Date.'),
                      ),
                    );
                  } else {
                    setState(() {
                      _fromDate = date;
                      _pageNumber = 1;
                    });
                    _fetchReport();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDatePickerField(
                labelText: 'To Date',
                initialDate: _toDate,
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                onDateSelected: (date) {
                  if (date.isBefore(_fromDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('To Date cannot be earlier than From Date.'),
                      ),
                    );
                  } else {
                    setState(() {
                      _toDate = date;
                      _pageNumber = 1;
                    });
                    _fetchReport();
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
                  _pageNumber = 1;
                });
                _fetchReport();
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
              labelText: 'Search Customer / Bill No',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _pageNumber = 1;
                        _fetchReport();
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
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  onDateSelected: (date) {
                    if (date.isAfter(_toDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('From Date cannot be later than To Date.'),
                        ),
                      );
                    } else {
                      setState(() {
                        _fromDate = date;
                        _pageNumber = 1;
                      });
                      _fetchReport();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomDatePickerField(
                  labelText: 'To Date',
                  initialDate: _toDate,
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  onDateSelected: (date) {
                    if (date.isBefore(_fromDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('To Date cannot be earlier than From Date.'),
                        ),
                      );
                    } else {
                      setState(() {
                        _toDate = date;
                        _pageNumber = 1;
                      });
                      _fetchReport();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                _pageNumber = 1;
              });
              _fetchReport();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _reportData == null) {
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
            FilledButton(onPressed: _fetchReport, child: const Text('Retry')),
          ],
        ),
      );
    }

    final hasPartyTotals =
        _reportData != null && _reportData!.partyTotals.isNotEmpty;
    final hasStatement =
        _reportData != null && _reportData!.statement.isNotEmpty;

    if (!hasPartyTotals && !hasStatement) {
      return Center(
        child: Text(
          _onlyOutstanding
              ? 'No outstanding sales return records found.'
              : 'No records found.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // Prepare list of party total blocks
    List<CustomerWiseSalesReturnPartyTotal> parties =
        _reportData!.partyTotals;
    if (parties.isEmpty && hasStatement) {
      // Fallback: group statement items by customerId
      final Map<int, List<CustomerWiseSalesReturnStatement>> grouped = {};
      for (var s in _reportData!.statement) {
        grouped.putIfAbsent(s.customerId, () => []).add(s);
      }
      parties = grouped.entries.map((entry) {
        final first = entry.value.first;
        final totalBill = entry.value.fold<double>(
          0.0,
          (sum, e) => sum + e.billAmount,
        );
        final totalPaid = entry.value.fold<double>(
          0.0,
          (sum, e) => sum + e.paidAmount,
        );
        final totalBal = entry.value.fold<double>(
          0.0,
          (sum, e) => sum + e.balanceAmount,
        );
        return CustomerWiseSalesReturnPartyTotal(
          customerId: entry.key,
          customerCode: first.customerCode,
          customerName: first.customerName,
          totalReturns: entry.value.length,
          totalBillAmount: totalBill,
          totalPaidAmount: totalPaid,
          totalBalanceAmount: totalBal,
          rowType: first.rowType,
        );
      }).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Column Header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.35),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
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
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Bill No.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Bill Amt',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Paid Amt',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Bal. Amt',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Days',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Grouped Party List
            Expanded(
              child: ListView.builder(
                itemCount: parties.length,
                itemBuilder: (context, index) {
                  final partyTotal = parties[index];
                  final returns = _reportData!.statement
                      .where((inv) => inv.customerId == partyTotal.customerId)
                      .toList();

                  final displayHeader = partyTotal.customerCode.isNotEmpty
                      ? '${partyTotal.customerName} (${partyTotal.customerCode})'
                      : partyTotal.customerName;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Party Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayHeader,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (partyTotal.totalReturns > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${partyTotal.totalReturns} ${partyTotal.totalReturns == 1 ? 'Return' : 'Returns'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Return Statements for this customer
                      ...returns.asMap().entries.map(
                            (entry) =>
                                _buildReturnRow(entry.value, entry.key),
                          ),

                      // Party Total Summary Row
                      _buildPartyTotalRow(partyTotal),
                    ],
                  );
                },
              ),
            ),

            // Sticky Grand Total
            if (_reportData!.grandTotal != null)
              _buildGrandTotalRow(_reportData!.grandTotal!),

            // Pagination Bar (when totalPages > 1)
            if (_reportData!.grandTotal != null &&
                _reportData!.grandTotal!.totalPages > 1)
              _buildPaginationBar(_reportData!.grandTotal!),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnRow(
    CustomerWiseSalesReturnStatement item,
    int index,
  ) {
    final flatIndex = _reportData!.statement.indexOf(item);
    final isSelected = _selectedIndex == flatIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = flatIndex;
          _focusNode.requestFocus();
        });
        _navigateToDetailScreen(item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : null,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 50, child: Text('${index + 1}')),
            Expanded(
              flex: 2,
              child: Text(
                item.returnDate != null
                    ? DateFormat('dd/MM/yyyy').format(item.returnDate!)
                    : '',
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.billNo,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.billAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.paidAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.balanceAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: item.balanceAmount > 0 ? Colors.red.shade700 : null,
                  fontWeight:
                      item.balanceAmount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                item.days.toString(),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyTotalRow(CustomerWiseSalesReturnPartyTotal partyTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50),
          const Expanded(
            flex: 4,
            child: Text(
              'Party Total :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              partyTotal.totalBillAmount.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              partyTotal.totalPaidAmount.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              partyTotal.totalBalanceAmount.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildGrandTotalRow(CustomerWiseSalesReturnGrandTotal grandTotal) {
    final customerReturnsInfo = grandTotal.totalCustomers > 0
        ? 'Total (${grandTotal.totalCustomers} Customers, ${grandTotal.totalReturns} Returns)'
        : 'Total';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
      child: Row(
        children: [
          const SizedBox(width: 50),
          Expanded(
            flex: 4,
            child: Text(
              customerReturnsInfo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              grandTotal.grandTotalBillAmount.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              grandTotal.grandTotalPaidAmount.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              grandTotal.grandTotalBalanceAmount.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(CustomerWiseSalesReturnGrandTotal grandTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_pageNumber of ${grandTotal.totalPages} (${grandTotal.totalReturns} Returns)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous Page',
                onPressed: _pageNumber > 1 && !_isLoading
                    ? () {
                        setState(() => _pageNumber--);
                        _fetchReport();
                      }
                    : null,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$_pageNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next Page',
                onPressed: _pageNumber < grandTotal.totalPages && !_isLoading
                    ? () {
                        setState(() => _pageNumber++);
                        _fetchReport();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
