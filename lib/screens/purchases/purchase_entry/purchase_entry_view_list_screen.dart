import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/purchase_entry.dart';
import '../../../services/purchase_entry_service.dart';
import '../../../widgets/app_drawer.dart';

class PurchaseEntryViewListScreen extends StatefulWidget {
  const PurchaseEntryViewListScreen({super.key});

  @override
  State<PurchaseEntryViewListScreen> createState() => _PurchaseEntryViewListScreenState();
}

class _PurchaseEntryViewListScreenState extends State<PurchaseEntryViewListScreen> {
  final PurchaseEntryService _purchaseEntryService = PurchaseEntryService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  bool _isLoading = false;
  String? _errorMessage;
  
  List<PurchaseMasterViewItem> _entries = [];
  int _highlightedIndex = 0;

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    _fetchEntries();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _screenFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchEntries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responseData = await _purchaseEntryService.getPurchaseMasterViewList(
        pageNumber: 1,
        pageSize: 1000,
        searchText: _searchController.text.trim(),
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (mounted) {
        setState(() {
          _entries = responseData.items;
          _isLoading = false;
          if (_entries.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(0, _entries.length - 1);
          } else {
            _highlightedIndex = 0;
          }
        });
        _scrollToIndex(_highlightedIndex);
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

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchEntries();
    });
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

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _entries.length) {
        Navigator.pop(context, _entries[_highlightedIndex]);
        return KeyEventResult.handled;
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    Widget content = Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search Purchase Invoices...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _fetchEntries();
                                _screenFocusNode.requestFocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Use ↑ / ↓ to navigate, Enter to select',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _entries.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _entries.isEmpty
                        ? const Center(child: Text('No purchase entries found.'))
                        : Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  border: Border(
                                    bottom: BorderSide(color: theme.dividerColor),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text('#', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('Date', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('Invoice Number', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text('Supplier Name', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text('Amount', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Table Body
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: _entries.length,
                                  itemBuilder: (context, index) {
                                    final item = _entries[index];
                                    final isSelected = index == _highlightedIndex;
                                    final dateFormat = DateFormat('dd/MM/yyyy');
                                    DateTime parsedDate;
                                    try {
                                      parsedDate = DateTime.parse(item.invoiceDate);
                                    } catch (_) {
                                      parsedDate = DateTime.now();
                                    }

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _highlightedIndex = index;
                                        });
                                        Navigator.pop(context, item);
                                      },
                                      child: Container(
                                        height: 60,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                                              : (index.isEven ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : Colors.transparent),
                                          border: Border(
                                            bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
                                            left: isSelected ? BorderSide(color: theme.colorScheme.primary, width: 4) : BorderSide.none,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: theme.hintColor,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                dateFormat.format(parsedDate),
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                  color: isSelected ? theme.colorScheme.primary : theme.hintColor,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                item.invoiceNo,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  color: isSelected ? theme.colorScheme.primary : null,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                item.suppName,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: Text(
                                                  '₹${item.netAmount.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
        ],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(title: const Text('Select Purchase Entry')),
                body: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Purchase Entry')),
      body: content,
    );
  }
}
