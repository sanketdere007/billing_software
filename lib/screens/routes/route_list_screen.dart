import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import 'route_master_screen.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  final RouteService _routeService = routeService;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  bool? _selectedStatus; // null = All, true = Active, false = Inactive
  bool _isLoading = false;

  String? _errorMessage;
  List<RouteListItem> _allRoutes = [];
  List<RouteListItem> _routes = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    sessionService.addListener(_onSessionChanged);
    _fetchRoutes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  void _onSessionChanged() {
    if (mounted) {
      _fetchRoutes();
    }
  }

  @override
  void dispose() {
    sessionService.removeListener(_onSessionChanged);
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _screenFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _routes.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _routes.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _routes.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _routes.length) {
        _navigateToEditRoute(_routes[_highlightedIndex]);
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

  List<RouteListItem> _applyFilters(List<RouteListItem> source) {
    final search = _searchController.text.trim().toLowerCase();
    final status = _selectedStatus;

    return source.where((r) {
      // 1. Status Filter
      if (status != null && r.routeIsActive != status) {
        return false;
      }

      // 2. Search Text Filter
      if (search.isNotEmpty) {
        final matches =
            r.routeName.toLowerCase().contains(search) ||
            r.routeDescription.toLowerCase().contains(search);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _updateFilteredRoutes() {
    _routes = _applyFilters(_allRoutes);
    if (_routes.isNotEmpty) {
      _highlightedIndex = _highlightedIndex.clamp(0, _routes.length - 1);
    } else {
      _highlightedIndex = 0;
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _updateFilteredRoutes();
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchRoutes();
    });
  }

  void _onStatusChanged(bool? status) {
    setState(() {
      _selectedStatus = status;
      _updateFilteredRoutes();
    });
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final routes = await _routeService.getAllRoutes(
        search: _searchController.text.trim(),
        isActive: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          if (_routeService.routes.isNotEmpty) {
            _allRoutes = _routeService.routes;
          } else if (!_hasActiveFilters) {
            _allRoutes = routes;
          }
          _routes = _applyFilters(
            _allRoutes.isNotEmpty ? _allRoutes : routes,
          );
          _isLoading = false;
          if (_routes.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(
              0,
              _routes.length - 1,
            );
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

  void _clearFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedStatus = null;
      _highlightedIndex = 0;
      _updateFilteredRoutes();
    });
    _fetchRoutes();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedStatus != null;

  void _navigateToEditRoute([RouteListItem? route]) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => RouteMasterScreen(routeToEdit: route),
      ),
    );

    if (result == true || (result != null && result is String)) {
      if (result is String) {
        if (!mounted) return;
        await showSuccessDialog(context, result);
      }
      _fetchRoutes();
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
                          title: const Text('Route List'),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh Routes',
                              onPressed: _isLoading ? null : _fetchRoutes,
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _navigateToEditRoute(),
                              icon: const Icon(
                                Icons.add_box_rounded,
                                size: 18,
                              ),
                              label: const Text('Add Route'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
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

            // Mobile Layout
            return Scaffold(
              appBar: AppBar(
                title: const Text('Route List'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : _fetchRoutes,
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _navigateToEditRoute(),
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Add Route'),
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

  // --- Filter Bars ---

  Widget _buildDesktopFilterBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Description...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _updateFilteredRoutes();
                                });
                                _fetchRoutes();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                          : Colors.grey.shade50,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Status Filter
              _buildStatusFilterSegment(),
              const SizedBox(width: 12),

              // Clear Filter Button
              if (_hasActiveFilters)
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Showing ${_routes.length} ${_routes.length == 1 ? 'route' : 'routes'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.keyboard_outlined, size: 14, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(
                'Use ↑ / ↓ arrows to navigate, Enter to edit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search routes...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _updateFilteredRoutes();
                        });
                        _fetchRoutes();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              PopupMenuButton<bool?>(
                initialValue: _selectedStatus,
                tooltip: 'Filter Status',
                onSelected: _onStatusChanged,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('All Statuses')),
                  const PopupMenuItem(value: true, child: Text('Active Only')),
                  const PopupMenuItem(
                    value: false,
                    child: Text('Inactive Only'),
                  ),
                ],
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedStatus == null
                            ? Icons.filter_list_rounded
                            : (_selectedStatus!
                                ? Icons.check_circle_outline
                                : Icons.pause_circle_outline),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedStatus == null
                            ? 'Status'
                            : (_selectedStatus! ? 'Active' : 'Inactive'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  tooltip: 'Reset Filters',
                  onPressed: _clearFilters,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterSegment() {
    return SizedBox(
      height: 44,
      child: SegmentedButton<bool?>(
        segments: const [
          ButtonSegment<bool?>(value: null, label: Text('All')),
          ButtonSegment<bool?>(value: true, label: Text('Active')),
          ButtonSegment<bool?>(value: false, label: Text('Inactive')),
        ],
        selected: {_selectedStatus},
        onSelectionChanged: (Set<bool?> newSelection) {
          _onStatusChanged(newSelection.first);
        },
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // --- Main Body Content ---

  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading && _routes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading routes...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchRoutes,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _hasActiveFilters
                    ? 'No routes match your filter criteria.'
                    : 'No routes added yet.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try clearing filters or search query.'
                    : 'Click "Add Route" to create your first route record.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (_hasActiveFilters)
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Clear Filters'),
                )
              else
                FilledButton.icon(
                  onPressed: () => _navigateToEditRoute(),
                  icon: const Icon(Icons.add_box_rounded),
                  label: const Text('Add New Route'),
                ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopDataTable();
    } else {
      return _buildMobileListView();
    }
  }

  // --- Desktop Sticky Header Data Table ---

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      child: Column(
        children: [
          // Sticky Table Header
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildHeaderCell('#', width: 50, alignment: Alignment.center),
                _buildHeaderCell('Route Name', flex: 2),
                _buildHeaderCell('Description', flex: 3),
                _buildHeaderCell(
                  'Status',
                  width: 100,
                  alignment: Alignment.center,
                ),
                _buildHeaderCell(
                  'Actions',
                  width: 120,
                  alignment: Alignment.centerRight,
                ),
              ],
            ),
          ),

          // Table Rows
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                final isHighlighted = _highlightedIndex == index;

                Color rowBackground;
                if (isHighlighted) {
                  rowBackground = theme.colorScheme.primaryContainer
                      .withOpacity(isDark ? 0.35 : 0.25);
                } else if (index.isOdd) {
                  rowBackground = isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.white;
                } else {
                  rowBackground = isDark
                      ? Colors.transparent
                      : Colors.grey.shade50.withOpacity(0.5);
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _highlightedIndex = index;
                    });
                    _showRouteDetailsDialog(route);
                  },
                  onDoubleTap: () => _navigateToEditRoute(route),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: rowBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.06),
                          width: 1,
                        ),
                        left: isHighlighted
                            ? BorderSide(
                                color: theme.colorScheme.primary,
                                width: 4,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Row Index
                        SizedBox(
                          width: 50,
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // Route Name
                        Expanded(
                          flex: 2,
                          child: Text(
                            route.routeName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Description
                        Expanded(
                          flex: 3,
                          child: Text(
                            route.routeDescription.isNotEmpty
                                ? route.routeDescription
                                : '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: route.routeDescription.isNotEmpty
                                  ? null
                                  : theme.hintColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Status Badge
                        SizedBox(
                          width: 100,
                          child: Center(
                            child: _buildStatusBadge(route.routeIsActive),
                          ),
                        ),

                        // Actions
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                tooltip: 'View Details',
                                splashRadius: 18,
                                onPressed: () =>
                                    _showRouteDetailsDialog(route),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit Route',
                                splashRadius: 18,
                                onPressed: () =>
                                    _navigateToEditRoute(route),
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
    );
  }

  Widget _buildHeaderCell(
    String title, {
    int flex = 1,
    double? width,
    Alignment alignment = Alignment.centerLeft,
  }) {
    final theme = Theme.of(context);

    final child = Align(
      alignment: alignment,
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isActive ? Colors.green : Colors.grey).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Mobile Responsive Card List ---

  Widget _buildMobileListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _routes.length,
      itemBuilder: (context, index) {
        final route = _routes[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1.5,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showRouteDetailsDialog(route),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar, Name, Status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.map_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.routeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(route.routeIsActive),
                    ],
                  ),
                  const Divider(height: 20),

                  // Info Rows
                  if (route.routeDescription.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            route.routeDescription,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Action Buttons
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        onPressed: () => _showRouteDetailsDialog(route),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        onPressed: () => _navigateToEditRoute(route),
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

  void _showRouteDetailsDialog(RouteListItem route) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Route Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${route.routeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Description: ${route.routeDescription.isNotEmpty ? route.routeDescription : "—"}'),
              const SizedBox(height: 8),
              Text('Status: ${route.routeIsActive ? "Active" : "Inactive"}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToEditRoute(route);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }
}
