import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/supplier_reports.dart';
import '../../services/supplier_service.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/app_drawer.dart';

class SupplierPendingInvoiceReportScreen extends StatefulWidget {
  final int supplierId;
  final String supplierName;

  const SupplierPendingInvoiceReportScreen({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  @override
  State<SupplierPendingInvoiceReportScreen> createState() => _SupplierPendingInvoiceReportScreenState();
}

class _SupplierPendingInvoiceReportScreenState extends State<SupplierPendingInvoiceReportScreen> {
  final SupplierService _supplierService = supplierService;
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 20;

  String _searchQuery = '';
  String? _errorMessage;
  List<SupplierPendingInvoiceItem> _invoiceData = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);
    _fetchInvoices(refresh: true);

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
    if (_debounce != null) _debounce!.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      final data = await _supplierService.getSupplierPendingInvoice(
        supplierId: widget.supplierId,
        pageNumber: nextPage,
        pageSize: _pageSize,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          if (data.isEmpty) {
            _hasMoreData = false;
          } else {
            _pageNumber = nextPage;
            _invoiceData.addAll(data);
            if (data.length < _pageSize) {
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
    if (event is! KeyDownEvent || _invoiceData.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _invoiceData.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      
      // Auto fetch if near bottom
      if (_highlightedIndex >= _invoiceData.length - 5) {
        _fetchMoreData();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _invoiceData.length - 1;
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchInvoices(refresh: true);
      }
    });
  }

  Future<void> _fetchInvoices({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _pageNumber = 1;
        _hasMoreData = true;
        _invoiceData.clear();
        _highlightedIndex = 0;
      }
    });

    try {
      final data = await _supplierService.getSupplierPendingInvoice(
        supplierId: widget.supplierId,
        pageNumber: 1,
        pageSize: _pageSize,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _invoiceData = data;
          _isLoading = false;
          _hasMoreData = data.length == _pageSize;
          if (_invoiceData.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(0, _invoiceData.length - 1);
          } else {
            _highlightedIndex = 0;
          }
        });
        if (!refresh) {
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
                          title: Text('Pending Invoices: ${widget.supplierName}'),
                          actions: [
                            Container(
                              width: 250,
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search invoice...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                              onPressed: _isLoading ? null : () => _fetchInvoices(refresh: true),
                            ),
                            const SizedBox(width: 16),
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
                title: Text('Pending Invoices: ${widget.supplierName}'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : () => _fetchInvoices(refresh: true),
                  ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _invoiceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load invoices', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => _fetchInvoices(refresh: true), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (!isDesktop) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search invoice...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
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
              onChanged: _onSearchChanged,
            ),
          ),
          if (_invoiceData.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No pending invoices found for this supplier.'),
              ),
            )
          else
            Expanded(child: _buildMobileList()),
        ],
      );
    }

    if (_invoiceData.isEmpty) {
      return const Center(child: Text('No pending invoices found for this supplier.'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
          child: Row(
            children: [
              Text(
                'Showing ${_invoiceData.length} invoices',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Use ↑ / ↓ to navigate • Esc to go back',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildDesktopDataTable(),
        ),
      ],
    );
  }

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd-MM-yyyy');

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
                border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Invoice No', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Ledger', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Net Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Paid Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _invoiceData.length + (_isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _invoiceData.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = _invoiceData[index];
                  final isSelected = index == _highlightedIndex;
                  final dateStr = item.purchaseMasterInvoiceDate != null 
                      ? dateFormat.format(item.purchaseMasterInvoiceDate!) 
                      : '-';

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _highlightedIndex = index;
                      });
                    },
                    child: Container(
                      height: 53,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 50, child: Text('${index + 1}')),
                          Expanded(flex: 3, child: Text(item.purchaseMasterInvoiceNo)),
                          Expanded(flex: 3, child: Text(dateStr)),
                          Expanded(flex: 3, child: Text(item.accLedgerName)),
                          Expanded(flex: 2, child: Text(item.netAmount.toStringAsFixed(2))),
                          Expanded(flex: 2, child: Text(item.paidAmount.toStringAsFixed(2))),
                          Expanded(
                            flex: 2, 
                            child: Text(
                              item.balanceAmount.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.balanceAmount > 0 ? Colors.red.shade700 : Colors.green.shade700,
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
    final dateFormat = DateFormat('dd-MM-yyyy');

    double totalNet = 0;
    double totalPaid = 0;
    double totalBalance = 0;
    for (var item in _invoiceData) {
      totalNet += item.netAmount;
      totalPaid += item.paidAmount;
      totalBalance += item.balanceAmount;
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _invoiceData.length + (_isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _invoiceData.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = _invoiceData[index];
              final isSelected = index == _highlightedIndex;
              final dateStr = item.purchaseMasterInvoiceDate != null
                  ? dateFormat.format(item.purchaseMasterInvoiceDate!)
                  : '-';

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
                                    item.purchaseMasterInvoiceNo.isNotEmpty
                                        ? item.purchaseMasterInvoiceNo
                                        : 'Invoice #${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.accLedgerName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.accLedgerName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
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
                                  'Net Amt',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${item.netAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paid Amt',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${item.paidAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
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
                                  'Balance Due',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${item.balanceAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: item.balanceAmount > 0
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
                      'Invoices: ${_invoiceData.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Net: ₹${totalNet.toStringAsFixed(2)}',
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
                      'Total Balance Due',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹${totalBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: totalBalance > 0
                            ? Colors.red.shade700
                            : colorScheme.primary,
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

class _InvoiceSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  _InvoiceSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch(query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSearch(query);
      close(context, query);
    });
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
