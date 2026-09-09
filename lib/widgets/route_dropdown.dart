import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';

class RouteDropdown extends StatefulWidget {
  final int? selectedRouteId;
  final ValueChanged<RouteListItem?>? onChanged;
  final String labelText;
  final String hintText;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const RouteDropdown({
    super.key,
    this.selectedRouteId,
    this.onChanged,
    this.labelText = 'Route',
    this.hintText = 'Select Route',
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<RouteDropdown> createState() => _RouteDropdownState();
}

class _RouteDropdownState extends State<RouteDropdown> {
  final RouteService _routeService = routeService;
  bool _isLoading = false;
  RouteListItem? _selectedRoute;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<RouteListItem> _availableRoutes = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadRoutes();
  }

  @override
  void didUpdateWidget(covariant RouteDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRouteId != widget.selectedRouteId) {
      _syncSelectedRoute();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _syncSelectedRoute() {
    if (widget.selectedRouteId == null || widget.selectedRouteId! <= 0) {
      _selectedRoute = null;
    } else {
      _selectedRoute = _availableRoutes.firstWhere(
        (r) => r.routeId == widget.selectedRouteId,
        orElse: () => RouteListItem(
          routeId: widget.selectedRouteId!,
          routeName: 'Route #${widget.selectedRouteId}',
        ),
      );
    }
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await _routeService.getAllRoutes();
      if (mounted) {
        _availableRoutes = routes;
        _syncSelectedRoute();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSearchDialog() async {
    if (_isLoading) return;
    if (_availableRoutes.isEmpty) {
      await _loadRoutes();
      if (_availableRoutes.isEmpty) return;
    }
    
    if (!mounted) return;

    final RouteListItem? picked = await showDialog<RouteListItem?>(
      context: context,
      builder: (context) => _RouteSearchDialog(
        routes: _availableRoutes,
        selectedRouteId: _selectedRoute?.routeId,
      ),
    );

    if (picked != null) {
      setState(() => _selectedRoute = picked);
      widget.onChanged?.call(picked);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.nextFocusNode?.requestFocus();
      });
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayText = _selectedRoute?.routeName ?? widget.hintText;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.enter || 
             event.logicalKey == LogicalKeyboardKey.space || 
             event.logicalKey == LogicalKeyboardKey.arrowDown)) {
          _openSearchDialog();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: _openSearchDialog,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.outline,
              width: _isFocused ? 2 : 1,
            ),
            color: theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              Icon(
                Icons.route_outlined,
                size: 18,
                color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedRoute != null)
                      Text(
                        widget.labelText,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          fontWeight: _isFocused ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    Text(
                      displayText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _selectedRoute == null 
                            ? theme.colorScheme.onSurfaceVariant.withOpacity(0.6) 
                            : theme.colorScheme.onSurface,
                        fontWeight: _selectedRoute != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isFocused)
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
              Icon(
                Icons.arrow_drop_down_rounded,
                color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSearchDialog extends StatefulWidget {
  final List<RouteListItem> routes;
  final int? selectedRouteId;

  const _RouteSearchDialog({required this.routes, this.selectedRouteId});

  @override
  State<_RouteSearchDialog> createState() => _RouteSearchDialogState();
}

class _RouteSearchDialogState extends State<_RouteSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<RouteListItem> _filteredRoutes = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredRoutes = widget.routes;
    _searchController.addListener(_onSearchChanged);

    if (widget.selectedRouteId != null) {
      final index = widget.routes.indexWhere((r) => r.routeId == widget.selectedRouteId);
      if (index != -1) _highlightedIndex = index;
    }

    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        _scrollToIndex(_highlightedIndex);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRoutes = widget.routes;
      } else {
        _filteredRoutes = widget.routes.where((r) => r.routeName.toLowerCase().contains(query)).toList();
      }
      _highlightedIndex = 0;
    });
    _scrollToIndex(0);
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = index * 56.0;
      final current = _scrollController.offset;
      final viewport = _scrollController.position.viewportDimension;
      final max = _scrollController.position.maxScrollExtent;
      if (target < current) {
        _scrollController.animateTo(target.clamp(0.0, max), duration: const Duration(milliseconds: 80), curve: Curves.easeOut);
      } else if (target + 56.0 > current + viewport) {
        _scrollController.animateTo((target + 56.0 - viewport).clamp(0.0, max), duration: const Duration(milliseconds: 80), curve: Curves.easeOut);
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final total = _filteredRoutes.length;
    if (total == 0) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlightedIndex = (_highlightedIndex + 1) % total);
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlightedIndex = (_highlightedIndex - 1 + total) % total);
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _selectHighlighted();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _selectHighlighted() {
    if (_highlightedIndex >= 0 && _highlightedIndex < _filteredRoutes.length) {
      Navigator.pop(context, _filteredRoutes[_highlightedIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.route_outlined, color: theme.colorScheme.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Select Route', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search route...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: _filteredRoutes.length,
                itemBuilder: (context, index) {
                  final route = _filteredRoutes[index];
                  final isHighlighted = index == _highlightedIndex;
                  final isSelected = route.routeId == widget.selectedRouteId;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isHighlighted ? theme.colorScheme.primary.withOpacity(isDark ? 0.25 : 0.12) : (isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.4) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: isHighlighted ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.route_rounded, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                      title: Text(route.routeName, style: TextStyle(fontWeight: isSelected || isHighlighted ? FontWeight.bold : FontWeight.w500, color: isSelected || isHighlighted ? theme.colorScheme.primary : null)),
                      onTap: () => Navigator.pop(context, route),
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
}
