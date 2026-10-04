import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/sales_entry_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';

class CustomerOutstandingDetailReportScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerOutstandingDetailReportScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerOutstandingDetailReportScreen> createState() =>
      _CustomerOutstandingDetailReportScreenState();
}

class _CustomerOutstandingDetailReportScreenState
    extends State<CustomerOutstandingDetailReportScreen> {
  final SalesEntryService _salesEntryService = SalesEntryService();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 20;

  String? _errorMessage;
  List<Map<String, dynamic>> _reportData = [];
  int _highlightedIndex = 0;

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
      final data = await _salesEntryService.getAllPendingAmount(
        customerId: widget.customerId,
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (data.isEmpty) {
            _hasMoreData = false;
          } else {
            _pageNumber = nextPage;
            _reportData.addAll(data);
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

      // Auto fetch if near bottom
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
      // Future feature: Open specific invoice details
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double rowHeight = 60.0;
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
      if (refresh) {
        _isLoading = true;
        _pageNumber = 1;
        _hasMoreData = true;
        _reportData.clear();
        _highlightedIndex = 0;
      }
      _errorMessage = null;
    });

    try {
      final data = await _salesEntryService.getAllPendingAmount(
        customerId: widget.customerId,
        pageNumber: 1,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
          _hasMoreData = data.length == _pageSize;
          if (_reportData.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(
              0,
              _reportData.length - 1,
            );
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

  String _getString(
    Map<String, dynamic> item,
    List<String> keys, [
    String defaultValue = '',
  ]) {
    for (var key in keys) {
      // Try exact match first
      if (item.containsKey(key) && item[key] != null) {
        return item[key].toString();
      }
      // Try case insensitive match
      final lowerKey = key.toLowerCase();
      for (var actualKey in item.keys) {
        if (actualKey.toLowerCase() == lowerKey && item[actualKey] != null) {
          return item[actualKey].toString();
        }
      }
    }
    return defaultValue;
  }

  double _getDouble(
    Map<String, dynamic> item,
    List<String> keys, [
    double defaultValue = 0.0,
  ]) {
    for (var key in keys) {
      if (item.containsKey(key) && item[key] != null) {
        return double.tryParse(item[key].toString()) ?? defaultValue;
      }
      final lowerKey = key.toLowerCase();
      for (var actualKey in item.keys) {
        if (actualKey.toLowerCase() == lowerKey && item[actualKey] != null) {
          return double.tryParse(item[actualKey].toString()) ?? defaultValue;
        }
      }
    }
    return defaultValue;
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
                          title: Text(
                            'Outstanding Details - ${widget.customerName}',
                          ),
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
                        body: _buildBodyContent(isDesktop: true),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Details - ${widget.customerName}',
                  style: const TextStyle(fontSize: 16),
                ),
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
      return const Center(
        child: Text('No outstanding records found for this customer.'),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
          child: Row(
            children: [
              const Spacer(),
              if (isDesktop)
                Text(
                  'Use ↑ / ↓ to navigate • Esc to go back',
                  style: Theme.of(context).textTheme.bodySmall,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '#',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Invoice No',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total Amount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Paid Amount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Pending Amount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

                  final invoiceNo = _getString(item, [
                    'invoiceNo',
                    'salesMaster_InvoiceNo',
                    'SalesMaster_InvoiceNo',
                  ], 'N/A');
                  final dateStr = _getString(item, [
                    'invoiceDate',
                    'salesMaster_InvoiceDate',
                    'date',
                    'Date',
                  ]);
                  final totalAmt = _getDouble(item, [
                    'netAmount',
                    'grandTotal',
                    'totalAmount',
                    'salesMaster_GrandTotal',
                  ]);
                  final paidAmt = _getDouble(item, [
                    'paidAmount',
                    'salesMaster_PaidAmount',
                    'receivedAmount',
                  ]);
                  final pendingAmt = _getDouble(item, [
                    'balanceAmount',
                    'pendingAmount',
                    'salesMaster_BalanceAmount',
                  ]);

                  final dateFormat = DateFormat('dd/MM/yyyy');
                  DateTime parsedDate;
                  try {
                    parsedDate = DateTime.parse(dateStr);
                  } catch (_) {
                    parsedDate = DateTime.now();
                  }

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _highlightedIndex = index;
                      });
                    },
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(
                                0.5,
                              )
                            : (index.isEven
                                  ? theme.colorScheme.surfaceVariant
                                        .withOpacity(0.3)
                                  : Colors.transparent),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withOpacity(0.5),
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
                            width: 50,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              invoiceNo,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              dateStr.isNotEmpty
                                  ? dateFormat.format(parsedDate)
                                  : '',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.hintColor,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(totalAmt.toStringAsFixed(2)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(paidAmt.toStringAsFixed(2)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                pendingAmt.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
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
    return ListView.builder(
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

        final invoiceNo = _getString(item, [
          'invoiceNo',
          'salesMaster_InvoiceNo',
          'SalesMaster_InvoiceNo',
        ], 'N/A');
        final dateStr = _getString(item, [
          'invoiceDate',
          'salesMaster_InvoiceDate',
          'date',
          'Date',
        ]);
        final totalAmt = _getDouble(item, [
          'netAmount',
          'grandTotal',
          'totalAmount',
          'salesMaster_GrandTotal',
        ]);
        final paidAmt = _getDouble(item, [
          'paidAmount',
          'salesMaster_PaidAmount',
          'receivedAmount',
        ]);
        final pendingAmt = _getDouble(item, [
          'balanceAmount',
          'pendingAmount',
          'salesMaster_BalanceAmount',
        ]);

        final dateFormat = DateFormat('dd/MM/yyyy');
        DateTime parsedDate;
        try {
          parsedDate = DateTime.parse(dateStr);
        } catch (_) {
          parsedDate = DateTime.now();
        }

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          child: ListTile(
            title: Text(
              'Invoice: $invoiceNo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${dateStr.isNotEmpty ? dateFormat.format(parsedDate) : ''}',
                ),
                Text(
                  'Total: ${totalAmt.toStringAsFixed(2)} | Paid: ${paidAmt.toStringAsFixed(2)}',
                ),
                Text(
                  'Pending: ${pendingAmt.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _highlightedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
