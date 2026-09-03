import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/unit.dart';
import '../services/unit_service.dart';

class UnitDropdown extends StatefulWidget {
  final int? selectedUnitId;
  final String? selectedUnitName;
  final ValueChanged<UnitListItem?>? onChanged;
  final String? Function(UnitListItem?)? validator;
  final String labelText;
  final String hintText;
  final bool isRequired;
  final bool enabled;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const UnitDropdown({
    super.key,
    this.selectedUnitId,
    this.selectedUnitName,
    this.onChanged,
    this.validator,
    this.labelText = 'Unit',
    this.hintText = 'Select Unit',
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<UnitDropdown> createState() => _UnitDropdownState();
}

class _UnitDropdownState extends State<UnitDropdown> {
  final UnitService _service = UnitService();
  bool _isLoading = false;
  String? _error;
  UnitListItem? _selectedItem;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<UnitListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _syncSelected();
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant UnitDropdown oldWidget) {
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
    if (oldWidget.selectedUnitId != widget.selectedUnitId ||
        oldWidget.selectedUnitName != widget.selectedUnitName) {
      _syncSelected();
      if (mounted) setState(() {});
      _notifyResolvedSelection();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  UnitListItem? _matchByName(String name) {
    final query = name.trim().toLowerCase();
    if (query.isEmpty) return null;
    for (final item in _items) {
      if (item.unitName.trim().toLowerCase() == query ||
          item.unitShortName.trim().toLowerCase() == query) {
        return item;
      }
    }
    return null;
  }

  void _syncSelected() {
    final selectedId = widget.selectedUnitId;
    if (selectedId != null && selectedId > 0) {
      try {
        _selectedItem = _items.firstWhere((e) => e.unitId == selectedId);
        return;
      } catch (_) {
        final byName = widget.selectedUnitName != null
            ? _matchByName(widget.selectedUnitName!)
            : null;
        _selectedItem = byName ??
            UnitListItem(
              unitId: selectedId,
              unitName: (widget.selectedUnitName != null &&
                      widget.selectedUnitName!.trim().isNotEmpty)
                  ? widget.selectedUnitName!.trim()
                  : 'Unit #$selectedId',
              unitShortName: '',
              unitCreatedBy: 0,
              unitModifiedBy: 0,
            );
        return;
      }
    }

    final name = widget.selectedUnitName;
    if (name != null && name.trim().isNotEmpty) {
      final matched = _matchByName(name);
      if (matched != null) {
        _selectedItem = matched;
        return;
      }
      _selectedItem = UnitListItem(
        unitId: 0,
        unitName: name.trim(),
        unitShortName: '',
        unitCreatedBy: 0,
        unitModifiedBy: 0,
      );
      return;
    }

    _selectedItem = null;
  }

  void _notifyResolvedSelection() {
    final selected = _selectedItem;
    if (selected == null || selected.unitId <= 0) return;
    if (widget.selectedUnitId == selected.unitId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.selectedUnitId == selected.unitId) return;
      widget.onChanged?.call(selected);
    });
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.getAllUnits(isActive: true);
      if (mounted) {
        _items = items;
        _syncSelected();
        _notifyResolvedSelection();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSearchDialog([FormFieldState<UnitListItem?>? fieldState]) async {
    if (!widget.enabled) return;
    if (_isLoading && _items.isEmpty) return;
    if (_items.isEmpty) await _loadItems();
    if (!mounted) return;

    final picked = await showDialog<UnitListItem?>(
      context: context,
      builder: (context) => _SearchDialog(items: _items, selectedId: _selectedItem?.unitId),
    );

    if (picked != null) {
      setState(() => _selectedItem = picked);
      fieldState?.didChange(picked);
      widget.onChanged?.call(picked);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.nextFocusNode != null) {
          widget.nextFocusNode!.requestFocus();
        } else {
          FocusScope.of(context).nextFocus();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, FormFieldState<UnitListItem?>? fieldState) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _openSearchDialog(fieldState);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _selectedItem == null) {
      return Container(
        height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.scale_outlined, size: 20, color: Colors.grey), const SizedBox(width: 10), Expanded(child: Text('Loading...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))), const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))]),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.error), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(Icons.error, color: theme.colorScheme.error, size: 20), const SizedBox(width: 8), Expanded(child: Text('Failed to load', style: TextStyle(color: theme.colorScheme.error, fontSize: 13))), TextButton(onPressed: _loadItems, child: const Text('Retry'))]),
      );
    }

    return FormField<UnitListItem?>(
      key: ValueKey(
        'unit-${widget.selectedUnitId ?? 0}-${widget.selectedUnitName ?? ''}-${_selectedItem?.unitId ?? 0}',
      ),
      initialValue: _selectedItem,
      validator: (val) {
        if (widget.validator != null) return widget.validator!(_selectedItem);
        if (widget.isRequired && _selectedItem == null) return 'Please select a unit';
        return null;
      },
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: _focusNode,
              onKeyEvent: (node, event) => _handleKeyEvent(node, event, fieldState),
              child: InkWell(
                onTap: widget.enabled ? () => _openSearchDialog(fieldState) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 52, padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hasError ? theme.colorScheme.error : (_isFocused ? theme.colorScheme.primary : theme.colorScheme.outline), width: (_isFocused || hasError) ? 2 : 1),
                    color: widget.enabled ? theme.colorScheme.surface : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.scale_outlined, size: 20, color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectedItem != null) Text(widget.isRequired ? '${widget.labelText} *' : widget.labelText, style: TextStyle(fontSize: 11, color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, fontWeight: _isFocused ? FontWeight.bold : FontWeight.w500)),
                            Text(_selectedItem?.unitName ?? widget.hintText, style: TextStyle(color: _selectedItem == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (_isFocused) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(4)), child: Text('↵ Enter', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer))),
                      Icon(Icons.arrow_drop_down_rounded, color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError) Padding(padding: const EdgeInsets.only(left: 12, top: 4), child: Text(fieldState.errorText ?? '', style: TextStyle(color: theme.colorScheme.error, fontSize: 12))),
          ],
        );
      },
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final List<UnitListItem> items;
  final int? selectedId;
  const _SearchDialog({required this.items, this.selectedId});
  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  List<UnitListItem> _filtered = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
    if (widget.selectedId != null) {
      final idx = widget.items.indexWhere((e) => e.unitId == widget.selectedId);
      if (idx != -1) _highlightedIndex = idx;
    }
    _searchFocus.onKeyEvent = _handleKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { _searchFocus.requestFocus(); _scrollToIndex(_highlightedIndex); }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _searchFocus.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty ? widget.items : widget.items.where((e) => e.unitName.toLowerCase().contains(query)).toList();
      _highlightedIndex = 0;
    });
    _scrollToIndex(0);
  }

  void _scrollToIndex(int index) {
    if (!_scrollCtrl.hasClients) return;
    final target = index * 56.0;
    final current = _scrollCtrl.offset;
    final viewport = _scrollCtrl.position.viewportDimension;
    if (target < current) {
      _scrollCtrl.jumpTo(target);
    } else if (target + 56.0 > current + viewport) {
      _scrollCtrl.jumpTo(target + 56.0 - viewport);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_filtered.isNotEmpty) setState(() => _highlightedIndex = (_highlightedIndex + 1) % _filtered.length);
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (_filtered.isNotEmpty) setState(() => _highlightedIndex = (_highlightedIndex - 1 + _filtered.length) % _filtered.length);
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_filtered.isNotEmpty) Navigator.of(context).pop(_filtered[_highlightedIndex]);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchCtrl, focusNode: _searchFocus, decoration: InputDecoration(hintText: 'Search unit...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true))),
            Expanded(
              child: _filtered.isEmpty ? const Center(child: Text('No units found')) : ListView.builder(
                controller: _scrollCtrl,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  final isSel = item.unitId == widget.selectedId;
                  final isHigh = index == _highlightedIndex;
                  return Container(
                    height: 56,
                    color: isHigh ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                    child: ListTile(
                      title: Text(item.unitName, style: TextStyle(color: isSel || isHigh ? theme.colorScheme.primary : null, fontWeight: isSel || isHigh ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSel ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                      onTap: () => Navigator.of(context).pop(item),
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
