import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/subcategory.dart';
import '../../models/category.dart';
import '../../services/subcategory_service.dart';
import '../../services/category_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import 'subcategory_master_screen.dart';

/// SubCategory List Screen with search, category filter, status filter, keyboard navigation, and navigation to SubCategoryMasterScreen
class SubCategoryListScreen extends StatefulWidget {
  const SubCategoryListScreen({super.key});

  @override
  State<SubCategoryListScreen> createState() => _SubCategoryListScreenState();
}

class _SubCategoryListScreenState extends State<SubCategoryListScreen> {
  final SubCategoryService _subcategoryService = subcategoryService;
  final CategoryService _categoryService = categoryService;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  int? _selectedCategoryId;
  bool? _selectedStatus; // null = All, true = Active, false = Inactive
  bool _isLoading = false;
  String? _errorMessage;
  List<SubCategoryListItem> _allSubCategories = [];
  List<SubCategoryListItem> _subcategories = [];
  List<CategoryListItem> _categories = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    _fetchCategories();
    _fetchSubCategories();

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

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryService.getAllCategories(isActive: true);
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (_) {
      // Ignore
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _subcategories.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _subcategories.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _subcategories.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _subcategories.length) {
        _navigateToAddSubCategory(_subcategories[_highlightedIndex]);
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

  Future<void> _fetchSubCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subcategories = await _subcategoryService.getAllSubCategories(isActive: _selectedStatus);

      if (mounted) {
        setState(() {
          _allSubCategories = subcategories;
          _isLoading = false;
        });
        _applyFilters();
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

  void _applyFilters() {
    setState(() {
      _subcategories = _allSubCategories.where((c) {
        final matchesSearch = c.subCatName.toLowerCase().contains(_searchController.text.trim().toLowerCase()) ||
            c.catName.toLowerCase().contains(_searchController.text.trim().toLowerCase());
        final matchesCategory = _selectedCategoryId == null || c.subCatCatId == _selectedCategoryId;
        final matchesStatus = _selectedStatus == null || c.subCatIsActive == _selectedStatus;
        return matchesSearch && matchesCategory && matchesStatus;
      }).toList();

      if (_subcategories.isNotEmpty) {
        _highlightedIndex = _highlightedIndex.clamp(0, _subcategories.length - 1);
      } else {
        _highlightedIndex = 0;
      }
    });
    _scrollToIndex(_highlightedIndex);
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedStatus = null;
      _highlightedIndex = 0;
    });
    _fetchSubCategories();
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedCategoryId != null ||
      _selectedStatus != null;

  void _navigateToAddSubCategory([SubCategoryListItem? subcategory]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SubCategoryMasterScreen(subcategoryToEdit: subcategory),
      ),
    );

    if (result == true) {
      _fetchSubCategories();
    }
  }

  Widget _buildCategoryDropdown({bool isFilter = false, String hintText = 'All Categories'}) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int?>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: isFilter ? 'Filter Category' : 'State',
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        prefixIcon: const Icon(Icons.category_rounded, size: 20),
      ),
      items: [
        if (isFilter)
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('All Categories'),
          ),
        ..._categories.map((c) => DropdownMenuItem<int?>(
              value: c.catId,
              child: Text(c.catName),
            )),
      ],
      onChanged: (int? newValue) {
        setState(() {
          _selectedCategoryId = newValue;
        });
        _fetchSubCategories(); // refetch because status might have changed, or just apply filters
      },
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
                        title: const Text('SubCategory Master'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Refresh SubCategories',
                            onPressed: _isLoading ? null : _fetchSubCategories,
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => _navigateToAddSubCategory(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add SubCategory'),
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
              title: const Text('SubCategory Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: _isLoading ? null : _fetchSubCategories,
                ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _navigateToAddSubCategory(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add SubCategory'),
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
                hintText: 'Search by subcategory name...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
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

          // Category Filter Dropdown
          Expanded(
            flex: 3,
            child: _buildCategoryDropdown(isFilter: true),
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
                _fetchSubCategories();
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
              hintText: 'Search subcategory name...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
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
                child: _buildCategoryDropdown(isFilter: true),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<bool?>(
                initialValue: _selectedStatus,
                tooltip: 'Filter Status',
                onSelected: (val) {
                  setState(() {
                    _selectedStatus = val;
                  });
                  _fetchSubCategories();
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
            Text('Loading subcategories from server...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _subcategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load subcategories',
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
                onPressed: _fetchSubCategories,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_subcategories.isEmpty) {
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
                  Icons.category_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _hasActiveFilters ? 'No subcategories match your filter' : 'No subcategories found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try clearing your search query or category filter'
                    : 'Get started by creating your first subcategory master record',
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
                  onPressed: () => _navigateToAddSubCategory(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add First SubCategory'),
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
                'Showing ${_subcategories.length} ${_subcategories.length == 1 ? 'subcategory' : 'subcategories'}',
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
                  const double minTableWidth = 800.0;
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
                                child: Text('SubCategory Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                            itemCount: _subcategories.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                            itemBuilder: (context, index) {
                              final subcategory = _subcategories[index];
                              final isHighlighted = index == _highlightedIndex;

                              return Material(
                                color: isHighlighted
                                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.12)
                                    : Colors.transparent,
                                child: InkWell(
                                  hoverColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                  onTap: () {
                                    setState(() => _highlightedIndex = index);
                                    _navigateToAddSubCategory(subcategory);
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

                                        // SubCategory Name
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
                                                child: Icon(Icons.category_rounded, size: 14, color: theme.colorScheme.primary),
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  subcategory.subCatName,
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Category Name
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            subcategory.catName,
                                            style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Description
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            subcategory.subCatDescription.isEmpty ? '-' : subcategory.subCatDescription,
                                            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Status
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: subcategory.subCatIsActive
                                                      ? Colors.green.withOpacity(0.15)
                                                      : Colors.grey.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: subcategory.subCatIsActive
                                                        ? Colors.green.withOpacity(0.5)
                                                        : Colors.grey.withOpacity(0.5),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: subcategory.subCatIsActive ? Colors.green : Colors.grey,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      subcategory.subCatIsActive ? 'Active' : 'Inactive',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: subcategory.subCatIsActive
                                                            ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Actions
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_rounded, size: 18),
                                                color: theme.colorScheme.primary,
                                                tooltip: 'Edit SubCategory',
                                                splashRadius: 20,
                                                onPressed: () {
                                                  setState(() => _highlightedIndex = index);
                                                  _navigateToAddSubCategory(subcategory);
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

                  // Allow horizontal scrolling if constraints are too narrow
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _subcategories.length,
      itemBuilder: (context, index) {
        final subcategory = _subcategories[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToAddSubCategory(subcategory),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.category_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subcategory.subCatName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.folder_open_rounded, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  subcategory.catName,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: subcategory.subCatIsActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subcategory.subCatIsActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: subcategory.subCatIsActive
                                ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subcategory.subCatDescription.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Description:',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        Text(
                          subcategory.subCatDescription,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
