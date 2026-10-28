import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_return.dart';
import '../../services/purchase_return_service.dart';
import '../../services/session_service.dart';
import '../../services/report_excel_export_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class PurchaseReturnDetailReportScreen extends StatefulWidget {
  final PurchaseReturnMasterViewItem masterItem;

  const PurchaseReturnDetailReportScreen({
    super.key,
    required this.masterItem,
  });

  @override
  State<PurchaseReturnDetailReportScreen> createState() =>
      _PurchaseReturnDetailReportScreenState();
}

class _PurchaseReturnDetailReportScreenState
    extends State<PurchaseReturnDetailReportScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  List<PurchaseReturnDetailViewItem> _details = [];

  double _totalQty = 0.0;
  double _totalGross = 0.0;
  double _totalDiscount = 0.0;
  double _totalGST = 0.0;
  double _totalAmount = 0.0;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
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

      final items = await purchaseReturnService.getPurchaseReturnDetailViewList(
        widget.masterItem.purchaseReturnMasterId,
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
    double discount = 0.0;
    double gst = 0.0;
    double amount = 0.0;

    for (final item in _details) {
      qty += item.qty;
      gross += (item.qty * item.purchasePrice);
      discount += item.discountAmount;
      gst += item.gstAmount;
      amount += item.totalAmount;
    }

    _totalQty = qty;
    _totalGross = gross;
    _totalDiscount = discount;
    _totalGST = gst;
    _totalAmount = amount > 0 ? amount : widget.masterItem.netAmount;
  }

  Future<void> _exportToExcel() async {
    if (_details.isEmpty) {
      await showWarningDialog(
        context,
        'No purchase return detail records to export.',
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final result =
          await ReportExcelExportService.exportPurchaseReturnDetailReport(
        master: widget.masterItem,
        items: _details,
      );

      if (!mounted) return;

      if (result.success) {
        await showSuccessDialog(
          context,
          result.filePath != null && result.filePath!.isNotEmpty
              ? 'Purchase Return Details exported successfully to:\n${result.filePath}'
              : result.message,
        );
      } else {
        await showErrorDialog(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to export purchase return details.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        'Failed to export purchase return details: $e',
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
          const Icon(Icons.assignment_return_rounded, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Purchase Return: ${widget.masterItem.returnNo}',
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
                      label: 'Return No',
                      value: widget.masterItem.returnNo,
                      isBold: true,
                    ),
                    _buildMetaItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: _formatDateString(widget.masterItem.returnDate),
                    ),
                    _buildMetaItem(
                      icon: Icons.business_rounded,
                      label: 'Supplier',
                      value: widget.masterItem.ledgerName.isNotEmpty
                          ? widget.masterItem.ledgerName
                          : 'Supplier #${widget.masterItem.supplierId}',
                      isBold: true,
                    ),
                    if (widget.masterItem.supplierMobile.isNotEmpty)
                      _buildMetaItem(
                        icon: Icons.phone_android_rounded,
                        label: 'Mobile',
                        value: widget.masterItem.supplierMobile,
                      ),
                    // if (widget.masterItem.supplierCode.isNotEmpty)
                    //   _buildMetaItem(
                    //     icon: Icons.badge_outlined,
                    //     label: 'Code',
                    //     value: widget.masterItem.supplierCode,
                    //   ),
                  ],
                ),
              ),
              if (widget.masterItem.status.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.masterItem.status)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(widget.masterItem.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.masterItem.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(widget.masterItem.status),
                    ),
                  ),
                ),
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
                  'Discount',
                  widget.masterItem.discountAmount > 0
                      ? widget.masterItem.discountAmount
                      : _totalDiscount,
                  Colors.orange.shade700,
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
                  'Refund Amount',
                  widget.masterItem.refundAmount,
                  Colors.teal.shade700,
                ),
                if (widget.masterItem.balanceAmount > 0) ...[
                  const SizedBox(width: 10),
                  _buildAmountPill(
                    'Balance',
                    widget.masterItem.balanceAmount,
                    Colors.red.shade700,
                  ),
                ],
              ],
            ),
          ),
          if (widget.masterItem.remark.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Remark: ${widget.masterItem.remark}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.hintColor,
              ),
            ),
          ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).hintColor),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary
            ? color.withOpacity(isDark ? 0.35 : 0.12)
            : (isDark ? Colors.black26 : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrimary ? color : color.withOpacity(0.35),
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
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '₹ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPrimary ? color : null,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load purchase return details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _fetchDetails,
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
            Icons.inbox_outlined,
            size: 56,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 14),
          Text(
            'No itemized records found for this return invoice.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total Return Invoice Amount: ₹ ${widget.masterItem.netAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Card(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Table Header
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
                    child: Text('#',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text('Product Description',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Batch No.',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Quantity',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Purchase Rate',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Discount',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('GST Amt',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Total Amount',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Scrollable Rows
            Expanded(
              child: ListView.builder(
                itemCount: _details.length,
                itemBuilder: (context, index) {
                  final item = _details[index];

                  return Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: index % 2 == 1
                          ? theme.colorScheme.surfaceVariant.withOpacity(0.08)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withOpacity(0.3),
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
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.productName.isNotEmpty
                                    ? item.productName
                                    : 'Product #${item.productId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.productCode.isNotEmpty)
                                Text(
                                  'Code: ${item.productCode}',
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
                            item.batchNumber.isNotEmpty
                                ? item.batchNumber
                                : '-',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.qty.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
                            item.discountAmount > 0
                                ? '₹ ${item.discountAmount.toStringAsFixed(2)} (${item.discountPercent.toStringAsFixed(0)}%)'
                                : '-',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.gstAmount > 0
                                ? '₹ ${item.gstAmount.toStringAsFixed(2)} (${item.gstPercent.toStringAsFixed(0)}%)'
                                : '-',
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
                  const SizedBox(width: 45),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Total (${_details.length} Items):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _totalQty.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_totalDiscount.toStringAsFixed(2)}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _details.length,
      itemBuilder: (context, index) {
        final item = _details[index];

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.12),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
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
                                : 'Product #${item.productId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (item.productCode.isNotEmpty)
                            Text(
                              'Code: ${item.productCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
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
                    _buildMobileLabelValue('Qty', item.qty.toStringAsFixed(2)),
                    _buildMobileLabelValue(
                        'Price', '₹ ${item.purchasePrice.toStringAsFixed(2)}'),
                    _buildMobileLabelValue(
                      'Batch',
                      item.batchNumber.isNotEmpty ? item.batchNumber : '-',
                    ),
                    _buildMobileLabelValue(
                      'GST',
                      item.gstAmount > 0
                          ? '₹ ${item.gstAmount.toStringAsFixed(2)}'
                          : '-',
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

  Widget _buildMobileLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
