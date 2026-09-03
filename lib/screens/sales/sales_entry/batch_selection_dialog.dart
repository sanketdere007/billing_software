import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/batch.dart';
import '../../../services/batch_service.dart';

class BatchSelectionDialog extends StatefulWidget {
  const BatchSelectionDialog({super.key});

  @override
  State<BatchSelectionDialog> createState() => _BatchSelectionDialogState();
}

class _BatchSelectionDialogState extends State<BatchSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<BatchListItem> _filteredBatches = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredBatches = batchService.batches;
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.onKeyEvent = _handleKeyEvent;

    batchService.addListener(_onBatchServiceChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    batchService.removeListener(_onBatchServiceChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onBatchServiceChanged() {
    _onSearchChanged(); // Refresh the list if batches change
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBatches = batchService.batches;
      } else {
        _filteredBatches = batchService.batches.where((b) {
          return b.prodName.toLowerCase().contains(query) ||
                 b.prodCode.toLowerCase().contains(query);
        }).toList();
      }
      _highlightedIndex = 0;
    });
    _scrollToIndex(0);
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final total = _filteredBatches.length;
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

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
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
    if (_filteredBatches.isEmpty) return;
    if (_highlightedIndex >= 0 && _highlightedIndex < _filteredBatches.length) {
      Navigator.of(context).pop(_filteredBatches[_highlightedIndex]);
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
          maxWidth: 600,
          maxHeight: 600,
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
                      Icons.inventory_2_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Product (Batch)',
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
                  hintText: 'Search product name or code...',
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
                    '${_filteredBatches.length} ${_filteredBatches.length == 1 ? 'batch' : 'batches'} found',
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

            // List of Batches
            Flexible(
              child: ListenableBuilder(
                listenable: batchService,
                builder: (context, child) {
                  if (batchService.isLoading && batchService.batches.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (batchService.errorMessage != null && batchService.batches.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          batchService.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    );
                  }

                  if (_filteredBatches.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No products found.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: _filteredBatches.length,
                    itemBuilder: (context, index) {
                      final batch = _filteredBatches[index];
                      final isSelected = index == _highlightedIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(batch),
                            onHover: (hovering) {
                              if (hovering) {
                                setState(() {
                                  _highlightedIndex = index;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                    : Colors.transparent,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.inventory_2,
                                      size: 16,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          batch.prodName,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? theme.colorScheme.onPrimaryContainer
                                                : theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Unit: ${batch.unitName}  |  Stock: ${batch.batchStock}  |  Unit Value: ${batch.formattedUnitValue}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isSelected
                                                ? theme.colorScheme.onPrimaryContainer
                                                    .withOpacity(0.8)
                                                : theme.colorScheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
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
}
