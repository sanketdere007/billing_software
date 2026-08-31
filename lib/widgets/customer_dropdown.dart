import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

/// A reusable Customer Dropdown widget
/// Supports search dialog, and keyboard navigation.
class CustomerDropdown extends StatefulWidget {
  final int? selectedCustomerId;
  final ValueChanged<CustomerListItem?>? onChanged;
  final String? Function(CustomerListItem?)? validator;
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

  const CustomerDropdown({
    super.key,
    this.selectedCustomerId,
    this.onChanged,
    this.validator,
    this.labelText = 'Customer',
    this.hintText = 'Select Customer',
    this.isRequired = false,
    this.isFilter = false,
    this.allOptionLabel = 'All Customers',
    this.enabled = true,
    this.contentPadding,
    this.prefixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.onSelectionComplete,
  });

  @override
  State<CustomerDropdown> createState() => _CustomerDropdownState();
}

class _CustomerDropdownState extends State<CustomerDropdown> {
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  String? _error;
  CustomerListItem? _selectedCustomer;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<CustomerListItem> _availableCustomers = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadCustomers();
  }

  @override
  void didUpdateWidget(covariant CustomerDropdown oldWidget) {
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

    if (oldWidget.selectedCustomerId != widget.selectedCustomerId) {
      _syncSelectedCustomer();
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

  void _syncSelectedCustomer() {
    if (widget.selectedCustomerId == null || widget.selectedCustomerId! <= 0) {
      _selectedCustomer = null;
    } else {
      _selectedCustomer = _availableCustomers.firstWhere(
        (c) => c.custId == widget.selectedCustomerId,
        orElse: () => _customerService.customers.firstWhere(
          (c) => c.custId == widget.selectedCustomerId,
          orElse: () => CustomerListItem(
            custId: widget.selectedCustomerId!,
            custCode: '',
            custName: 'Customer #${widget.selectedCustomerId}',
            custCompanyName: '',
            custMobileNo: '',
            custAlternateMobileNo: '',
            custEmail: '',
            custGSTNo: '',
            custPANNo: '',
            custAddress: '',
            custAreaId: 0,
            custCityId: 0,
            custStateId: 0,
            custPincode: '',
            custCountry: '',
            custBranchId: 0,
            custCompId: 0,
            custIsActive: true,
            custCreatedBy: 0,
            custModifiedBy: 0,
          ),
        ),
      );
    }
  }

  Future<void> _loadCustomers({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customers = await _customerService.getAllCustomers();
      if (mounted) {
        _availableCustomers = customers;
        _syncSelectedCustomer();
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

  void _openSearchDialog([FormFieldState<CustomerListItem?>? fieldState]) async {
    if (!widget.enabled || _isLoading) return;

    if (_availableCustomers.isEmpty) {
      await _loadCustomers(force: true);
      if (_availableCustomers.isEmpty) return;
    }

    if (!mounted) return;

    final CustomerListItem? picked = await showDialog<CustomerListItem?>(
      context: context,
      builder: (context) => _CustomerSearchDialog(
        customers: _availableCustomers,
        selectedCustomerId: _selectedCustomer?.custId,
        isFilter: widget.isFilter,
        allOptionLabel: widget.allOptionLabel ?? 'All Customers',
      ),
    );

    if (picked != null) {
      final CustomerListItem? effectiveCustomer =
          (picked.custId == -1 || picked.custName == '__ALL_CUSTOMERS__') ? null : picked;
      setState(() {
        _selectedCustomer = effectiveCustomer;
      });
      fieldState?.didChange(effectiveCustomer);
      widget.onChanged?.call(effectiveCustomer);

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
    FormFieldState<CustomerListItem?>? fieldState,
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
              const Icon(Icons.person_rounded, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                'Loading customers...',
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

    if (_error != null && _availableCustomers.isEmpty) {
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
                'Failed to load customers',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: () => _loadCustomers(force: true),
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

    return FormField<CustomerListItem?>(
      initialValue: _selectedCustomer,
      validator: (val) {
        if (widget.validator != null) {
          return widget.validator!(_selectedCustomer);
        }
        if (widget.isRequired && _selectedCustomer == null) {
          return 'Please select a customer';
        }
        return null;
      },
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        final displayText = _selectedCustomer != null
            ? _selectedCustomer!.custName
            : (widget.isFilter
                ? (widget.allOptionLabel ?? 'All Customers')
                : widget.hintText);

        final isPlaceholder = _selectedCustomer == null && !widget.isFilter;

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
                          Icons.person_rounded,
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
                                  fontWeight: _selectedCustomer != null
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
                                  if (_selectedCustomer != null)
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
                                      fontWeight: _selectedCustomer != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                      if (widget.isFilter && _selectedCustomer != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCustomer = null;
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

class _CustomerSearchDialog extends StatefulWidget {
  static CustomerListItem allCustomersOption = CustomerListItem(
    custId: -1,
    custCode: '',
    custName: '__ALL_CUSTOMERS__',
    custCompanyName: '',
    custMobileNo: '',
    custAlternateMobileNo: '',
    custEmail: '',
    custGSTNo: '',
    custPANNo: '',
    custAddress: '',
    custAreaId: 0,
    custCityId: 0,
    custStateId: 0,
    custPincode: '',
    custCountry: '',
    custBranchId: 0,
    custCompId: 0,
    custIsActive: true,
    custCreatedBy: 0,
    custModifiedBy: 0,
  );

  final List<CustomerListItem> customers;
  final int? selectedCustomerId;
  final bool isFilter;
  final String allOptionLabel;

  const _CustomerSearchDialog({
    required this.customers,
    this.selectedCustomerId,
    required this.isFilter,
    required this.allOptionLabel,
  });

  @override
  State<_CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<_CustomerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<CustomerListItem> _filteredCustomers = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
    _searchController.addListener(_onSearchChanged);

    if (widget.isFilter && widget.selectedCustomerId == null) {
      _highlightedIndex = 0;
    } else if (widget.selectedCustomerId != null) {
      final foundIndex =
          widget.customers.indexWhere((c) => c.custId == widget.selectedCustomerId);
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
        _filteredCustomers = widget.customers;
      } else {
        _filteredCustomers = widget.customers.where((c) {
          return c.custName.toLowerCase().contains(query) ||
                 c.custCompanyName.toLowerCase().contains(query) ||
                 c.custMobileNo.toLowerCase().contains(query) ||
                 c.custCode.toLowerCase().contains(query);
        }).toList();
      }
      _highlightedIndex = 0;
    });
    _scrollToIndex(0);
  }

  int get _totalItemsCount =>
      widget.isFilter ? _filteredCustomers.length + 1 : _filteredCustomers.length;

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
        Navigator.of(context).pop(_CustomerSearchDialog.allCustomersOption);
        return;
      }
      final cIndex = _highlightedIndex - 1;
      if (cIndex >= 0 && cIndex < _filteredCustomers.length) {
        Navigator.of(context).pop(_filteredCustomers[cIndex]);
      }
    } else {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredCustomers.length) {
        Navigator.of(context).pop(_filteredCustomers[_highlightedIndex]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
                      Icons.person_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isFilter ? 'Filter by Customer' : 'Select Customer',
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
                    '${_filteredCustomers.length} ${_filteredCustomers.length == 1 ? 'customer' : 'customers'} found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _totalItemsCount == 0
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No customers found',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search term',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _totalItemsCount,
                      itemBuilder: (context, index) {
                        final isSelected = index == _highlightedIndex;
                        
                        if (widget.isFilter && index == 0) {
                          return _buildListTile(
                            context,
                            item: _CustomerSearchDialog.allCustomersOption,
                            isSelected: isSelected,
                            onTap: () {
                              Navigator.of(context).pop(_CustomerSearchDialog.allCustomersOption);
                            },
                          );
                        }
                        
                        final customerIndex = widget.isFilter ? index - 1 : index;
                        final customer = _filteredCustomers[customerIndex];
                        
                        return _buildListTile(
                          context,
                          item: customer,
                          isSelected: isSelected,
                          onTap: () {
                            Navigator.of(context).pop(customer);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required CustomerListItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isAllOption = item.custId == -1;

    return Container(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
          : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: isAllOption
            ? CircleAvatar(
                backgroundColor: theme.colorScheme.surfaceVariant,
                radius: 18,
                child: Icon(Icons.all_inclusive_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
              )
            : CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                radius: 18,
                child: Text(
                  item.custName.isNotEmpty ? item.custName[0].toUpperCase() : 'C',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: Text(
          isAllOption ? widget.allOptionLabel : item.custName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: isAllOption
            ? null
            : Text(
                item.custCompanyName.isNotEmpty
                    ? '${item.custCompanyName} • ${item.custMobileNo}'
                    : item.custMobileNo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              )
            : const SizedBox(width: 20),
      ),
    );
  }
}
