import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/invoice_pdf_controller.dart';
import '../../../models/customer.dart';
import '../../../models/invoice_pdf_data.dart';
import '../../../models/sales_entry.dart';
import '../../../services/company_service.dart';
import '../../../services/customer_service.dart';
import '../../../services/invoice_pdf_data_factory.dart';
import '../../../services/sales_entry_service.dart';
import '../../../services/session_service.dart';
import '../../../services/shortcut_service.dart';
import '../../../widgets/app_confirm_dialog.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_message_dialog.dart';
import '../../../widgets/custom_date_picker_field.dart';
import '../../../widgets/direct_back_scope.dart';
import '../../pdf/pdf_preview_screen.dart';

class SalesEntryViewList extends StatefulWidget {
  const SalesEntryViewList({super.key});

  @override
  State<SalesEntryViewList> createState() => _SalesEntryViewListState();
}

class _SalesEntryViewListState extends State<SalesEntryViewList> {
  final SalesEntryService _salesEntryService = SalesEntryService();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<SalesMasterData> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _highlightedIndex = 0;

  int? _loadingSalesMasterId;
  String? _loadingAction; // 'preview' or 'download'
  final Map<int, List<SalesDetailData>> _detailsCache = {};

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);
    _fetchEntries(refresh: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _screenFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore && _hasMore) {
        _fetchEntries();
      }
    }
  }

  Future<void> _fetchEntries({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMore = true;
        _entries.clear();
        _detailsCache.clear();
      });
    } else {
      setState(() {
        _isFetchingMore = true;
      });
    }

    try {
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      String? fromDateStr;
      String? toDateStr;
      if (_fromDate != null) {
        fromDateStr = _fromDate!.toIso8601String().split('T').first;
      }
      if (_toDate != null) {
        toDateStr = _toDate!.toIso8601String().split('T').first;
      }

      final response = await _salesEntryService.getAllSalesMaster(
        compId: compId,
        branchId: branchId,
        fromDate: fromDateStr,
        toDate: toDateStr,
        search: _searchController.text.trim(),
        pageNumber: _currentPage,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          final newItems = response.data?.items ?? [];
          if (refresh) {
            _entries = newItems;
            _highlightedIndex = 0;
          } else {
            _entries.addAll(newItems);
          }

          if (newItems.length < 20) {
            _hasMore = false;
          } else {
            _currentPage++;
          }

          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _entries.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _entries.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _entries.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _entries.length) {
        _selectEntry(_entries[_highlightedIndex]);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double rowHeight = 56.0;
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

  void _selectEntry(SalesMasterData entry) {
    Navigator.pop(context, entry);
  }

  int _getSalesMasterId(SalesMasterData entry) {
    final id = entry.raw['salesMaster_Id'] ?? entry.raw['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '') ?? 0;
  }

  Future<InvoicePdfData?> _prepareInvoicePdfData(SalesMasterData entry) async {
    final salesMasterId = _getSalesMasterId(entry);
    if (salesMasterId <= 0) {
      await showErrorDialog(context, 'Invalid sales invoice ID.');
      return null;
    }

    List<SalesDetailData> details;
    if (_detailsCache.containsKey(salesMasterId)) {
      details = _detailsCache[salesMasterId]!;
    } else {
      final response = await _salesEntryService.getAllSalesDetail(salesMasterId);
      details = response.data;
      _detailsCache[salesMasterId] = details;
    }

    if (details.isEmpty) {
      if (mounted) {
        await showErrorDialog(
          context,
          'No invoice details found for sales invoice #$salesMasterId.',
        );
      }
      return null;
    }

    final user = await sessionService.getUserData();

    final rawCompId = entry.raw['salesMaster_CompId'] ??
        entry.raw['compId'] ??
        sessionService.selectedCompId;
    final compId = rawCompId is int
        ? rawCompId
        : int.tryParse(rawCompId?.toString() ?? '') ?? 0;
    var company = companyService.getCompanyById(compId);
    if (company == null && compId > 0) {
      try {
        final companies = await companyService.getAllCompanies(isActive: null);
        for (final c in companies) {
          if (c.compId == compId) {
            company = c;
            break;
          }
        }
      } catch (_) {}
    }

    final rawCustId = entry.raw['salesMaster_CustomerId'] ??
        entry.raw['customerId'] ??
        entry.raw['cust_Id'];
    final custId = rawCustId is int
        ? rawCustId
        : int.tryParse(rawCustId?.toString() ?? '') ?? 0;
    CustomerListItem? customer;
    if (custId > 0) {
      try {
        customer = customerService.customers.firstWhere((c) => c.custId == custId);
      } catch (_) {
        try {
          customer = await customerService.getCustomerById(custId);
        } catch (_) {}
      }
    }

    return InvoicePdfDataFactory.fromMasterAndDetails(
      master: entry,
      details: details,
      customer: customer,
      company: company,
      user: user,
      companyNameFallback: sessionService.selectedCompName,
    );
  }

  Future<void> _handlePdfPreview(SalesMasterData entry) async {
    if (_loadingSalesMasterId != null) return;
    final salesMasterId = _getSalesMasterId(entry);
    if (salesMasterId <= 0) {
      await showErrorDialog(context, 'Invalid sales invoice ID.');
      return;
    }

    setState(() {
      _loadingSalesMasterId = salesMasterId;
      _loadingAction = 'preview';
    });

    try {
      final pdfData = await _prepareInvoicePdfData(entry);
      if (pdfData == null || !mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.pdfPreview),
          builder: (context) => PdfPreviewScreen(invoiceData: pdfData),
        ),
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Failed to preview invoice PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSalesMasterId = null;
          _loadingAction = null;
        });
      }
    }
  }

  Future<void> _handlePdfDownload(SalesMasterData entry) async {
    if (_loadingSalesMasterId != null) return;
    final salesMasterId = _getSalesMasterId(entry);
    if (salesMasterId <= 0) {
      await showErrorDialog(context, 'Invalid sales invoice ID.');
      return;
    }

    setState(() {
      _loadingSalesMasterId = salesMasterId;
      _loadingAction = 'download';
    });

    try {
      final pdfData = await _prepareInvoicePdfData(entry);
      if (pdfData == null || !mounted) return;

      final controller = InvoicePdfController();
      final invoiceNo = entry.raw['salesMaster_InvoiceNo']?.toString().trim();
      final safeNo = (invoiceNo != null && invoiceNo.isNotEmpty)
          ? invoiceNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
          : 'INV-$salesMasterId';
      final customFileName =
          safeNo.toLowerCase().endsWith('.pdf') ? safeNo : '$safeNo.pdf';

      await controller.generateFromData(pdfData, customFileName: customFileName);
      final path = await controller.downloadPdf();

      if (mounted && path != null) {
        await showSuccessDialog(
          context,
          'Invoice PDF downloaded successfully:\n$path',
        );
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Failed to download invoice PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSalesMasterId = null;
          _loadingAction = null;
        });
      }
    }
  }

  Future<void> _deleteEntry(int salesMasterId) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete Sales Entry',
      message:
          'Are you sure you want to delete this sales entry? This action cannot be undone.',
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _salesEntryService.deleteSalesEntryApi(salesMasterId);
        _detailsCache.remove(salesMasterId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales entry deleted successfully.')),
          );
        }
        _fetchEntries(refresh: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
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
                          title: const Text('View Sales Entries'),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: _isLoading
                                  ? null
                                  : () => _fetchEntries(refresh: true),
                            ),
                          ],
                        ),
                        body: _buildBody(),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('View Sales Entries'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _isLoading
                        ? null
                        : () => _fetchEntries(refresh: true),
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: _buildBody(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
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
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _fetchEntries(refresh: true);
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
                  _fetchEntries(refresh: true);
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
                  _fetchEntries(refresh: true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildFilterRow(),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _fetchEntries(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_entries.isEmpty)
          const Expanded(child: Center(child: Text('No sales entries found.')))
        else
          Expanded(
            child: Column(
              children: [
                // Header Row
                Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 1,
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
                          'Mobile',
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
                          'Discount',
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
                          'Bal Amt',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Net Amt',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Action',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Data List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _entries.length + (_isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _entries.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final entry = _entries[index];
                      final isHighlighted = index == _highlightedIndex;
                      final raw = entry.raw;
                      final id = _getSalesMasterId(entry);
                      final isCurrentRowLoading = _loadingSalesMasterId == id;

                      return InkWell(
                        onTap: () => _selectEntry(entry),
                        child: Container(
                          height: 56.0,
                          color: isHighlighted
                              ? Theme.of(context).colorScheme.primaryContainer
                              : (index.isEven
                                    ? Theme.of(context).colorScheme.surface
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: Text('${index + 1}')),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  raw['salesMaster_InvoiceNo']?.toString() ??
                                      '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(raw['cust_Name']?.toString() ?? ''),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  raw['cust_MobileNo']?.toString() ?? '',
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  raw['salesMaster_InvoiceDate']
                                          ?.toString()
                                          .split('T')
                                          .first ??
                                      '',
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${raw['salesMaster_TotalQty'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesMaster_TotalDiscount'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesMaster_PaidAmount'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesMaster_BalanceAmount'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesMaster_GrandTotal'] ?? 0}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: isCurrentRowLoading &&
                                              _loadingAction == 'preview'
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.visibility_outlined,
                                              size: 18,
                                            ),
                                      tooltip: 'Preview PDF',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: _loadingSalesMasterId != null
                                          ? null
                                          : () => _handlePdfPreview(entry),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: isCurrentRowLoading &&
                                              _loadingAction == 'download'
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.download_outlined,
                                              size: 18,
                                            ),
                                      tooltip: 'Download PDF',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: _loadingSalesMasterId != null
                                          ? null
                                          : () => _handlePdfDownload(entry),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      tooltip: 'Delete',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: _loadingSalesMasterId != null
                                          ? null
                                          : () {
                                              if (id > 0) {
                                                _deleteEntry(id);
                                              }
                                            },
                                    ),
                                  ],
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
      ],
    );
  }
}
