import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import '../../widgets/app_drawer.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteListItem route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final RouteService _routeService = routeService;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _details = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchDetails();
    });
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _routeService.getAllRouteDetails(
        widget.route.routeId,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
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
    _searchController.clear();
    _fetchDetails();
  }

  Future<void> _deleteDetail(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _routeService.deleteRouteDetail(id);

      if (!mounted) return;

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Removed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _fetchDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Failed to remove',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text('${widget.route.routeName} - Details'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Refresh Details',
                          onPressed: _isLoading ? null : _fetchDetails,
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
            title: Text('${widget.route.routeName} - Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: _isLoading ? null : _fetchDetails,
              ),
            ],
          ),
          drawer: const AppDrawer(isPermanent: false),
          body: Column(
            children: [
              _buildMobileFilterBar(),
              Expanded(child: _buildBodyContent(isDesktop: false)),
            ],
          ),
        );
      },
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
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search route details...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: _clearFilters,
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
              Expanded(flex: 2, child: Container()), // Spacer for alignment
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Showing ${_details.length} ${_details.length == 1 ? 'record' : 'records'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
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
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search details...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _clearFilters,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }

  // --- Main Body Content ---

  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading && _details.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _details.isEmpty) {
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
                onPressed: _fetchDetails,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_details.isEmpty) {
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
                _searchController.text.isNotEmpty
                    ? 'No details match your search query.'
                    : 'No details found for this route.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (_searchController.text.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Clear Search'),
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
                _buildHeaderCell('Area Name', flex: 3),
                _buildHeaderCell(
                  'Action',
                  width: 100,
                  alignment: Alignment.center,
                ),
              ],
            ),
          ),

          // Table Rows
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _details.length,
              itemBuilder: (context, index) {
                final detail = _details[index];

                Color rowBackground;
                if (index.isOdd) {
                  rowBackground = isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.white;
                } else {
                  rowBackground = isDark
                      ? Colors.transparent
                      : Colors.grey.shade50.withOpacity(0.5);
                }

                return Container(
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
                          detail['route_Name']?.toString() ??
                              widget.route.routeName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Area Name
                      Expanded(
                        flex: 3,
                        child: Text(
                          detail['area_Name']?.toString() ??
                              detail['areaName']?.toString() ??
                              '—',
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Action
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: _details.length > 1
                              ? TextButton(
                                  onPressed: () {
                                    final id =
                                        int.tryParse(
                                          detail['routeDetail_Id']
                                                  ?.toString() ??
                                              detail['routeDetailId']
                                                  ?.toString() ??
                                              detail['id']?.toString() ??
                                              '0',
                                        ) ??
                                        0;
                                    if (id > 0) {
                                      _deleteDetail(id);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invalid detail ID'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Remove'),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }

  // --- Mobile Responsive Card List ---

  Widget _buildMobileListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _details.length,
      itemBuilder: (context, index) {
        final detail = _details[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.map_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        detail['route_Name']?.toString() ??
                            widget.route.routeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Area Name: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          detail['area_Name']?.toString() ??
                              detail['areaName']?.toString() ??
                              '—',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_details.length > 1) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        final id =
                            int.tryParse(
                              detail['routeDetail_Id']?.toString() ??
                                  detail['routeDetailId']?.toString() ??
                                  detail['id']?.toString() ??
                                  '0',
                            ) ??
                            0;
                        if (id > 0) {
                          _deleteDetail(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid detail ID'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Remove'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
