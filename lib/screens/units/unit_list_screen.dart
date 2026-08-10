import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/unit.dart';
import '../../services/unit_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import 'unit_master_screen.dart';

/// Unit List Screen with search, status filter, keyboard navigation, and navigation to UnitMasterScreen
class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  final UnitService _unitService = unitService;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  bool? _selectedStatus; // null = All, true = Active, false = Inactive
  bool _isLoading = false;
  String? _errorMessage;
  List<UnitListItem> _units = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    _fetchUnits();

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
    if (event is! KeyDownEvent || _units.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _units.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _units.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _units.length) {
        _navigateToAddUnit(_units[_highlightedIndex]);
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
      _applyFilters();
    });
  }

  Future<void> _fetchUnits() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _unitService.getAllUnits(
        isActive: _selectedStatus,
      );

      _applyFilters();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    
    final allUnits = _unitService.units;
    final query = _searchController.text.trim().toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _units = allUnits;
      } else {
        _units = allUnits.where((u) {
          return u.unitName.toLowerCase().contains(query) || u.unitShortName.toLowerCase().contains(query);
        }).toList();
      }
      
      _isLoading = false;
      if (_units.isNotEmpty) {
        _highlightedIndex = _highlightedIndex.clamp(0, _units.length - 1);
      } else {
        _highlightedIndex = 0;
      }
    });
    
    if (_units.isNotEmpty) {
      _scrollToIndex(_highlightedIndex);
    }
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedStatus = null;
      _highlightedIndex = 0;
    });
    _fetchUnits();
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedStatus != null;

  void _navigateToAddUnit([UnitListItem? unit]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UnitMasterScreen(unitToEdit: unit),
      ),
    );

    if (result == true) {
      _fetchUnits();
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
                        title: const Text('Unit Master'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Refresh Units',
                            onPressed: _isLoading ? null : _fetchUnits,
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => _navigateToAddUnit(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Unit'),
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
              title: const Text('Unit Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: _isLoading ? null : _fetchUnits,
                ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _navigateToAddUnit(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Unit'),
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
                hintText: 'Search by unit name...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchUnits();
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
                _fetchUnits();
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
              hintText: 'Search unit name...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _fetchUnits();
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
              PopupMenuButton<bool?>(
                initialValue: _selectedStatus,
                tooltip: 'Filter Status',
                onSelected: (val) {
                  setState(() {
                    _selectedStatus = val;
                  });
                  _fetchUnits();
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
                          fontSize: 12,
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

  // Body Content (Table on Desktop, Cards on Mobile)
  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading units from server...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _units.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load units',
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
                onPressed: _fetchUnits,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_units.isEmpty) {
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
                  Icons.straighten_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _hasActiveFilters ? 'No units match your filter' : 'No units found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try clearing your search query'
                    : 'Get started by creating your first unit master record',
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
                  onPressed: () => _navigateToAddUnit(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add First Unit'),
                ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopDataTable();
    } else {
      return _buildMobileCardList();
    }
  }

  // Desktop Data Table with Sticky Header
  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Table Subheader with records count & keyboard shortcut tip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
          child: Row(
            children: [
              Text(
                'Showing ${_units.length} ${_units.length == 1 ? 'unit' : 'units'}',
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

        // Table with Sticky Header
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
                  const double minTableWidth = 700.0;
                  final tableWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

                  Widget tableContent = SizedBox(
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
                              SizedBox(
                                width: 60,
                                child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text('Unit Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Short Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              SizedBox(
                                width: 120,
                                child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                              ),
                            ],
                          ),
                        ),

                        // SCROLLABLE ROWS
                        Expanded(
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount: _units.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                            itemBuilder: (context, index) {
                              final unit = _units[index];
                              final isHighlighted = index == _highlightedIndex;

                              return Material(
                                color: isHighlighted
                                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.12)
                                    : Colors.transparent,
                                child: InkWell(
                                  hoverColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                  onTap: () {
                                    setState(() => _highlightedIndex = index);
                                    _navigateToAddUnit(unit);
                                  },
                                  child: Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        // Index with Highlight Indicator
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

                                        // Unit Name
                                        Expanded(
                                          flex: 4,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(Icons.straighten_rounded, size: 16, color: theme.colorScheme.primary),
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  unit.unitName,
                                                  style: TextStyle(
                                                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                                                    color: isHighlighted ? theme.colorScheme.primary : null,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Short Name
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            unit.unitShortName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Status
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: unit.unitIsActive
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: unit.unitIsActive
                                                      ? Colors.green.shade300
                                                      : Colors.red.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    unit.unitIsActive ? Icons.check_circle : Icons.cancel,
                                                    size: 14,
                                                    color: unit.unitIsActive ? Colors.green.shade700 : Colors.red.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    unit.unitIsActive ? 'Active' : 'Inactive',
                                                    style: TextStyle(
                                                      color: unit.unitIsActive ? Colors.green.shade800 : Colors.red.shade800,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Actions
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (isHighlighted)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  margin: const EdgeInsets.only(right: 6),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primaryContainer,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '↵ Enter',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit_outlined,
                                                  size: 20,
                                                  color: isHighlighted ? theme.colorScheme.primary : Colors.blueAccent,
                                                ),
                                                tooltip: 'Edit Unit',
                                                splashRadius: 20,
                                                onPressed: () {
                                                  setState(() => _highlightedIndex = index);
                                                  _navigateToAddUnit(unit);
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

                  if (constraints.maxWidth < minTableWidth) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: tableContent,
                    );
                  }
                  return tableContent;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile / Tablet Card List
  Widget _buildMobileCardList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(14),
      itemCount: _units.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final unit = _units[index];
        final isHighlighted = index == _highlightedIndex;

        return Card(
          elevation: isHighlighted ? 3 : 1,
          color: isHighlighted
              ? theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.08)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _highlightedIndex = index);
              _navigateToAddUnit(unit);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.straighten_rounded,
                      color: isHighlighted
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.unitName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isHighlighted ? theme.colorScheme.primary : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.short_text_rounded, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                unit.unitShortName,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: unit.unitIsActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: unit.unitIsActive ? Colors.green.shade300 : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          unit.unitIsActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: unit.unitIsActive ? Colors.green.shade800 : Colors.red.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHighlighted)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '↵ Enter',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isHighlighted
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
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
    );
  }
}
