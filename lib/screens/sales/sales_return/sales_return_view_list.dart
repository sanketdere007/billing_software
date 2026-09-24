import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/sales_return.dart';
import '../../../services/sales_return_service.dart';
import '../../../widgets/direct_back_scope.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/custom_date_picker_field.dart';
import '../../../services/session_service.dart';
import '../../../widgets/app_confirm_dialog.dart';

class SalesReturnViewList extends StatefulWidget {
  const SalesReturnViewList({super.key});

  @override
  State<SalesReturnViewList> createState() => _SalesReturnViewListState();
}

class _SalesReturnViewListState extends State<SalesReturnViewList> {
  final SalesReturnService _salesReturnService = SalesReturnService();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<SalesReturnMasterDataListItem> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _highlightedIndex = 0;

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
        fromDateStr = _fromDate!.toIso8601String();
      }
      if (_toDate != null) {
        toDateStr = _toDate!.toIso8601String();
      }

      final response = await _salesReturnService.getSalesReturnList(
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
          final newItems = response.data;
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

  void _selectEntry(SalesReturnMasterDataListItem entry) {
    Navigator.pop(context, entry);
  }

  Future<void> _deleteEntry(int salesReturnMasterId) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete Sales Return',
      message:
          'Are you sure you want to delete this sales return? This action cannot be undone.',
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _salesReturnService.deleteSalesReturnApi(salesReturnMasterId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales return deleted successfully.')),
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
                          title: const Text('View Sales Returns'),
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
                title: const Text('View Sales Returns'),
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
          const Expanded(child: Center(child: Text('No sales return entries found.')))
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
                        flex: 1,
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
                                  raw['salesReturnMaster_InvoiceNo']?.toString() ??
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
                                  raw['salesReturnMaster_Date']
                                          ?.toString()
                                          .split('T')
                                          .first ??
                                      '',
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${raw['salesReturnMaster_TotalQty'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesReturnMaster_DiscountAmount'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesReturnMaster_PaidAmount'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesReturnMaster_BalanceAmount'] ?? 0}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${raw['salesReturnMaster_GrandTotal'] ?? 0}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    final id = raw['salesReturnMaster_Id'];
                                    if (id != null) {
                                      _deleteEntry(
                                        id is int
                                            ? id
                                            : int.parse(id.toString()),
                                      );
                                    }
                                  },
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
