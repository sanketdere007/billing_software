import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';
import 'product_master_screen.dart';

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

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
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
    final status = _selectedStatus;

    return source.where((p) {
      // 1. Status Filter
      if (status != null && p.prodIsActive != status) {
        return false;
      }

      // 2. Search Text Filter
      if (search.isNotEmpty) {
        final matches =
            p.prodName.toLowerCase().contains(search) ||
            p.prodCode.toLowerCase().contains(search) ||
            p.prodHSNCode.toLowerCase().contains(search) ||
            p.prodCompanyName.toLowerCase().contains(search) ||
            p.prodBranchName.toLowerCase().contains(search);
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
          _products = _applyFilters(_allProducts.isNotEmpty ? _allProducts : products);
          _isLoading = false;
          if (_products.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(0, _products.length - 1);
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
      _updateFilteredProducts();
    });
    _fetchProducts();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty || _selectedStatus != null;

  void _navigateToEditProduct([ProductListItem? product]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProductMasterScreen(productToEdit: product),
      ),
    );

    if (result == true) {
      _fetchProducts();
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
                              icon: const Icon(Icons.add_box_rounded, size: 18),
                              label: const Text('Add Product'),
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
              Expanded(
                flex: 4,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : Colors.grey.shade50,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusFilterSegment(),
              const SizedBox(width: 12),
              if (_hasActiveFilters)
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                'Use ↑ / ↓ arrows to navigate, Enter to edit',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: _clearFilters,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : Colors.grey.shade50,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatusFilterSegment()),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                  tooltip: 'Clear Filters',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.5),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterSegment() {
    return SegmentedButton<bool?>(
      segments: const [
        ButtonSegment<bool?>(value: null, label: Text('All')),
        ButtonSegment<bool?>(value: true, label: Text('Active')),
        ButtonSegment<bool?>(value: false, label: Text('Inactive')),
      ],
      selected: {_selectedStatus},
      onSelectionChanged: (Set<bool?> newSelection) {
        _onStatusChanged(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13)),
      ),
    );
  }

  // --- Body Content ---
  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
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
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters ? 'No products match your filters' : 'No products found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Filters'),
              ),
            ]
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final isHighlighted = index == _highlightedIndex;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Card(
          elevation: isHighlighted ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isHighlighted
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _highlightedIndex = index;
              });
              _navigateToEditProduct(product);
            },
            onHover: (hovering) {
              if (hovering) {
                setState(() {
                  _highlightedIndex = index;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar / Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: product.prodIsActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: product.prodIsActive
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.hintColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.prodName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (product.prodCode.isNotEmpty)
                              _buildInfoChip(context, Icons.qr_code_2_rounded, product.prodCode),
                            if (product.prodHSNCode.isNotEmpty)
                              _buildInfoChip(context, Icons.numbers_rounded, 'HSN: ${product.prodHSNCode}'),
                            _buildInfoChip(
                              context,
                              Icons.percent_rounded,
                              'GST: ${product.prodGSTPercent.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions & Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.prodIsActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: product.prodIsActive
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          product.prodIsActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: product.prodIsActive ? Colors.green.shade700 : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.hintColor,
                        size: 20,
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

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.hintColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
