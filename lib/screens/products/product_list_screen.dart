import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/subcategory.dart';
import '../../models/brand.dart';
import '../../services/product_service.dart';

import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/subcategory_dropdown.dart';
import '../../widgets/brand_dropdown.dart';
import '../../widgets/direct_back_scope.dart';
import 'product_master_screen.dart';

/// Product List Screen with search, category filter, subcategory filter, brand filter, status filter,
/// keyboard navigation, responsive layout, and Product Details dialog
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = productService;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedSubcategoryId;
  String? _selectedSubcategoryName;
  int? _selectedBrandId;
  String? _selectedBrandName;
  bool? _selectedStatus; // null = All, true = Active, false = Inactive
  bool _isLoading = false;

  String? _errorMessage;
  List<ProductListItem> _allProducts = [];
  List<ProductListItem> _products = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    sessionService.addListener(_onSessionChanged);
    _fetchProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  void _onSessionChanged() {
    if (mounted) {
      _fetchProducts();
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
    if (event is! KeyDownEvent || _products.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _products.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _products.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _products.length) {
        _navigateToEditProduct(_products[_highlightedIndex]);
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

  List<ProductListItem> _applyFilters(List<ProductListItem> source) {
    final search = _searchController.text.trim().toLowerCase();
    final categoryId = _selectedCategoryId;
    final categoryName = _selectedCategoryName?.trim().toLowerCase();
    final subcategoryId = _selectedSubcategoryId;
    final subcategoryName = _selectedSubcategoryName?.trim().toLowerCase();
    final brandId = _selectedBrandId;
    final brandName = _selectedBrandName?.trim().toLowerCase();
    final status = _selectedStatus;

    return source.where((p) {
      // 1. Status Filter
      if (status != null && p.prodIsActive != status) {
        return false;
      }

      // 2. Category Filter
      if (categoryId != null && categoryId > 0 && p.prodCategoryId > 0) {
        if (p.prodCategoryId != categoryId) return false;
      } else if (categoryName != null &&
          categoryName.isNotEmpty &&
          p.prodCategoryName.trim().isNotEmpty) {
        if (p.prodCategoryName.trim().toLowerCase() != categoryName) return false;
      }

      // 3. Subcategory Filter
      if (subcategoryId != null && subcategoryId > 0 && p.prodSubCategoryId > 0) {
        if (p.prodSubCategoryId != subcategoryId) return false;
      } else if (subcategoryName != null &&
          subcategoryName.isNotEmpty &&
          p.prodSubCategoryName.trim().isNotEmpty) {
        if (p.prodSubCategoryName.trim().toLowerCase() != subcategoryName) return false;
      }

      // 4. Brand Filter
      if (brandId != null && brandId > 0 && p.prodBrandId > 0) {
        if (p.prodBrandId != brandId) return false;
      } else if (brandName != null &&
          brandName.isNotEmpty &&
          p.prodBrandName.trim().isNotEmpty) {
        if (p.prodBrandName.trim().toLowerCase() != brandName) return false;
      }

      // 5. Search Text Filter
      if (search.isNotEmpty) {
        final matches =
            p.prodName.toLowerCase().contains(search) ||
            p.prodCode.toLowerCase().contains(search) ||
            p.prodHSNCode.toLowerCase().contains(search) ||
            p.prodCategoryName.toLowerCase().contains(search) ||
            p.prodSubCategoryName.toLowerCase().contains(search) ||
            p.prodBrandName.toLowerCase().contains(search) ||
            'p-${p.prodId}'.contains(search);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _updateFilteredProducts() {
    _products = _applyFilters(_allProducts);
    if (_products.isNotEmpty) {
      _highlightedIndex = _highlightedIndex.clamp(0, _products.length - 1);
    } else {
      _highlightedIndex = 0;
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _updateFilteredProducts();
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchProducts();
    });
  }

  void _onCategoryChanged(CategoryListItem? category) {
    setState(() {
      _selectedCategoryId = category?.catId;
      _selectedCategoryName = category?.catName;
      _selectedSubcategoryId = null;
      _selectedSubcategoryName = null;
      _updateFilteredProducts();
    });
    _fetchProducts();
  }

  void _onSubcategoryChanged(SubCategoryListItem? subcategory) {
    setState(() {
      _selectedSubcategoryId = subcategory?.subCatId;
      _selectedSubcategoryName = subcategory?.subCatName;
      if (subcategory != null &&
          subcategory.subCatCatId != null &&
          subcategory.subCatCatId! > 0 &&
          _selectedCategoryId == null) {
        _selectedCategoryId = subcategory.subCatCatId;
        _selectedCategoryName = subcategory.catName;
      }
      _updateFilteredProducts();
    });
    _fetchProducts();
  }

  void _onBrandChanged(BrandListItem? brand) {
    setState(() {
      _selectedBrandId = brand?.brandId;
      _selectedBrandName = brand?.brandName;
      _updateFilteredProducts();
    });
    _fetchProducts();
  }

  void _onStatusChanged(bool? status) {
    setState(() {
      _selectedStatus = status;
      _updateFilteredProducts();
    });
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getAllProducts(
        search: _searchController.text.trim(),
        isActive: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          if (_productService.products.isNotEmpty) {
            _allProducts = _productService.products;
          } else if (!_hasActiveFilters) {
            _allProducts = products;
          }
          _products = _applyFilters(
            _allProducts.isNotEmpty ? _allProducts : products,
          );
          _isLoading = false;
          if (_products.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(
              0,
              _products.length - 1,
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
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedSubcategoryId = null;
      _selectedSubcategoryName = null;
      _selectedBrandId = null;
      _selectedBrandName = null;
      _selectedStatus = null;
      _highlightedIndex = 0;
      _updateFilteredProducts();
    });
    _fetchProducts();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategoryId != null ||
      (_selectedCategoryName != null && _selectedCategoryName!.isNotEmpty) ||
      _selectedSubcategoryId != null ||
      (_selectedSubcategoryName != null && _selectedSubcategoryName!.isNotEmpty) ||
      _selectedBrandId != null ||
      (_selectedBrandName != null && _selectedBrandName!.isNotEmpty) ||
      _selectedStatus != null;

  void _navigateToEditProduct([ProductListItem? product]) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => ProductMasterScreen(productToEdit: product),
      ),
    );

    if (result == true || (result != null && result is String)) {
      if (result is String) {
        if (!mounted) return;
        await showSuccessDialog(context, result);
      }
      _fetchProducts();
    }
  }

  void _showProductDetailsDialog(ProductListItem product) {
    showDialog(
      context: context,
      builder: (context) => _ProductDetailsDialog(
        product: product,
        onEdit: () {
          Navigator.of(context).pop();
          _navigateToEditProduct(product);
        },
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
                          title: const Text('Product Master'),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh Products',
                              onPressed: _isLoading ? null : _fetchProducts,
                            ),
                            const SizedBox(width: 8),

                            FilledButton.icon(
                              onPressed: () => _navigateToEditProduct(),
                              icon: const Icon(
                                Icons.add_box_rounded,
                                size: 18,
                              ),
                              label: const Text('Add Product'),
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
                title: const Text('Product Master'),
                actions: [

                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : _fetchProducts,
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _navigateToEditProduct(),
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Add Product'),
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
                      hintText: 'Search by Name, Code, HSN...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _updateFilteredProducts();
                                });
                                _fetchProducts();
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

              // Category Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: CategoryDropdown(
                    selectedCategoryId: _selectedCategoryId,
                    isFilter: true,
                    allOptionLabel: 'All Categories',
                    labelText: 'Category Filter',
                    hintText: 'All Categories',
                    onChanged: _onCategoryChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Subcategory Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: SubcategoryDropdown(
                    selectedSubcategoryId: _selectedSubcategoryId,
                    isFilter: true,
                    allOptionLabel: 'All Subcategories',
                    labelText: 'Subcategory Filter',
                    hintText: 'All Subcategories',
                    onChanged: _onSubcategoryChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Brand Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: BrandDropdown(
                    selectedBrandId: _selectedBrandId,
                    isFilter: true,
                    allOptionLabel: 'All Brands',
                    labelText: 'Brand Filter',
                    hintText: 'All Brands',
                    onChanged: _onBrandChanged,
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
                'Showing ${_products.length} ${_products.length == 1 ? 'product' : 'products'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.keyboard_outlined, size: 14, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(
                'Use ↑ / ↓ arrows to navigate, Enter to edit, click row to view details',
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
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _updateFilteredProducts();
                        });
                        _fetchProducts();
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
              Expanded(
                child: CategoryDropdown(
                  selectedCategoryId: _selectedCategoryId,
                  isFilter: true,
                  allOptionLabel: 'All Categories',
                  labelText: 'Category',
                  hintText: 'All Categories',
                  onChanged: _onCategoryChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SubcategoryDropdown(
                  selectedSubcategoryId: _selectedSubcategoryId,
                  isFilter: true,
                  allOptionLabel: 'All Subcategories',
                  labelText: 'Subcategory',
                  hintText: 'All Subcategories',
                  onChanged: _onSubcategoryChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: BrandDropdown(
                  selectedBrandId: _selectedBrandId,
                  isFilter: true,
                  allOptionLabel: 'All Brands',
                  labelText: 'Brand',
                  hintText: 'All Brands',
                  onChanged: _onBrandChanged,
                ),
              ),
              const SizedBox(width: 8),
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
    if (_isLoading && _products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _products.isEmpty) {
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
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
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
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _hasActiveFilters
                    ? 'No products match your filter criteria.'
                    : 'No products added yet.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try clearing filters or search query.'
                    : 'Click "Add Product" to create your first product record.',
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
                  onPressed: () => _navigateToEditProduct(),
                  icon: const Icon(Icons.add_box_rounded),
                  label: const Text('Add New Product'),
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
                _buildHeaderCell('Code', width: 100),
                _buildHeaderCell('Product Name', flex: 3),
                _buildHeaderCell('Category', flex: 2),
                _buildHeaderCell('Subcategory', flex: 2),
                _buildHeaderCell('Brand', flex: 2),
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
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
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
                    _showProductDetailsDialog(product);
                  },
                  onDoubleTap: () => _navigateToEditProduct(product),
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

                        // Code
                        SizedBox(
                          width: 100,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.prodCode.isNotEmpty
                                    ? product.prodCode
                                    : 'P-${product.prodId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Product Name
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.prodName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (product.prodHSNCode.isNotEmpty)
                                Text(
                                  'HSN: ${product.prodHSNCode}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Category
                        Expanded(
                          flex: 2,
                          child: Text(
                            product.prodCategoryName.isNotEmpty
                                ? product.prodCategoryName
                                : '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: product.prodCategoryName.isNotEmpty
                                  ? null
                                  : theme.hintColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Subcategory
                        Expanded(
                          flex: 2,
                          child: Text(
                            product.prodSubCategoryName.isNotEmpty
                                ? product.prodSubCategoryName
                                : '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: product.prodSubCategoryName.isNotEmpty
                                  ? null
                                  : theme.hintColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Brand
                        Expanded(
                          flex: 2,
                          child: Text(
                            product.prodBrandName.isNotEmpty
                                ? product.prodBrandName
                                : '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: product.prodBrandName.isNotEmpty
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
                            child: _buildStatusBadge(product.prodIsActive),
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
                                    _showProductDetailsDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit Product',
                                splashRadius: 18,
                                onPressed: () =>
                                    _navigateToEditProduct(product),
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
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1.5,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showProductDetailsDialog(product),
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
                          Icons.inventory_2_rounded,
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
                              product.prodName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.prodCode.isNotEmpty)
                              Text(
                                product.prodCode,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(product.prodIsActive),
                    ],
                  ),
                  const Divider(height: 20),

                  // Info Rows
                  if (product.prodHSNCode.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.numbers_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HSN: ${product.prodHSNCode}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GST: ${product.prodGSTPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (product.prodCategoryName.isNotEmpty ||
                      product.prodBrandName.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (product.prodCategoryName.isNotEmpty)
                                product.prodCategoryName,
                              if (product.prodBrandName.isNotEmpty)
                                product.prodBrandName,
                            ].join(' • '),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Action Buttons
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        onPressed: () => _showProductDetailsDialog(product),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        onPressed: () => _navigateToEditProduct(product),
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

/// Dialog displaying full product details fetched from `/api/Product/GetProductById/{Prod_Id}`
class _ProductDetailsDialog extends StatefulWidget {
  final ProductListItem product;
  final VoidCallback onEdit;

  const _ProductDetailsDialog({required this.product, required this.onEdit});

  @override
  State<_ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<_ProductDetailsDialog> {
  late ProductListItem _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fetchLiveDetails();
  }

  Future<void> _fetchLiveDetails() async {
    if (_product.prodId <= 0) return;
    try {
      final updatedList = await productService.getAllProducts(prodId: _product.prodId);
      final updated = updatedList.isNotEmpty ? updatedList.first : null;
      if (updated != null && mounted) {
        setState(() {
          _product = updated;
        });
      }
    } catch (_) {
      // Ignore background refresh error, display existing data
    }
  }

  Future<void> _copyToClipboard(String label, String text) async {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    await showSuccessDialog(context, '$label copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _product.prodName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildDialogStatusBadge(_product.prodIsActive),
                          ],
                        ),
                        if (_product.prodCode.isNotEmpty)
                          Text(
                            _product.prodCode,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identification Section
                    _buildSectionHeader(
                      'Identification & Tax',
                      Icons.qr_code_2_rounded,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile(
                            'Product Code',
                            _product.prodCode.isNotEmpty
                                ? _product.prodCode
                                : 'P-${_product.prodId}',
                            onCopy: () =>
                                _copyToClipboard('Product Code', _product.prodCode),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailTile(
                            'HSN Code',
                            _product.prodHSNCode.isNotEmpty
                                ? _product.prodHSNCode
                                : '—',
                            onCopy: _product.prodHSNCode.isNotEmpty
                                ? () => _copyToClipboard('HSN Code', _product.prodHSNCode)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile(
                            'GST Percentage',
                            '${_product.prodGSTPercent.toStringAsFixed(1)}%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Categorization Section
                    _buildSectionHeader(
                      'Categorization',
                      Icons.category_outlined,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile(
                            'Category',
                            _product.prodCategoryName.isNotEmpty
                                ? _product.prodCategoryName
                                : '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailTile(
                            'Subcategory',
                            _product.prodSubCategoryName.isNotEmpty
                                ? _product.prodSubCategoryName
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile(
                            'Brand',
                            _product.prodBrandName.isNotEmpty
                                ? _product.prodBrandName
                                : '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailTile(
                            'Unit',
                            _product.prodUnitName.isNotEmpty
                                ? _product.prodUnitName
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Audit Timestamps
                    if (_product.prodCreatedDate != null ||
                        _product.prodModifiedDate != null) ...[
                      _buildSectionHeader(
                        'Audit Information',
                        Icons.history_rounded,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (_product.prodCreatedDate != null)
                            Expanded(
                              child: _buildDetailTile(
                                'Created Date',
                                _product.prodCreatedDate!.split('T').first,
                              ),
                            ),
                          if (_product.prodModifiedDate != null)
                            Expanded(
                              child: _buildDetailTile(
                                'Modified Date',
                                _product.prodModifiedDate!.split('T').first,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    String label,
    String value, {
    IconData? icon,
    VoidCallback? onCopy,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.hintColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14),
              tooltip: 'Copy $label',
              splashRadius: 14,
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _buildDialogStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
