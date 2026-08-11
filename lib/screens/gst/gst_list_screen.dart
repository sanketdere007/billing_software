import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gst.dart';
import '../../services/gst_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import 'add_gst_screen.dart';

class GstListScreen extends StatefulWidget {
  const GstListScreen({super.key});

  @override
  State<GstListScreen> createState() => _GstListScreenState();
}

class _GstListScreenState extends State<GstListScreen> {
  final GstService _gstService = gstService;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  bool? _selectedStatus; // null = All, true = Active, false = Inactive
  bool _isLoading = false;
  String? _errorMessage;
  List<GstTaxListItem> _gsts = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    _fetchGsts();

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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _gsts.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _gsts.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _gsts.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _gsts.length) {
        _navigateToAddGst(_gsts[_highlightedIndex]);
        return KeyEventResult.handled;
      }
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

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _highlightedIndex = 0;
      });
      // GST API doesn't have a Search parameter yet, but we can filter locally or modify if backend supports
      // Since backend api only has Supp_Id / IsActive in params for now, we'll filter the fetched list locally for search
    });
  }

  Future<void> _fetchGsts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gsts = await _gstService.getAllGsts(
        isActive: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _gsts = gsts;
          _isLoading = false;
          if (_gsts.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(0, _gsts.length - 1);
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

  List<GstTaxListItem> get _filteredGsts {
    if (_searchController.text.trim().isEmpty) return _gsts;
    final query = _searchController.text.trim().toLowerCase();
    return _gsts.where((g) => 
        g.gstTaxName.toLowerCase().contains(query) || 
        g.gstTaxPercentage.toString().contains(query)
    ).toList();
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedStatus = null;
      _highlightedIndex = 0;
    });
    _fetchGsts();
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedStatus != null;

  void _navigateToAddGst([GstTaxListItem? gst]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddGstScreen(gstToEdit: gst),
      ),
    );

    if (result == true) {
      _fetchGsts();
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
                          title: const Text('GST Master'),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh GST Taxes',
                              onPressed: _isLoading ? null : _fetchGsts,
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _navigateToAddGst(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add GST Tax'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                        body: Column(
                          children: [
                            _buildDesktopFilterBar(),
                            Expanded(child: _buildBodyContent(isDesktop: true)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile / Tablet view
            return Scaffold(
              appBar: AppBar(
                title: const Text('GST Master'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : _fetchGsts,
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _navigateToAddGst(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add GST Tax'),
              ),
              body: Column(
                children: [
                  _buildMobileFilterBar(),
                  Expanded(child: _buildBodyContent(isDesktop: false)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Desktop Filter Bar
  Widget _buildDesktopFilterBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by GST name or %...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status Filter Segmented Button
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SegmentedButton<bool?>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<bool?>(value: null, label: Text('All')),
                ButtonSegment<bool?>(value: true, label: Text('Active')),
                ButtonSegment<bool?>(value: false, label: Text('Inactive')),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (Set<bool?> selection) {
                setState(() {
                  _selectedStatus = selection.first;
                });
                _fetchGsts();
              },
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          if (_hasActiveFilters) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Mobile Filter Bar
  Widget _buildMobileFilterBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search GST...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 10),

          // Filters Row
          Row(
            children: [
              Expanded(
                child: PopupMenuButton<bool?>(
                  initialValue: _selectedStatus,
                  tooltip: 'Filter Status',
                  onSelected: (val) {
                    setState(() {
                      _selectedStatus = val;
                    });
                    _fetchGsts();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('All Statuses')),
                    const PopupMenuItem(value: true, child: Text('Active Only')),
                    const PopupMenuItem(value: false, child: Text('Inactive Only')),
                  ],
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedStatus != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _selectedStatus != null
                          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: _selectedStatus != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedStatus == null
                              ? 'Status'
                              : (_selectedStatus! ? 'Active' : 'Inactive'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedStatus != null ? FontWeight.bold : FontWeight.normal,
                            color: _selectedStatus != null
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                  tooltip: 'Clear filters',
                  splashRadius: 20,
                  onPressed: _clearFilters,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Body Content
  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading GST Taxes from server...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _gsts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load GST Taxes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _fetchGsts,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final displayList = _filteredGsts;

    if (displayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _hasActiveFilters ? 'No GST Taxes match your filter' : 'No GST Taxes found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try clearing your search query or status filter'
                    : 'Get started by creating your first GST Tax record',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              if (_hasActiveFilters)
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Clear Filters'),
                )
              else
                FilledButton.icon(
                  onPressed: () => _navigateToAddGst(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add First GST Tax'),
                ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopDataTable(displayList);
    } else {
      return _buildMobileCardList(displayList);
    }
  }

  // Desktop Data Table
  Widget _buildDesktopDataTable(List<GstTaxListItem> displayList) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
          child: Row(
            children: [
              Text(
                'Showing ${displayList.length} ${displayList.length == 1 ? 'record' : 'records'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_outlined, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Text(
                      'Use ↑ / ↓ to navigate • Enter / Click to Edit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double minTableWidth = 800.0;
                  final tableWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

                  return SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        // STICKY HEADER ROW
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                            border: Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 60, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 3, child: Text('GST Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 2, child: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 2, child: Text('CGST %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 2, child: Text('SGST %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 2, child: Text('IGST %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),

                        // SCROLLABLE ROWS
                        Expanded(
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount: displayList.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                            itemBuilder: (context, index) {
                              final gst = displayList[index];
                              final isHighlighted = index == _highlightedIndex;

                              return Material(
                                color: isHighlighted
                                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.12)
                                    : Colors.transparent,
                                child: InkWell(
                                  hoverColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                  onTap: () {
                                    setState(() => _highlightedIndex = index);
                                    _navigateToAddGst(gst);
                                  },
                                  child: Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isHighlighted)
                                                Container(
                                                  width: 3.5,
                                                  height: 24,
                                                  margin: const EdgeInsets.only(right: 6),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                              Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: isHighlighted
                                                      ? theme.colorScheme.primary
                                                      : Colors.grey.shade600,
                                                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(gst.gstTaxName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('${gst.gstTaxPercentage.toStringAsFixed(2)}%'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('${gst.gstTaxCgst.toStringAsFixed(2)}%'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('${gst.gstTaxSgst.toStringAsFixed(2)}%'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('${gst.gstTaxIgst.toStringAsFixed(2)}%'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: gst.gstTaxIsActive
                                                    ? Colors.green.withOpacity(0.15)
                                                    : Colors.red.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: gst.gstTaxIsActive
                                                      ? Colors.green.withOpacity(0.3)
                                                      : Colors.red.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                gst.gstTaxIsActive ? 'Active' : 'Inactive',
                                                style: TextStyle(
                                                  color: gst.gstTaxIsActive
                                                      ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                                      : (isDark ? Colors.red.shade300 : Colors.red.shade700),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18),
                                                color: theme.colorScheme.primary,
                                                tooltip: 'Edit GST Tax',
                                                splashRadius: 20,
                                                onPressed: () {
                                                  setState(() => _highlightedIndex = index);
                                                  _navigateToAddGst(gst);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Card List
  Widget _buildMobileCardList(List<GstTaxListItem> displayList) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final gst = displayList[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToAddGst(gst),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          gst.gstTaxName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: gst.gstTaxIsActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          gst.gstTaxIsActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: gst.gstTaxIsActive
                                ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                : (isDark ? Colors.red.shade300 : Colors.red.shade700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(theme, 'GST', '${gst.gstTaxPercentage}%', Colors.blue),
                      const SizedBox(width: 8),
                      _buildInfoChip(theme, 'CGST', '${gst.gstTaxCgst}%', Colors.purple),
                      const SizedBox(width: 8),
                      _buildInfoChip(theme, 'SGST', '${gst.gstTaxSgst}%', Colors.teal),
                    ],
                  ),
                  if (gst.gstTaxIgst > 0) ...[
                    const SizedBox(height: 8),
                    _buildInfoChip(theme, 'IGST', '${gst.gstTaxIgst}%', Colors.orange),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(ThemeData theme, String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
