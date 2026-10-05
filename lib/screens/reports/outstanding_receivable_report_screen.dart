import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/outstanding_receivable_report.dart';
import '../../services/report_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/custom_date_picker_field.dart';
import 'package:intl/intl.dart';

import '../../widgets/direct_back_scope.dart';
import 'sales_bill_detail_screen.dart';

class OutstandingReceivableReportScreen extends StatefulWidget {
  const OutstandingReceivableReportScreen({super.key});

  @override
  State<OutstandingReceivableReportScreen> createState() =>
      _OutstandingReceivableReportScreenState();
}

class _OutstandingReceivableReportScreenState
    extends State<OutstandingReceivableReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isExporting = false;
  int _selectedIndex = -1;

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  OutstandingReceivableReportData? _reportData;
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
      if (_reportData == null || _reportData!.invoiceDetails.isEmpty) return;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (_selectedIndex < _reportData!.invoiceDetails.length - 1) {
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
        if (_selectedIndex >= 0 && _selectedIndex < _reportData!.invoiceDetails.length) {
          final inv = _reportData!.invoiceDetails[_selectedIndex];
          _navigateToDetailScreen(inv);
        }
      }
    }
  }

  void _navigateToDetailScreen(OutstandingReceivableInvoiceDetail inv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesBillDetailScreen(
          salesMasterId: inv.salesMasterId,
          invoiceNo: inv.salesMasterInvoiceNo,
          customerName: inv.custName,
          billWiseDiscountPercentage: inv.billWiseDiscountPercentage,
          billWiseDiscountAmount: inv.billWiseDiscountAmount,
          billAmount: inv.billAmount,
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
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
      final response = await reportService.getOutstandingReceivableReport(
        fromDate: _fromDate.toIso8601String(),
        toDate: _toDate.toIso8601String(),
        search: _searchController.text,
      );

      if (mounted) {
        setState(() {
          _reportData = response.data;
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
      final result = await ReportExcelExportService.exportOutstandingReceivable(
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
                          title: const Text('Outstanding Receivable Report'),
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
                title: const Text('Outstanding Receivable'),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
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
                      content: Text(
                        'To Date cannot be earlier than From Date.',
                      ),
                    ),
                  );
                } else {
                  setState(() {
                    _toDate = date;
                  });
                  _fetchReport();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
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

    if (_reportData == null || _reportData!.partyTotals.isEmpty) {
      return const Center(
        child: Text('No outstanding receivable records found.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.35),
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
                    flex: 1,
                    child: Text(
                      'Dis%',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Dis Amt',
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
            // List
            Expanded(
              child: ListView.builder(
                itemCount: _reportData!.partyTotals.length,
                itemBuilder: (context, index) {
                  final partyTotal = _reportData!.partyTotals[index];
                  final invoices = _reportData!.invoiceDetails
                      .where((inv) => inv.custId == partyTotal.custId)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Party Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.5),
                        child: Text(
                          '${partyTotal.custName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Invoices
                      ...invoices.asMap().entries.map(
                        (entry) => _buildInvoiceRow(entry.value, entry.key),
                      ),
                      // Party Total
                      _buildPartyTotalRow(partyTotal),
                    ],
                  );
                },
              ),
            ),
            // Sticky Grand Total
            if (_reportData!.grandTotal != null)
              _buildGrandTotalRow(_reportData!.grandTotal!),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(OutstandingReceivableInvoiceDetail inv, int index) {
    final flatIndex = _reportData!.invoiceDetails.indexOf(inv);
    final isSelected = _selectedIndex == flatIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = flatIndex;
          _focusNode.requestFocus();
        });
        _navigateToDetailScreen(inv);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : null,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 50, child: Text('${index + 1}')),
            Expanded(
              flex: 2,
              child: Text(
                inv.salesMasterInvoiceDate != null
                    ? DateFormat('dd/MM/yyyy').format(inv.salesMasterInvoiceDate!)
                    : '',
              ),
            ),
            Expanded(flex: 2, child: Text(inv.salesMasterInvoiceNo)),
            Expanded(
              flex: 2,
              child: Text(
                inv.billAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                inv.billWiseDiscountPercentage.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                inv.billWiseDiscountAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                inv.balanceAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                inv.daysOutstanding.toString(),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyTotalRow(OutstandingReceivablePartyTotal partyTotal) {
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
      child: Column(
        children: [
          Row(
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
              const Expanded(flex: 1, child: SizedBox()), // Empty space for Dis%
              const Expanded(flex: 2, child: SizedBox()), // Empty space for Dis Amt
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
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildGrandTotalRow(OutstandingReceivableGrandTotal grandTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
      child: Row(
        children: [
          const SizedBox(width: 50),
          const Expanded(
            flex: 4,
            child: Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          const Expanded(flex: 1, child: SizedBox()), // Empty space for Dis%
          const Expanded(flex: 2, child: SizedBox()), // Empty space for Dis Amt
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
}
