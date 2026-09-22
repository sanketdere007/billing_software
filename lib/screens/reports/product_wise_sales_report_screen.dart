import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/product_wise_sales_report.dart';
import '../../services/product_wise_sales_report_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/custom_date_picker_field.dart';
import 'product_wise_customer_purchase_list_screen.dart';

class ProductWiseSalesReportScreen extends StatefulWidget {
  const ProductWiseSalesReportScreen({super.key});

  @override
  State<ProductWiseSalesReportScreen> createState() => _ProductWiseSalesReportScreenState();
}

class _ProductWiseSalesReportScreenState extends State<ProductWiseSalesReportScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 15;
  
  String? _errorMessage;
  List<ProductWiseSalesItem> _reportData = [];
  int _highlightedIndex = 0;

  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate = DateTime.now();

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
    _searchController.dispose();
    _debounce?.cancel();
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
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;
      
      final response = await productWiseSalesReportService.getProductWiseSalesReport(
        compId: compId,
        branchId: branchId,
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        searchText: _searchController.text.trim(),
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (response.items.isEmpty) {
            _hasMoreData = false;
          } else {
            _pageNumber = nextPage;
            _reportData.addAll(response.items);
            if (response.items.length < _pageSize) {
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

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _reportData.length) {
        _navigateToDetails(_reportData[_highlightedIndex]);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double rowHeight = 58.0; 
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
        _highlightedIndex = 0;
      }
    });

    try {
      final compId = sessionService.selectedCompId ?? 0;
      final branchId = sessionService.selectedBranchId ?? 0;

      final response = await productWiseSalesReportService.getProductWiseSalesReport(
        compId: compId,
        branchId: branchId,
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        searchText: _searchController.text.trim(),
        pageNumber: 1,
        pageSize: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          if (response.status) {
            _reportData = response.items;
            _hasMoreData = response.items.length == _pageSize;
          } else {
            _errorMessage = response.message.isNotEmpty ? response.message : 'Unknown error';
          }
          _isLoading = false;
          
          if (_reportData.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(0, _reportData.length - 1);
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

  void _navigateToDetails(ProductWiseSalesItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductWiseCustomerPurchaseListScreen(
          productId: item.productId,
          productName: item.productName,
          fromDate: _fromDate ?? DateTime.now(),
          toDate: _toDate ?? DateTime.now(),
        ),
      ),
    );
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
                          title: const Text('Product Wise Sales Report'),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                              onPressed: _isLoading ? null : () => _fetchReport(refresh: true),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                        body: Column(
                          children: [
                            _buildFilterRow(),
                            Expanded(child: _buildBodyContent(isDesktop: true)),
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
                title: const Text('Product Wise Sales'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : () => _fetchReport(refresh: true),
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: Column(
                children: [
                  _buildFilterRow(),
                  Expanded(child: _buildBodyContent(isDesktop: false)),
                ],
              ),
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
                  _fetchReport(refresh: true);
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
                      content: Text('To Date cannot be earlier than From Date.'),
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
    );
  }

  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading && _reportData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _reportData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load report', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => _fetchReport(refresh: true), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_reportData.isEmpty) {
      return const Center(child: Text('No records found.'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
          child: Row(
            children: [
              Text(
                'Showing ${_reportData.length} records',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isDesktop)
                Text(
                  'Use ↑ / ↓ arrows to navigate, Enter to view details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: 11,
                  ),
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('HSN Code', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Quantity', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
             //     Expanded(flex: 1, child: Text('Free Qty', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Total Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
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
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _highlightedIndex = index;
                      });
                      _navigateToDetails(item);
                    },
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 50, child: Text('${index + 1}')),
                          Expanded(flex: 3, child: Text(item.productName.isNotEmpty ? item.productName : 'N/A')),
                          Expanded(flex: 1, child: Text(item.hsnCode.isNotEmpty ? item.hsnCode : '-')),
                          Expanded(flex: 1, child: Text(item.totalQty.toStringAsFixed(2), textAlign: TextAlign.right)),
                        //  Expanded(flex: 1, child: Text(item.totalFreeQty.toStringAsFixed(2), textAlign: TextAlign.right)),
                          Expanded(
                            flex: 2, 
                            child: Text(
                              '₹ ${item.totalAmount.toStringAsFixed(2)}', 
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
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
        
        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
          child: ListTile(
            title: Text(item.productName.isNotEmpty ? item.productName : 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HSN: ${item.hsnCode.isNotEmpty ? item.hsnCode : '-'} • Invoices: ${item.totalInvoices}'),
                Text('Qty: ${item.totalQty.toStringAsFixed(2)} • Free: ${item.totalFreeQty.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text(
                  'Amount: ₹ ${item.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _highlightedIndex = index;
              });
              _navigateToDetails(item);
            },
          ),
        );
      },
    );
  }
}
