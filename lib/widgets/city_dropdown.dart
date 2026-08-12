import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/city.dart';
import '../services/city_service.dart';

/// A reusable City Dropdown widget that connects to `/api/City/GetAllCities`.
/// Supports state filtering, search dialog, and keyboard navigation.
class CityDropdown extends StatefulWidget {
  final int? selectedCityId;
  final int? stateId;
  final ValueChanged<CityListItem?>? onChanged;
  final String? Function(CityListItem?)? validator;
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

  const CityDropdown({
    super.key,
    this.selectedCityId,
    this.stateId,
    this.onChanged,
    this.validator,
    this.labelText = 'City',
    this.hintText = 'Select City',
    this.isRequired = false,
    this.isFilter = false,
    this.allOptionLabel = 'All Cities',
    this.enabled = true,
    this.contentPadding,
    this.prefixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.onSelectionComplete,
  });

  @override
  State<CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<CityDropdown> {
  final CityService _cityService = cityService;
  bool _isLoading = false;
  String? _error;
  CityListItem? _selectedCity;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<CityListItem> _availableCities = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadCities();
  }

  @override
  void didUpdateWidget(covariant CityDropdown oldWidget) {
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

    if (oldWidget.stateId != widget.stateId) {
      _loadCities(force: true);
    } else if (oldWidget.selectedCityId != widget.selectedCityId) {
      _syncSelectedCity();
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

  void _syncSelectedCity() {
    if (widget.selectedCityId == null || widget.selectedCityId! <= 0) {
      _selectedCity = null;
    } else {
      _selectedCity = _availableCities.firstWhere(
        (c) => c.cityId == widget.selectedCityId,
        orElse: () => _cityService.cities.firstWhere(
          (c) => c.cityId == widget.selectedCityId,
          orElse: () => CityListItem(
            cityId: widget.selectedCityId!,
            cityName: 'City #${widget.selectedCityId}',
            stateName: '',
          ),
        ),
      );
    }
  }

  Future<void> _loadCities({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cities = await _cityService.getAllCities(
        stateId: widget.stateId,
      );
      if (mounted) {
        _availableCities = cities;
        _syncSelectedCity();
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

  void _openSearchDialog([FormFieldState<CityListItem?>? fieldState]) async {
    if (!widget.enabled || _isLoading) return;

    if (_availableCities.isEmpty) {
      await _loadCities(force: true);
      if (_availableCities.isEmpty) return;
    }

    if (!mounted) return;

    final CityListItem? picked = await showDialog<CityListItem?>(
      context: context,
      builder: (context) => _CitySearchDialog(
        cities: _availableCities,
        selectedCityId: _selectedCity?.cityId,
        isFilter: widget.isFilter,
        allOptionLabel: widget.allOptionLabel ?? 'All Cities',
      ),
    );

    // If dismissed with a result (including allCitiesOption for "All Cities" in filter mode)
    if (picked != null) {
      final CityListItem? effectiveCity =
          (picked.cityId == -1 || picked.cityName == '__ALL_CITIES__') ? null : picked;
      setState(() {
        _selectedCity = effectiveCity;
      });
      fieldState?.didChange(effectiveCity);
      widget.onChanged?.call(effectiveCity);

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

  KeyEventResult _handleTriggerKeyEvent(
    FocusNode node,
    KeyEvent event,
    FormFieldState<CityListItem?>? fieldState,
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
              const Icon(Icons.location_city_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                'Loading cities...',
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

    if (_error != null && _availableCities.isEmpty) {
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
                'Failed to load cities',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: () => _loadCities(force: true),
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

    return FormField<CityListItem?>(
      initialValue: _selectedCity,
      validator: (val) {
        if (widget.validator != null) {
          return widget.validator!(_selectedCity);
        }
        if (widget.isRequired && _selectedCity == null) {
          return 'Please select a city';
        }
        return null;
      },
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        final displayText = _selectedCity != null
            ? (_selectedCity!.stateName.isNotEmpty
                ? '${_selectedCity!.cityName}, ${_selectedCity!.stateName}'
                : _selectedCity!.cityName)
            : (widget.isFilter
                ? (widget.allOptionLabel ?? 'All Cities')
                : widget.hintText);

        final isPlaceholder = _selectedCity == null && !widget.isFilter;

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
                          Icons.location_city_outlined,
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
                                  fontWeight: _selectedCity != null
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
                                  if (_selectedCity != null)
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
                                      fontWeight: _selectedCity != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                      if (widget.isFilter && _selectedCity != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCity = null;
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

/// Search Dialog for selecting a City with fast filtering & keyboard navigation
class _CitySearchDialog extends StatefulWidget {
  static  CityListItem allCitiesOption = CityListItem(
    cityId: -1,
    cityName: '__ALL_CITIES__',
    stateId: 0,
    stateName: '',
    cityIsActive: true,
  );

  final List<CityListItem> cities;
  final int? selectedCityId;
  final bool isFilter;
  final String allOptionLabel;

  const _CitySearchDialog({
    required this.cities,
    this.selectedCityId,
    required this.isFilter,
    required this.allOptionLabel,
  });

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<CityListItem> _filteredCities = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.cities;
    _searchController.addListener(_onSearchChanged);

    // Initial highlighted index
    if (widget.isFilter && widget.selectedCityId == null) {
      _highlightedIndex = 0;
    } else if (widget.selectedCityId != null) {
      final foundIndex =
          widget.cities.indexWhere((c) => c.cityId == widget.selectedCityId);
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
        _filteredCities = widget.cities;
      } else {
        _filteredCities = widget.cities.where((c) {
          final cityNameMatch = c.cityName.toLowerCase().contains(query);
          final stateNameMatch = c.stateName.toLowerCase().contains(query);
          return cityNameMatch || stateNameMatch;
        }).toList();
      }
      _highlightedIndex = 0;
    });
    _scrollToIndex(0);
  }

  int get _totalItemsCount =>
      widget.isFilter ? _filteredCities.length + 1 : _filteredCities.length;

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
        Navigator.of(context).pop(_CitySearchDialog.allCitiesOption); // "All Cities" selected
        return;
      }
      final cityIndex = _highlightedIndex - 1;
      if (cityIndex >= 0 && cityIndex < _filteredCities.length) {
        Navigator.of(context).pop(_filteredCities[cityIndex]);
      }
    } else {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredCities.length) {
        Navigator.of(context).pop(_filteredCities[_highlightedIndex]);
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
            // Header
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
                      Icons.location_city_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isFilter ? 'Filter by City' : 'Select City',
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search city or state name...',
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

            // Keyboard hints badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              child: Row(
                children: [
                  Text(
                    '${_filteredCities.length} ${_filteredCities.length == 1 ? 'city' : 'cities'} found',
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

            // List of Cities
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
                            'No cities match "${_searchController.text}"',
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
                        // "All Cities" entry for filter mode
                        if (widget.isFilter && index == 0) {
                          final isHighlighted = _highlightedIndex == 0;
                          final isSelected = widget.selectedCityId == null;

                          return _buildCityTile(
                            context: context,
                            title: widget.allOptionLabel,
                            subtitle: 'Show records for all cities',
                            isSelected: isSelected,
                            isHighlighted: isHighlighted,
                            onTap: () => Navigator.of(context).pop(_CitySearchDialog.allCitiesOption),
                            leadingIcon: Icons.all_inclusive_rounded,
                          );
                        }

                        final cityIndex = widget.isFilter ? index - 1 : index;
                        final city = _filteredCities[cityIndex];
                        final isHighlighted = _highlightedIndex == index;
                        final isSelected = city.cityId == widget.selectedCityId;

                        return _buildCityTile(
                          context: context,
                          title: city.cityName,
                          subtitle: city.stateName.isNotEmpty ? city.stateName : null,
                          badgeText: city.stateCode,
                          isSelected: isSelected,
                          isHighlighted: isHighlighted,
                          onTap: () => Navigator.of(context).pop(city),
                          leadingIcon: Icons.location_city_rounded,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTile({
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
