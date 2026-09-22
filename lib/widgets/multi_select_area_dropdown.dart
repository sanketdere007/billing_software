import 'package:flutter/material.dart';
import '../models/area.dart';
import '../services/area_service.dart';

class MultiSelectAreaDropdown extends StatefulWidget {
  final int routeId;
  final List<int> selectedAreaIds;
  final ValueChanged<List<int>> onChanged;
  final String? Function(List<int>?)? validator;

  const MultiSelectAreaDropdown({
    super.key,
    required this.routeId,
    required this.selectedAreaIds,
    required this.onChanged,
    this.validator,
  });

  @override
  State<MultiSelectAreaDropdown> createState() =>
      _MultiSelectAreaDropdownState();
}

class _MultiSelectAreaDropdownState extends State<MultiSelectAreaDropdown> {
  List<int> _currentSelection = [];
  String _displayNames = '';

  @override
  void initState() {
    super.initState();
    _currentSelection = List.from(widget.selectedAreaIds);
  }

  @override
  void didUpdateWidget(covariant MultiSelectAreaDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAreaIds != widget.selectedAreaIds) {
      setState(() {
        _currentSelection = List.from(widget.selectedAreaIds);
      });
    }
  }

  void _showMultiSelectDialog(FormFieldState<List<int>> fieldState) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return _MultiSelectAreaDialog(
          routeId: widget.routeId,
          initialSelection: _currentSelection,
        );
      },
    );

    if (result != null) {
      setState(() {
        _currentSelection = result['selectedIds'] as List<int>;
        _displayNames = result['displayNames'] as String;
      });
      fieldState.didChange(_currentSelection);
      widget.onChanged(_currentSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FormField<List<int>>(
      initialValue: _currentSelection,
      validator: widget.validator,
      builder: (fieldState) {
        final hasError = fieldState.hasError;

        String displayText = 'Select Areas';
        if (_displayNames.isNotEmpty) {
          displayText = _displayNames;
        } else if (_currentSelection.isNotEmpty) {
          displayText = '${_currentSelection.length} area(s) selected';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showMultiSelectDialog(fieldState),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: theme.colorScheme.surface,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_location_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _currentSelection.isEmpty
                              ? theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.6,
                                )
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
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

class _MultiSelectAreaDialog extends StatefulWidget {
  final int routeId;
  final List<int> initialSelection;

  const _MultiSelectAreaDialog({
    required this.routeId,
    required this.initialSelection,
  });

  @override
  State<_MultiSelectAreaDialog> createState() => _MultiSelectAreaDialogState();
}

class _MultiSelectAreaDialogState extends State<_MultiSelectAreaDialog> {
  final AreaService _areaService = areaService;
  late List<int> _selectedIds;
  List<AvailableAreaForRoute> _areas = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelection);
    _searchController.addListener(_onSearchChanged);
    _fetchAreas('');
  }

  Future<void> _fetchAreas(String search) async {
    setState(() => _isLoading = true);
    try {
      final areas = await _areaService.getAvailableForRoute(
        widget.routeId,
        search: search,
      );
      if (mounted) {
        setState(() {
          _areas = areas;
          // If we haven't selected anything locally yet, initialize from API's isSelected
          if (_selectedIds.isEmpty) {
            for (var area in areas) {
              if (area.isSelected && !_selectedIds.contains(area.areaId)) {
                _selectedIds.add(area.areaId);
              }
            }
          } else {
            // ensure we track what is returned as selected if not already in our list?
            // actually the user wants it to show selected if `isSelected` is true.
            // We'll merge them.
            for (var area in areas) {
              if (area.isSelected && !_selectedIds.contains(area.areaId)) {
                _selectedIds.add(area.areaId);
              }
            }
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    // If doing server-side search, we debounce and call _fetchAreas
    // For now, let's just do a simple delay or call directly (might spam API, but let's do it on submit or debounce).
    // The previous implementation was local filtering. We can do local filtering if we fetch all.
    // Let's stick to local filtering if the API returns all.
  }

  // To support local filtering
  List<AvailableAreaForRoute> get _filteredAreas {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _areas;
    return _areas
        .where((a) => a.areaName.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Areas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search Area',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredAreas.length,
                      itemBuilder: (context, index) {
                        final area = _filteredAreas[index];
                        final isSelected = _selectedIds.contains(area.areaId);
                        return CheckboxListTile(
                          title: Text(area.areaName),
                          value: isSelected,
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedIds.add(area.areaId);
                              } else {
                                _selectedIds.remove(area.areaId);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      // Build display names
                      final selectedNames = _areas
                          .where((a) => _selectedIds.contains(a.areaId))
                          .map((a) => a.areaName)
                          .toList();
                      final displayNames = selectedNames.isNotEmpty
                          ? selectedNames.join(', ')
                          : '${_selectedIds.length} area(s) selected';

                      Navigator.of(context).pop({
                        'selectedIds': _selectedIds,
                        'displayNames': displayNames,
                      });
                    },
                    child: const Text('Confirm'),
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
