import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/payment_entry_report.dart';
import '../../services/payment_entry_report_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/custom_date_picker_field.dart';

class PaymentEntryReportScreen extends StatefulWidget {
  const PaymentEntryReportScreen({super.key});

  @override
  State<PaymentEntryReportScreen> createState() => _PaymentEntryReportScreenState();
}

class _PaymentEntryReportScreenState extends State<PaymentEntryReportScreen> {
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
  List<PaymentEntryReportData> _reportData = [];
  int _highlightedIndex = 0;

  int _totalRecords = 0;

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
      final request = _buildRequest(page: nextPage);

      final response = await paymentEntryReportService.getPaymentEntryReport(
        request,
      );

      if (mounted) {
        setState(() {
          if (response.data?.items.isEmpty ?? true) {
            _hasMoreData = false;
          } else {
            _pageNumber = nextPage;
            _reportData.addAll(response.data!.items);
            if (response.data!.items.length < _pageSize) {
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

  PaymentEntryReportRequest _buildRequest({required int page}) {
    final compId = sessionService.selectedCompId ?? 0;
    final branchId = sessionService.selectedBranchId ?? 0;

    return PaymentEntryReportRequest(
      compId: compId,
      branchId: branchId,
      fromDate: _fromDate != null ? _dateFormat.format(_fromDate!) : "",
      toDate: _toDate != null ? _dateFormat.format(_toDate!) : "",
      search: _searchQuery,
      page: page,
      pageSize: _pageSize,
    );
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
        _highlightedIndex = 0;
      }
    });

    try {
      final request = _buildRequest(page: 1);
      final response = await paymentEntryReportService.getPaymentEntryReport(
        request,
      );

      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.data?.items ?? [];
            _totalRecords = response.data?.totalRecords ?? 0;
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
                          title: const Text('Payment Entry Report'),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                              onPressed: _isLoading
                                  ? null
                                  : () => _fetchReport(refresh: true),
                            ),
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
                title: const Text('Payment Entry Report'),
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
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _fetchReport(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reportData.isEmpty
              ? const Center(child: Text('No payment records found.'))
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
              lastDate: DateTime.now(),
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
                  setState(() {
                    _toDate = date;
                  });
                  _fetchReport(refresh: true);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
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
                      'Payment No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _reportData.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _reportData.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  final item = _reportData[index];
                  final isSelected = index == _highlightedIndex;
                  final dateStr = item.paymentMasterPaymentDate != null
                      ? _displayFormat.format(item.paymentMasterPaymentDate!)
                      : '';

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
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(
                                0.3,
                              )
                            : index.isEven
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.5,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text('${index + 1}'),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(dateStr),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.paymentMasterPaymentNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Text(
                              item.paymentMasterTotalAmount.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
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
      itemCount: _reportData.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _reportData.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final item = _reportData[index];
        final dateStr = item.paymentMasterPaymentDate != null
            ? _displayFormat.format(item.paymentMasterPaymentDate!)
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.paymentMasterPaymentNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amount',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '₹${item.paymentMasterTotalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
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
}
