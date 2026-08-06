import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/state_model.dart';
import '../services/state_service.dart';

/// A reusable State Dropdown widget that connects to `/api/State/GetAllStates`.
/// Can be used across City Master, Customer, Supplier, Branch, Company, etc.
class StateDropdown extends StatefulWidget {
  final int? selectedStateId;
  final ValueChanged<StateModel?>? onChanged;
  final String? Function(StateModel?)? validator;
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

  const StateDropdown({
    super.key,
    this.selectedStateId,
    this.onChanged,
    this.validator,
    this.labelText = 'State',
    this.hintText = 'Select State',
    this.isRequired = false,
    this.isFilter = false,
    this.allOptionLabel = 'All States',
    this.enabled = true,
    this.contentPadding,
    this.prefixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.onSelectionComplete,
  });

  @override
  State<StateDropdown> createState() => _StateDropdownState();
}

class _StateDropdownState extends State<StateDropdown> {
  final StateService _stateService = stateService;
  bool _isLoading = false;
  String? _error;
  StateModel? _selectedState;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadStates();
  }

  @override
  void didUpdateWidget(covariant StateDropdown oldWidget) {
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
    if (oldWidget.selectedStateId != widget.selectedStateId) {
      _syncSelectedState();
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
    }
  }

  void _syncSelectedState() {
    if (widget.selectedStateId == null) {
      _selectedState = null;
    } else {
      _selectedState = _stateService.getStateById(widget.selectedStateId!);
    }
  }

  Future<void> _loadStates({bool force = false}) async {
    if (_stateService.states.isNotEmpty && !force) {
      _syncSelectedState();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _stateService.getAllStates(forceRefresh: force);
      if (mounted) {
        _syncSelectedState();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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

  void _openSearchDialog([FormFieldState<StateModel?>? fieldState]) async {
    if (!widget.enabled || _isLoading) return;

    if (_stateService.states.isEmpty) {
      await _loadStates(force: true);
      if (_stateService.states.isEmpty) return;
    }

    if (!mounted) return;

    final StateModel? picked = await showDialog<StateModel?>(
      context: context,
      builder: (context) => _StateSearchDialog(
        states: _stateService.states,
        selectedStateId: _selectedState?.stateId,
        isFilter: widget.isFilter,
        allOptionLabel: widget.allOptionLabel ?? 'All States',
      ),
    );

    // If dismissed with a result (including null for "All States" in filter mode)
    if (picked != null || (widget.isFilter && picked == null)) {
      setState(() {
        _selectedState = picked;
      });
      fieldState?.didChange(picked);
      widget.onChanged?.call(picked);

      // Automatically transfer focus to next field after dialog closes
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
      // Re-focus the dropdown trigger if dialog was dismissed without picking
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  KeyEventResult _handleTriggerKeyEvent(FocusNode node, KeyEvent event, FormFieldState<StateModel?>? fieldState) {
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
    final effectiveLabel = widget.isRequired ? '${widget.labelText} *' : widget.labelText;

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
              const Icon(Icons.map_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                'Loading states...',
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

    if (_error != null && _stateService.states.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.errorContainer.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load states',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: () => _loadStates(force: true),
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

    return FormField<StateModel?>(
      initialValue: _selectedState,
      validator: (val) {
        if (widget.validator != null) {
          return widget.validator!(_selectedState);
        }
        if (widget.isRequired && _selectedState == null) {
          return 'Please select a state';
        }
        return null;
      },
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        final displayText = _selectedState != null
            ? (_selectedState!.stateCode != null && _selectedState!.stateCode!.isNotEmpty
                ? '${_selectedState!.stateName} (${_selectedState!.stateCode})'
                : _selectedState!.stateName)
            : (widget.isFilter ? (widget.allOptionLabel ?? 'All States') : widget.hintText);

        final isPlaceholder = _selectedState == null && !widget.isFilter;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onKeyEvent: (node, event) => _handleTriggerKeyEvent(node, event, fieldState),
              child: InkWell(
                onTap: widget.enabled ? () => _openSearchDialog(fieldState) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: widget.contentPadding ??
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasError
                          ? theme.colorScheme.error
                          : (_isFocused
                              ? theme.colorScheme.primary
                              : (widget.enabled
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.outlineVariant.withOpacity(0.5))),
                      width: (_isFocused || hasError) ? 2 : 1,
                    ),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.15),
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
                        const SizedBox(width: 10),
                      ] else ...[
                        Icon(
                          Icons.map_outlined,
                          size: 20,
                          color: _isFocused
                              ? theme.colorScheme.primary
                              : (widget.enabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedState != null || widget.isFilter)
                              Text(
                                effectiveLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasError
                                      ? theme.colorScheme.error
                                      : (_isFocused
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant),
                                  fontWeight: _isFocused ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            Text(
                              displayText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isPlaceholder
                                    ? theme.colorScheme.onSurfaceVariant.withOpacity(0.6)
                                    : theme.colorScheme.onSurface,
                                fontWeight: _selectedState != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (widget.isFilter && _selectedState != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          splashRadius: 18,
                          tooltip: 'Clear state filter',
                          onPressed: () {
                            setState(() {
                              _selectedState = null;
                            });
                            fieldState.didChange(null);
                            widget.onChanged?.call(null);
                          },
                        )
                      else ...[
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

/// Search Dialog for selecting a State with fast filtering & keyboard navigation (Up, Down, Enter, Esc)
class _StateSearchDialog extends StatefulWidget {
  final List<StateModel> states;
  final int? selectedStateId;
  final bool isFilter;
  final String allOptionLabel;

  const _StateSearchDialog({
    required this.states,
    this.selectedStateId,
    required this.isFilter,
    required this.allOptionLabel,
  });

  @override
  State<_StateSearchDialog> createState() => _StateSearchDialogState();
}

class _StateSearchDialogState extends State<_StateSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<StateModel> _filteredStates = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredStates = widget.states;
    _searchController.addListener(_onSearchChanged);

    // Determine initial highlighted index based on current selection
    if (widget.isFilter && widget.selectedStateId == null) {
      _highlightedIndex = 0;
    } else if (widget.selectedStateId != null) {
      final foundIndex = widget.states.indexWhere((s) => s.stateId == widget.selectedStateId);
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

  int get _totalItems => _filteredStates.length + (widget.isFilter ? 1 : 0);

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final total = _totalItems;

    if (key == LogicalKeyboardKey.arrowDown) {
      if (total > 0) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1) % total;
        });
        _scrollToIndex(_highlightedIndex);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (total > 0) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1 + total) % total;
        });
        _scrollToIndex(_highlightedIndex);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (total > 0 && _highlightedIndex >= 0 && _highlightedIndex < total) {
        _selectHighlightedItem();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _selectHighlightedItem() {
    if (widget.isFilter && _highlightedIndex == 0) {
      Navigator.of(context).pop(null);
      return;
    }

    final stateIndex = widget.isFilter ? _highlightedIndex - 1 : _highlightedIndex;
    if (stateIndex >= 0 && stateIndex < _filteredStates.length) {
      Navigator.of(context).pop(_filteredStates[stateIndex]);
    }
  }

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

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStates = widget.states;
      } else {
        _filteredStates = widget.states.where((s) {
          final nameMatch = s.stateName.toLowerCase().contains(query);
          final codeMatch = s.stateCode?.toLowerCase().contains(query) ?? false;
          return nameMatch || codeMatch;
        }).toList();
      }
      _highlightedIndex = 0;
    });
    _scrollToIndex(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 520 ? 480.0 : size.width * 0.92;
    final dialogHeight = size.height * 0.68;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Close Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select State',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search state name or code...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.requestFocus();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 12),

            // States List
            Expanded(
              child: _filteredStates.isEmpty && !widget.isFilter
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No states match your search',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: _totalItems,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final isHighlighted = index == _highlightedIndex;

                        // "All States" option for filters
                        if (widget.isFilter && index == 0) {
                          final isSelected = widget.selectedStateId == null;
                          return MouseRegion(
                            onEnter: (_) => setState(() => _highlightedIndex = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.25 : 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isHighlighted
                                    ? Border(
                                        left: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 3.5,
                                        ),
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.public_rounded,
                                  color: isSelected || isHighlighted
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                                ),
                                title: Text(
                                  widget.allOptionLabel,
                                  style: TextStyle(
                                    fontWeight: isSelected || isHighlighted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected || isHighlighted
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isHighlighted)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Text(
                                          '↵ Enter',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          color: theme.colorScheme.primary, size: 20),
                                  ],
                                ),
                                onTap: () => Navigator.of(context).pop(null),
                              ),
                            ),
                          );
                        }

                        final stateIndex = widget.isFilter ? index - 1 : index;
                        final stateItem = _filteredStates[stateIndex];
                        final isSelected = widget.selectedStateId == stateItem.stateId;

                        return MouseRegion(
                          onEnter: (_) => setState(() => _highlightedIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? theme.colorScheme.primary.withOpacity(isDark ? 0.25 : 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isHighlighted
                                  ? Border(
                                      left: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 3.5,
                                      ),
                                    )
                                  : null,
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                stateItem.stateName,
                                style: TextStyle(
                                  fontWeight: isSelected || isHighlighted
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected || isHighlighted
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                              subtitle: stateItem.stateCode != null &&
                                      stateItem.stateCode!.isNotEmpty
                                  ? Text('Code: ${stateItem.stateCode}')
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!stateItem.stateIsActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Text(
                                        'Inactive',
                                        style: TextStyle(
                                            color: Colors.red.shade700, fontSize: 10),
                                      ),
                                    ),
                                  if (isHighlighted)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Text(
                                        '↵ Enter',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded,
                                        color: theme.colorScheme.primary, size: 20),
                                ],
                              ),
                              onTap: () => Navigator.of(context).pop(stateItem),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),

            // Keyboard navigation hint footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_outlined, size: 14, color: theme.hintColor),
                  const SizedBox(width: 6),
                  Text(
                    'Use ↑ / ↓ to navigate • Enter to select • Esc to close',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
