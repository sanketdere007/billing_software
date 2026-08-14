import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';

/// A reusable Supplier Dropdown widget
/// Supports search dialog, and keyboard navigation.
class SupplierDropdown extends StatefulWidget {
  final int? selectedSupplierId;
  final ValueChanged<SupplierListItem?>? onChanged;
  final String? Function(SupplierListItem?)? validator;
  final String labelText;
  final String hintText;
  final bool isRequired;
  final bool isFilter;
  final String? allOptionLabel;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool autofocus;
  final VoidCallback? onSelectionComplete;

  const SupplierDropdown({
    super.key,
    this.selectedSupplierId,
    this.onChanged,
    this.validator,
    this.labelText = 'Supplier',
    this.hintText = 'Select Supplier',
    this.isRequired = false,
    this.isFilter = false,
    this.allOptionLabel = 'All Suppliers',
    this.enabled = true,
    this.contentPadding,
    this.prefixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.onSelectionComplete,
  });

  @override
  State<SupplierDropdown> createState() => _SupplierDropdownState();
}

class _SupplierDropdownState extends State<SupplierDropdown> {
  final SupplierService _supplierService = supplierService;
  bool _isLoading = false;
  String? _error;
  SupplierListItem? _selectedSupplier;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<SupplierListItem> _availableSuppliers = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadSuppliers();
  }

  @override
  void didUpdateWidget(covariant SupplierDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.removeListener(_onFocusChanged);
        _focusNode.dispose();
      } else {
        oldWidget.focusNode?.removeListener(_onFocusChanged);
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }

    if (oldWidget.selectedSupplierId != widget.selectedSupplierId) {
      _syncSelectedSupplier();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_focusNode.hasFocus) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _syncSelectedSupplier() {
    if (widget.selectedSupplierId == null || widget.selectedSupplierId! <= 0) {
      _selectedSupplier = null;
    } else {
      _selectedSupplier = _availableSuppliers.firstWhere(
        (s) => s.suppId == widget.selectedSupplierId,
        orElse: () => _supplierService.suppliers.firstWhere(
          (s) => s.suppId == widget.selectedSupplierId,
          orElse: () => SupplierListItem(
            suppId: widget.selectedSupplierId!,
            suppCode: '',
            suppName: 'Supplier #${widget.selectedSupplierId}',
            suppCompanyName: '',
            suppMobileNo: '',
            suppAlternateMobileNo: '',
            suppEmail: '',
            suppGSTNo: '',
            suppPANNo: '',
            suppAddress: '',
            suppAreaId: 0,
            suppCityId: 0,
            suppStateId: 0,
            suppPincode: '',
            suppCountry: '',
            suppPaymentTerms: '',
            suppCreditLimit: 0,
            suppCreditDays: 0,
            suppIsActive: true,
            suppCreatedBy: 0,
            suppModifiedBy: 0,
            suppCompId: 0,
            suppBranchId: 0,
          ),
        ),
      );
    }
  }

  Future<void> _loadSuppliers({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suppliers = await _supplierService.getAllSuppliers();
      if (mounted) {
        _availableSuppliers = suppliers;
        _syncSelectedSupplier();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('ApiException: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openSearchDialog([FormFieldState<SupplierListItem?>? fieldState]) async {
    if (!widget.enabled || _isLoading) return;

    if (_availableSuppliers.isEmpty) {
      await _loadSuppliers(force: true);
      if (_availableSuppliers.isEmpty) return;
    }

    if (!mounted) return;

    final SupplierListItem? picked = await showDialog<SupplierListItem?>(
      context: context,
      builder: (context) => _SupplierSearchDialog(
        suppliers: _availableSuppliers,
        selectedSupplierId: _selectedSupplier?.suppId,
        isFilter: widget.isFilter,
        allOptionLabel: widget.allOptionLabel ?? 'All Suppliers',
      ),
    );

    if (picked != null) {
      final SupplierListItem? effectiveSupplier =
          (picked.suppId == -1 || picked.suppName == '__ALL_SUPPLIERS__') ? null : picked;
      setState(() {
        _selectedSupplier = effectiveSupplier;
      });
      fieldState?.didChange(effectiveSupplier);
      widget.onChanged?.call(effectiveSupplier);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.nextFocusNode != null) {
          widget.nextFocusNode!.requestFocus();
        } else if (widget.onSelectionComplete != null) {
          widget.onSelectionComplete!();
        } else {
          FocusScope.of(context).nextFocus();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  KeyEventResult _handleTriggerKeyEvent(
    FocusNode node,
    KeyEvent event,
    FormFieldState<SupplierListItem?>? fieldState,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _openSearchDialog(fieldState);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveLabel =
        widget.isRequired ? '${widget.labelText} *' : widget.labelText;

    if (_isLoading) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              widget.prefixIcon!,
              const SizedBox(width: 10),
            ] else ...[
              const Icon(Icons.business_rounded, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                'Loading suppliers...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
    }

    if (_error != null && _availableSuppliers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.errorContainer.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load suppliers',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: () => _loadSuppliers(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    return FormField<SupplierListItem?>(
      initialValue: _selectedSupplier,
      validator: (val) {
        if (widget.validator != null) {
          return widget.validator!(_selectedSupplier);
        }
        if (widget.isRequired && _selectedSupplier == null) {
          return 'Please select a supplier';
        }
        return null;
      },
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        final displayText = _selectedSupplier != null
            ? _selectedSupplier!.suppName
            : (widget.isFilter
                ? (widget.allOptionLabel ?? 'All Suppliers')
                : widget.hintText);

        final isPlaceholder = _selectedSupplier == null && !widget.isFilter;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onKeyEvent: (node, event) =>
                  _handleTriggerKeyEvent(node, event, fieldState),
              child: InkWell(
                onTap: widget.enabled
                    ? () => _openSearchDialog(fieldState)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: BoxConstraints(minHeight: widget.isFilter ? 40 : 52),
                  padding: widget.contentPadding ??
                      EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: widget.isFilter ? 4 : 10,
                      ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasError
                          ? theme.colorScheme.error
                          : (_isFocused
                              ? theme.colorScheme.primary
                              : (widget.enabled
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.outlineVariant
                                      .withOpacity(0.5))),
                      width: (_isFocused || hasError) ? 2 : 1,
                    ),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withOpacity(isDark ? 0.3 : 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 0),
                            ),
                          ]
                        : null,
                    color: widget.enabled
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[
                        widget.prefixIcon!,
                        const SizedBox(width: 8),
                      ] else ...[
                        Icon(
                          Icons.business_rounded,
                          size: 18,
                          color: _isFocused
                              ? theme.colorScheme.primary
                              : (widget.enabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: widget.isFilter
                            ? Text(
                                displayText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isPlaceholder
                                      ? theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.7)
                                      : theme.colorScheme.onSurface,
                                  fontWeight: _selectedSupplier != null
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedSupplier != null)
                                    Text(
                                      effectiveLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: hasError
                                            ? theme.colorScheme.error
                                            : (_isFocused
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme
                                                    .onSurfaceVariant),
                                        fontWeight: _isFocused
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  Text(
                                    displayText,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isPlaceholder
                                          ? theme.colorScheme.onSurfaceVariant
                                              .withOpacity(0.6)
                                      : theme.colorScheme.onSurface,
                                      fontWeight: _selectedSupplier != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                      if (widget.isFilter && _selectedSupplier != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSupplier = null;
                            });
                            fieldState.didChange(null);
                            widget.onChanged?.call(null);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else ...[
                        if (_isFocused)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                          color: _isFocused
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  fieldState.errorText ?? '',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SupplierSearchDialog extends StatefulWidget {
  static SupplierListItem allSuppliersOption = SupplierListItem(
    suppId: -1,
    suppCode: '',
    suppName: '__ALL_SUPPLIERS__',
    suppCompanyName: '',
    suppMobileNo: '',
    suppAlternateMobileNo: '',
    suppEmail: '',
    suppGSTNo: '',
    suppPANNo: '',
    suppAddress: '',
    suppAreaId: 0,
    suppCityId: 0,
    suppStateId: 0,
    suppPincode: '',
    suppCountry: '',
    suppPaymentTerms: '',
    suppCreditLimit: 0,
    suppCreditDays: 0,
    suppIsActive: true,
    suppCreatedBy: 0,
    suppModifiedBy: 0,
    suppCompId: 0,
    suppBranchId: 0,
  );

  final List<SupplierListItem> suppliers;
  final int? selectedSupplierId;
  final bool isFilter;
  final String allOptionLabel;

  const _SupplierSearchDialog({
    required this.suppliers,
    this.selectedSupplierId,
    required this.isFilter,
    required this.allOptionLabel,
  });

  @override
  State<_SupplierSearchDialog> createState() => _SupplierSearchDialogState();
}

class _SupplierSearchDialogState extends State<_SupplierSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<SupplierListItem> _filteredSuppliers = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredSuppliers = widget.suppliers;
    _searchController.addListener(_onSearchChanged);

    if (widget.isFilter && widget.selectedSupplierId == null) {
      _highlightedIndex = 0;
    } else if (widget.selectedSupplierId != null) {
      final foundIndex =
          widget.suppliers.indexWhere((s) => s.suppId == widget.selectedSupplierId);
      if (foundIndex != -1) {
        _highlightedIndex = widget.isFilter ? foundIndex + 1 : foundIndex;
      }
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = widget.suppliers;
      } else {
        _filteredSuppliers = widget.suppliers.where((s) {
          return s.suppName.toLowerCase().contains(query) ||
                 s.suppCompanyName.toLowerCase().contains(query) ||
                 s.suppMobileNo.toLowerCase().contains(query) ||
                 s.suppCode.toLowerCase().contains(query);
        }).toList();
      }
      _highlightedIndex = 0;
    });
    _scrollToIndex(0);
  }

  int get _totalItemsCount =>
      widget.isFilter ? _filteredSuppliers.length + 1 : _filteredSuppliers.length;

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double itemHeight = 56.0;
      final targetOffset = index * itemHeight;
      final currentOffset = _scrollController.offset;
      final viewportHeight = _scrollController.position.viewportDimension;
      final maxOffset = _scrollController.position.maxScrollExtent;

      if (targetOffset < currentOffset) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxOffset),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      } else if (targetOffset + itemHeight > currentOffset + viewportHeight) {
        _scrollController.animateTo(
          (targetOffset + itemHeight - viewportHeight).clamp(0.0, maxOffset),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final total = _totalItemsCount;
    if (total == 0) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1) % total;
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex = (_highlightedIndex - 1 + total) % total;
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _selectHighlighted();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _selectHighlighted() {
    if (_totalItemsCount == 0) return;

    if (widget.isFilter) {
      if (_highlightedIndex == 0) {
        Navigator.of(context).pop(_SupplierSearchDialog.allSuppliersOption);
        return;
      }
      final sIndex = _highlightedIndex - 1;
      if (sIndex >= 0 && sIndex < _filteredSuppliers.length) {
        Navigator.of(context).pop(_filteredSuppliers[sIndex]);
      }
    } else {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredSuppliers.length) {
        Navigator.of(context).pop(_filteredSuppliers[_highlightedIndex]);
      }
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
        constraints: const BoxConstraints(
          maxWidth: 480,
          maxHeight: 560,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isFilter ? 'Filter by Supplier' : 'Select Supplier',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search name, company, or mobile...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              child: Row(
                children: [
                  Text(
                    '${_filteredSuppliers.length} ${_filteredSuppliers.length == 1 ? 'supplier' : 'suppliers'} found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_outlined, size: 12, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '↑/↓ navigate • Enter to select • Esc to close',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: _totalItemsCount == 0
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 44, color: theme.hintColor),
                          const SizedBox(height: 10),
                          Text(
                            'No suppliers match "${_searchController.text}"',
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      itemCount: _totalItemsCount,
                      itemBuilder: (context, index) {
                        if (widget.isFilter && index == 0) {
                          final isHighlighted = _highlightedIndex == 0;
                          final isSelected = widget.selectedSupplierId == null;

                          return _buildSupplierTile(
                            context: context,
                            title: widget.allOptionLabel,
                            subtitle: 'Show records for all suppliers',
                            isSelected: isSelected,
                            isHighlighted: isHighlighted,
                            onTap: () => Navigator.of(context).pop(_SupplierSearchDialog.allSuppliersOption),
                            leadingIcon: Icons.all_inclusive_rounded,
                          );
                        }

                        final sIndex = widget.isFilter ? index - 1 : index;
                        final supplier = _filteredSuppliers[sIndex];
                        final isHighlighted = _highlightedIndex == index;
                        final isSelected = supplier.suppId == widget.selectedSupplierId;

                        return _buildSupplierTile(
                          context: context,
                          title: supplier.suppName,
                          subtitle: supplier.suppCompanyName.isNotEmpty ? supplier.suppCompanyName : null,
                          badgeText: supplier.suppMobileNo,
                          isSelected: isSelected,
                          isHighlighted: isHighlighted,
                          onTap: () => Navigator.of(context).pop(supplier),
                          leadingIcon: Icons.business_rounded,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? badgeText,
    required bool isSelected,
    required bool isHighlighted,
    required VoidCallback onTap,
    required IconData leadingIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primary.withOpacity(isDark ? 0.25 : 0.12)
            : (isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            leadingIcon,
            size: 16,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected || isHighlighted
                ? FontWeight.bold
                : FontWeight.w500,
            color: isSelected || isHighlighted
                ? theme.colorScheme.primary
                : null,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isHighlighted
                      ? theme.colorScheme.primary.withOpacity(0.8)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeText != null && badgeText.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  size: 18, color: theme.colorScheme.primary),
            if (isHighlighted && !isSelected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '↵ Enter',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
