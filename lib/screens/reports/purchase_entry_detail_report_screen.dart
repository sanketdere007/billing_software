import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_entry.dart';
import '../../services/purchase_entry_service.dart';
import '../../services/session_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class PurchaseEntryDetailReportScreen extends StatefulWidget {
  final PurchaseMasterViewItem masterItem;

  const PurchaseEntryDetailReportScreen({
    super.key,
    required this.masterItem,
  });

  @override
  State<PurchaseEntryDetailReportScreen> createState() =>
      _PurchaseEntryDetailReportScreenState();
}

class _PurchaseEntryDetailReportScreenState
    extends State<PurchaseEntryDetailReportScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  List<PurchaseDetailViewItem> _details = [];

  double _totalQty = 0.0;
  double _totalGross = 0.0;
  double _totalProductDiscount = 0.0;
  double _billWiseDiscount = 0.0;
  double _billWiseDiscountPercent = 0.0;
  double _totalDiscount = 0.0;
  double _totalGST = 0.0;
  double _totalAmount = 0.0;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _billWiseDiscount = widget.masterItem.billWiseDiscountAmount;
    _billWiseDiscountPercent = widget.masterItem.billWiseDiscountPercentage;
    _totalDiscount = widget.masterItem.discountAmount;
    if (_billWiseDiscount > 0 && _totalDiscount >= _billWiseDiscount) {
      _totalProductDiscount = _totalDiscount - _billWiseDiscount;
    }
    _totalGST = widget.masterItem.gstAmount;
    _totalAmount = widget.masterItem.netAmount;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final compId = sessionService.selectedCompId ?? widget.masterItem.compId;
      final branchId =
          sessionService.selectedBranchId ?? widget.masterItem.branchId;

      final items = await purchaseEntryService.getPurchaseDetailViewList(
        widget.masterItem.purchaseMasterId,
        compId: compId,
        branchId: branchId,
      );

      if (mounted) {
        setState(() {
          _details = items;
          _calculateTotals();
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

  void _calculateTotals() {
    double qty = 0.0;
    double gross = 0.0;
    double prodDiscount = 0.0;
    double gst = 0.0;
    double amount = 0.0;

    for (final item in _details) {
      qty += item.qty;
      gross += (item.qty * item.purchasePrice);
      prodDiscount += item.discountAmount;
      gst += item.gstAmount;
      amount += item.totalAmount;
    }

    _totalQty = qty;
    _totalGross = gross > 0 ? gross : widget.masterItem.subTotal;
    _totalProductDiscount = prodDiscount;

    _billWiseDiscount = widget.masterItem.billWiseDiscountAmount;
    _billWiseDiscountPercent = widget.masterItem.billWiseDiscountPercentage;

    // If master billWiseDiscountAmount is 0 but masterItem.discountAmount exceeds prodDiscount,
    // infer the difference as bill-wise discount.
    if (_billWiseDiscount == 0.0 &&
        widget.masterItem.discountAmount > prodDiscount) {
      _billWiseDiscount = widget.masterItem.discountAmount - prodDiscount;
    }

    // Total discount = product-wise discount + bill-wise discount.
    final calculatedDiscount = _totalProductDiscount + _billWiseDiscount;
    _totalDiscount = calculatedDiscount > 0
        ? calculatedDiscount
        : widget.masterItem.discountAmount;

    _totalGST = gst > 0 ? gst : widget.masterItem.gstAmount;
    _totalAmount = amount > 0 ? amount : widget.masterItem.netAmount;
  }

  Future<void> _exportToExcel() async {
    if (_details.isEmpty) {
      await showWarningDialog(
        context,
        'No purchase detail records to export.',
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final result =
          await ReportExcelExportService.exportPurchaseDetailReport(
        master: widget.masterItem,
        items: _details,
      );

      if (!mounted) return;

      if (result.success) {
        await showSuccessDialog(
          context,
          result.filePath != null && result.filePath!.isNotEmpty
              ? 'Purchase Invoice Details exported successfully to:\n${result.filePath}'
              : result.message,
        );
      } else {
        await showErrorDialog(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to export purchase details.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        'Failed to export purchase details: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _formatDateString(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return _dateFormat.format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'active':
      case 'approved':
      case 'paid':
        return Colors.green.shade700;
      case 'pending':
      case 'partial':
        return Colors.orange.shade700;
      case 'cancelled':
      case 'rejected':
      case 'unpaid':
        return Colors.red.shade700;
      default:
        return Colors.indigo.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectBackScope(
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
                      appBar: _buildAppBar(isDesktop: true),
                      body: _buildBody(isDesktop: true),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: _buildAppBar(isDesktop: false),
            drawer: const AppDrawer(isPermanent: false),
            body: _buildBody(isDesktop: false),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar({required bool isDesktop}) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Purchase Invoice: ${widget.masterItem.invoiceNo}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _fetchDetails,
        ),
        if (isDesktop)
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
          )
        else
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
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody({required bool isDesktop}) {
    return Column(
      children: [
        _buildMasterSummaryHeader(isDesktop: isDesktop),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorView()
                  : _details.isEmpty
                      ? _buildEmptyView()
                      : isDesktop
                          ? _buildDesktopDataTable()
                          : _buildMobileList(),
        ),
      ],
    );
  }

  Widget _buildMasterSummaryHeader({required bool isDesktop}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.25)
            : theme.colorScheme.primaryContainer.withOpacity(0.18),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildMetaItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Invoice No',
                      value: widget.masterItem.invoiceNo,
                      isBold: true,
                    ),
                    _buildMetaItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: _formatDateString(widget.masterItem.invoiceDate),
                    ),
                    _buildMetaItem(
                      icon: Icons.business_rounded,
                      label: 'Supplier',
                      value: widget.masterItem.suppName.isNotEmpty
                          ? widget.masterItem.suppName
                          : 'Supplier #${widget.masterItem.supplierId}',
                      isBold: true,
                    ),
                    if (widget.masterItem.suppMobile.isNotEmpty)
                      _buildMetaItem(
                        icon: Icons.phone_android_rounded,
                        label: 'Mobile',
                        value: widget.masterItem.suppMobile,
                      ),
                  ],
                ),
              ),
              // if (widget.masterItem.status.isNotEmpty)
              //   Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: _getStatusColor(widget.masterItem.status)
              //           .withOpacity(0.15),
              //       borderRadius: BorderRadius.circular(12),
              //       border: Border.all(
              //         color: _getStatusColor(widget.masterItem.status),
              //         width: 1,
              //       ),
              //     ),
              //     child: Text(
              //       widget.masterItem.status,
              //       style: TextStyle(
              //         fontSize: 12,
              //         fontWeight: FontWeight.bold,
              //         color: _getStatusColor(widget.masterItem.status),
              //       ),
              //     ),
              //   ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAmountPill(
                  'Sub Total',
                  widget.masterItem.subTotal > 0
                      ? widget.masterItem.subTotal
                      : _totalGross,
                  Colors.grey.shade700,
                ),
                const SizedBox(width: 10),
                _buildAmountPill(
                  'Product Disc',
                  _totalProductDiscount,
                  Colors.amber.shade800,
                ),
                const SizedBox(width: 10),
                _buildAmountPill(
                  _billWiseDiscountPercent > 0
                      ? 'Bill Disc (${_billWiseDiscountPercent.toStringAsFixed(1)}%)'
                      : 'Bill Disc',
                  _billWiseDiscount,
                  Colors.deepOrange.shade700,
                ),
                const SizedBox(width: 10),
                _buildAmountPill(
                  'Total Disc',
                  _totalDiscount,
                  Colors.orange.shade800,
                ),
                const SizedBox(width: 10),
                _buildAmountPill(
                  'GST Amount',
                  widget.masterItem.gstAmount > 0
                      ? widget.masterItem.gstAmount
                      : _totalGST,
                  Colors.blue.shade700,
                ),
                const SizedBox(width: 10),
                _buildAmountPill(
                  'Net Amount',
                  widget.masterItem.netAmount,
                  Colors.indigo.shade700,
                  isPrimary: true,
                ),
                const SizedBox(width: 10),
                _buildAmountPill(
                  'Paid Amount',
                  widget.masterItem.paidAmount,
                  Colors.green.shade700,
                ),
                if (widget.masterItem.balanceAmount > 0) ...[
                  const SizedBox(width: 10),
                  _buildAmountPill(
                    'Balance Due',
                    widget.masterItem.balanceAmount,
                    Colors.red.shade700,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountPill(
    String label,
    double amount,
    Color color, {
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
            ? (isDark
                ? theme.colorScheme.primary.withOpacity(0.25)
                : theme.colorScheme.primaryContainer)
            : (isDark
                ? theme.colorScheme.surfaceVariant.withOpacity(0.4)
                : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withOpacity(0.6),
          width: isPrimary ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isPrimary
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '₹ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isPrimary
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white : color),
            ),
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header Row
            Container(
              height: 44,
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
                    width: 40,
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
                    flex: 2,
                    child: Text(
                      'Barcode / Batch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Qty',
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
                    flex: 1,
                    child: Text(
                      'Disc %',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Disc Amt',
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
                      'Total Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Line items list
            Expanded(
              child: ListView.builder(
                itemCount: _details.length,
                itemBuilder: (context, index) {
                  final item = _details[index];

                  return Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: index % 2 == 1
                          ? theme.colorScheme.surfaceVariant.withOpacity(0.08)
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
                          width: 40,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.prodName.isNotEmpty
                                ? item.prodName
                                : 'Product #${item.productId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (item.barcode.isNotEmpty)
                                Text(
                                  item.barcode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (item.batchNo.isNotEmpty)
                                Text(
                                  'Batch: ${item.batchNo}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.hintColor,
                                  ),
                                ),
                              if (item.barcode.isEmpty && item.batchNo.isEmpty)
                                const Text('-', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.qty.toStringAsFixed(1),
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
                            '₹ ${item.purchasePrice.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹ ${item.mrp.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${item.discountPercent.toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹ ${item.discountAmount.toStringAsFixed(2)}',
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
                            '₹ ${item.totalAmount.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
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
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Total (${_details.length} items):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _totalQty.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                  const Expanded(flex: 2, child: SizedBox()),
                  const Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_totalProductDiscount.toStringAsFixed(2)}',
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
                      '₹ ${_totalGST.toStringAsFixed(2)}',
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
                      '₹ ${_totalAmount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Discount Breakdown Summary Footer
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            //   decoration: BoxDecoration(
            //     color: theme.colorScheme.surfaceVariant.withOpacity(0.22),
            //     border: Border(
            //       top: BorderSide(
            //         color: theme.colorScheme.outlineVariant.withOpacity(0.6),
            //       ),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       const Icon(
            //         Icons.discount_outlined,
            //         size: 18,
            //         color: Colors.orange,
            //       ),
            //       const SizedBox(width: 8),
            //       Text(
            //         'Discount Breakdown:',
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           fontSize: 12.5,
            //           color: theme.colorScheme.onSurface,
            //         ),
            //       ),
            //       const Spacer(),
            //       Wrap(
            //         spacing: 20,
            //         runSpacing: 6,
            //         crossAxisAlignment: WrapCrossAlignment.center,
            //         children: [
            //           Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               Text(
            //                 'Product Total Disc: ',
            //                 style: TextStyle(
            //                   fontSize: 12.5,
            //                   color: theme.colorScheme.onSurfaceVariant,
            //                 ),
            //               ),
            //               Text(
            //                 '₹ ${_totalProductDiscount.toStringAsFixed(2)}',
            //                 style: TextStyle(
            //                   fontSize: 13,
            //                   fontWeight: FontWeight.bold,
            //                   color: Colors.amber.shade900,
            //                 ),
            //               ),
            //             ],
            //           ),
            //           Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               Text(
            //                 _billWiseDiscountPercent > 0
            //                     ? 'Bill Disc (${_billWiseDiscountPercent.toStringAsFixed(1)}%): '
            //                     : 'Bill Disc: ',
            //                 style: TextStyle(
            //                   fontSize: 12.5,
            //                   color: theme.colorScheme.onSurfaceVariant,
            //                 ),
            //               ),
            //               Text(
            //                 '₹ ${_billWiseDiscount.toStringAsFixed(2)}',
            //                 style: TextStyle(
            //                   fontSize: 13,
            //                   fontWeight: FontWeight.bold,
            //                   color: Colors.deepOrange.shade800,
            //                 ),
            //               ),
            //             ],
            //           ),
            //           Container(
            //             padding: const EdgeInsets.symmetric(
            //               horizontal: 10,
            //               vertical: 4,
            //             ),
            //             decoration: BoxDecoration(
            //               color: Colors.orange.withOpacity(0.12),
            //               borderRadius: BorderRadius.circular(6),
            //               border: Border.all(
            //                 color: Colors.orange.shade400,
            //               ),
            //             ),
            //             child: Row(
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 Text(
            //                   'Total Discount: ',
            //                   style: TextStyle(
            //                     fontSize: 12.5,
            //                     fontWeight: FontWeight.bold,
            //                     color: Colors.orange.shade900,
            //                   ),
            //                 ),
            //                 Text(
            //                   '₹ ${_totalDiscount.toStringAsFixed(2)}',
            //                   style: TextStyle(
            //                     fontSize: 13,
            //                     fontWeight: FontWeight.bold,
            //                     color: Colors.orange.shade900,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _details.length + 1,
      itemBuilder: (context, index) {
        if (index == _details.length) {
          // Summary Footer Card
          return Card(
            margin: const EdgeInsets.only(top: 8, bottom: 20),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.summarize_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Invoice Summary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildMobileSummaryRow('Total Items', '${_details.length}'),
                  _buildMobileSummaryRow(
                    'Total Quantity',
                    _totalQty.toStringAsFixed(1),
                  ),
                  _buildMobileSummaryRow(
                    'Sub Total',
                    '₹ ${_totalGross.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 16),
                  _buildMobileSummaryRow(
                    'Product-wise Discount',
                    '₹ ${_totalProductDiscount.toStringAsFixed(2)}',
                    color: Colors.amber.shade900,
                  ),
                  _buildMobileSummaryRow(
                    _billWiseDiscountPercent > 0
                        ? 'Bill-wise Discount (${_billWiseDiscountPercent.toStringAsFixed(1)}%)'
                        : 'Bill-wise Discount',
                    '₹ ${_billWiseDiscount.toStringAsFixed(2)}',
                    color: Colors.deepOrange.shade800,
                  ),
                  _buildMobileSummaryRow(
                    'Total Discount',
                    '₹ ${_totalDiscount.toStringAsFixed(2)}',
                    color: Colors.orange.shade900,
                    isBold: true,
                  ),
                  const Divider(height: 16),
                  _buildMobileSummaryRow(
                    'GST Amount',
                    '₹ ${_totalGST.toStringAsFixed(2)}',
                  ),
                  _buildMobileSummaryRow(
                    'Net Amount',
                    '₹ ${_totalAmount.toStringAsFixed(2)}',
                    color: theme.colorScheme.primary,
                    isBold: true,
                    fontSize: 15,
                  ),
                ],
              ),
            ),
          );
        }

        final item = _details[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
            ),
          ),
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
                            item.prodName.isNotEmpty
                                ? item.prodName
                                : 'Product #${item.productId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          if (item.barcode.isNotEmpty ||
                              item.batchNo.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (item.barcode.isNotEmpty)
                                  'Barcode: ${item.barcode}',
                                if (item.batchNo.isNotEmpty)
                                  'Batch: ${item.batchNo}',
                              ].join(' • '),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '₹ ${item.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qty: ${item.qty.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      'Rate: ₹${item.purchasePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.discountPercent > 0
                          ? 'Disc: ₹${item.discountAmount.toStringAsFixed(2)} (${item.discountPercent.toStringAsFixed(0)}%)'
                          : 'Disc: ₹${item.discountAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'GST: ₹${item.gstAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildMobileSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load purchase item details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No item details found for this invoice.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
