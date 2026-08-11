import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/brand.dart';
import '../services/brand_service.dart';

class BrandDropdown extends StatefulWidget {
  final int? selectedBrandId;
  final ValueChanged<BrandListItem?>? onChanged;
  final String? Function(BrandListItem?)? validator;
  final String labelText;
  final String hintText;
  final bool isRequired;
  final bool enabled;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const BrandDropdown({
    super.key,
    this.selectedBrandId,
    this.onChanged,
    this.validator,
    this.labelText = 'Brand',
    this.hintText = 'Select Brand',
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<BrandDropdown> createState() => _BrandDropdownState();
}

class _BrandDropdownState extends State<BrandDropdown> {
  final BrandService _service = BrandService();
  bool _isLoading = false;
  String? _error;
  BrandListItem? _selectedItem;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<BrandListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant BrandDropdown oldWidget) {
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
    if (oldWidget.selectedBrandId != widget.selectedBrandId) {
      _syncSelected();
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

  void _syncSelected() {
    if (widget.selectedBrandId == null || widget.selectedBrandId! <= 0) {
      _selectedItem = null;
      return;
    }
    try {
      _selectedItem = _items.firstWhere((e) => e.brandId == widget.selectedBrandId);
    } catch (_) {
      _selectedItem = BrandListItem(
        brandId: widget.selectedBrandId!,
        brandName: 'Brand #${widget.selectedBrandId}',
        brandDescription: '',
        brandCreatedBy: 0,
        brandModifiedBy: 0,
      );
    }
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.getAllBrands(isActive: true);
      if (mounted) {
        _items = items;
        _syncSelected();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSearchDialog([FormFieldState<BrandListItem?>? fieldState]) async {
    if (!widget.enabled || _isLoading) return;
    if (_items.isEmpty) await _loadItems();
    if (!mounted) return;

    final picked = await showDialog<BrandListItem?>(
      context: context,
      builder: (context) => _SearchDialog(items: _items, selectedId: _selectedItem?.brandId),
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, FormFieldState<BrandListItem?>? fieldState) {
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

    if (_isLoading) {
      return Container(
        height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.branding_watermark_outlined, size: 20, color: Colors.grey), const SizedBox(width: 10), Expanded(child: Text('Loading...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))), const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))]),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.error), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(Icons.error, color: theme.colorScheme.error, size: 20), const SizedBox(width: 8), Expanded(child: Text('Failed to load', style: TextStyle(color: theme.colorScheme.error, fontSize: 13))), TextButton(onPressed: _loadItems, child: const Text('Retry'))]),
      );
    }

    return FormField<BrandListItem?>(
      initialValue: _selectedItem,
      validator: (val) {
        if (widget.validator != null) return widget.validator!(_selectedItem);
        if (widget.isRequired && _selectedItem == null) return 'Please select a brand';
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
                      Icon(Icons.branding_watermark_outlined, size: 20, color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectedItem != null) Text(widget.isRequired ? '${widget.labelText} *' : widget.labelText, style: TextStyle(fontSize: 11, color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, fontWeight: _isFocused ? FontWeight.bold : FontWeight.w500)),
                            Text(_selectedItem?.brandName ?? widget.hintText, style: TextStyle(color: _selectedItem == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
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
  final List<BrandListItem> items;
  final int? selectedId;
  const _SearchDialog({required this.items, this.selectedId});
  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  List<BrandListItem> _filtered = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
    if (widget.selectedId != null) {
      final idx = widget.items.indexWhere((e) => e.brandId == widget.selectedId);
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
      _filtered = query.isEmpty ? widget.items : widget.items.where((e) => e.brandName.toLowerCase().contains(query)).toList();
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
            Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchCtrl, focusNode: _searchFocus, decoration: InputDecoration(hintText: 'Search brand...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true))),
            Expanded(
              child: _filtered.isEmpty ? const Center(child: Text('No brands found')) : ListView.builder(
                controller: _scrollCtrl,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  final isSel = item.brandId == widget.selectedId;
                  final isHigh = index == _highlightedIndex;
                  return Container(
                    height: 56,
                    color: isHigh ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                    child: ListTile(
                      title: Text(item.brandName, style: TextStyle(color: isSel || isHigh ? theme.colorScheme.primary : null, fontWeight: isSel || isHigh ? FontWeight.bold : FontWeight.normal)),
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
