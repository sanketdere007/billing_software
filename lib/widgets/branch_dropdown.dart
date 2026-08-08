import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

/// A reusable Branch Dropdown widget that connects to `/api/Branch/GetAllBranches`.
/// Supports Company ID filtering, search dialog, and keyboard navigation.
class BranchDropdown extends StatefulWidget {
  final int? selectedBranchId;
  final int? compId;
  final ValueChanged<BranchListItem?>? onChanged;
  final String? Function(BranchListItem?)? validator;
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

  const BranchDropdown({
    super.key,
    this.selectedBranchId,
    this.compId,
    this.onChanged,
    this.validator,
    this.labelText = 'Branch',
    this.hintText = 'Select Branch',
    this.isRequired = false,
    this.isFilter = false,
    this.allOptionLabel = 'All Branches',
    this.enabled = true,
    this.contentPadding,
    this.prefixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.onSelectionComplete,
  });

  @override
  State<BranchDropdown> createState() => _BranchDropdownState();
}

class _BranchDropdownState extends State<BranchDropdown> {
  final BranchService _branchService = branchService;
  bool _isLoading = false;
  String? _error;
  BranchListItem? _selectedBranch;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<BranchListItem> _availableBranches = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadBranches();
  }

  @override
  void didUpdateWidget(covariant BranchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.compId != widget.compId) {
      _loadBranches();
    } else if (oldWidget.selectedBranchId != widget.selectedBranchId) {
      _syncSelectedBranch();
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
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _branchService.getAllBranches(
        compId: widget.compId,
        isActive: widget.isFilter ? null : true,
      );
      if (mounted) {
        setState(() {
          _availableBranches = list;
          _isLoading = false;
          _syncSelectedBranch();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
          if (_branchService.branches.isNotEmpty) {
            _availableBranches = widget.compId != null && widget.compId! > 0
                ? _branchService.getBranchesByCompId(widget.compId!)
                : _branchService.branches;
            _syncSelectedBranch();
          }
        });
      }
    }
  }

  void _syncSelectedBranch() {
    if (widget.selectedBranchId == null || widget.selectedBranchId == 0) {
      _selectedBranch = null;
    } else {
      try {
        _selectedBranch = _availableBranches.firstWhere(
          (b) => b.branchId == widget.selectedBranchId,
        );
      } catch (_) {
        _selectedBranch = null;
      }
    }
  }

  void _showSelectionDialog() async {
    if (!widget.enabled || _isLoading) return;

    if (_availableBranches.isEmpty && !_isLoading) {
      await _loadBranches();
    }

    if (!mounted) return;

    final selected = await showDialog<BranchListItem>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _BranchSearchDialog(
        branches: _availableBranches,
        selectedBranch: _selectedBranch,
        isFilter: widget.isFilter,
        allOptionLabel: widget.allOptionLabel ?? 'All Branches',
        title: widget.labelText,
        onRefresh: _loadBranches,
      ),
    );

    if (!mounted) return;

    if (selected != null || (widget.isFilter && selected == null)) {
      setState(() {
        _selectedBranch = (selected?.branchId == -1) ? null : selected;
      });
      widget.onChanged?.call(_selectedBranch);
      widget.onSelectionComplete?.call();

      if (widget.nextFocusNode != null) {
        widget.nextFocusNode!.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBorderColor = _error != null
        ? theme.colorScheme.error
        : (_isFocused ? theme.colorScheme.primary : (isDark ? Colors.white24 : Colors.grey.shade400));

    final displayText = _selectedBranch != null
        ? _selectedBranch!.branchName
        : (widget.isFilter ? (widget.allOptionLabel ?? 'All Branches') : widget.hintText);

    final isPlaceholder = _selectedBranch == null && !widget.isFilter;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _showSelectionDialog();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.enabled ? _showSelectionDialog : null,
        child: InputDecorator(
          isFocused: _isFocused,
          isEmpty: _selectedBranch == null,
          decoration: InputDecoration(
            labelText: widget.isRequired ? '${widget.labelText} *' : widget.labelText,
            labelStyle: TextStyle(
              color: _isFocused ? theme.colorScheme.primary : null,
              fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
            ),
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon ??
                Icon(
                  Icons.storefront_rounded,
                  color: _isFocused ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.teal.shade700),
                ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (widget.enabled && _selectedBranch != null && widget.isFilter)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear selection',
                    onPressed: () {
                      setState(() {
                        _selectedBranch = null;
                      });
                      widget.onChanged?.call(null);
                    },
                  )
                else
                  const Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            filled: !widget.enabled,
            fillColor: !widget.enabled ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100) : null,
            errorText: _error,
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 14,
              color: isPlaceholder
                  ? theme.hintColor
                  : (widget.enabled ? theme.textTheme.bodyMedium?.color : theme.disabledColor),
              fontWeight: _selectedBranch != null ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _BranchSearchDialog extends StatefulWidget {
  final List<BranchListItem> branches;
  final BranchListItem? selectedBranch;
  final bool isFilter;
  final String allOptionLabel;
  final String title;
  final Future<void> Function() onRefresh;

  const _BranchSearchDialog({
    required this.branches,
    this.selectedBranch,
    this.isFilter = false,
    required this.allOptionLabel,
    required this.title,
    required this.onRefresh,
  });

  @override
  State<_BranchSearchDialog> createState() => _BranchSearchDialogState();
}

class _BranchSearchDialogState extends State<_BranchSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<BranchListItem> _filteredBranches = [];
  int _highlightedIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _filteredBranches = List.from(widget.branches);
    if (widget.selectedBranch != null) {
      final idx = _filteredBranches.indexWhere((b) => b.branchId == widget.selectedBranch!.branchId);
      if (idx != -1) {
        _highlightedIndex = widget.isFilter ? idx + 1 : idx;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final cleanQuery = query.trim().toLowerCase();
    setState(() {
      if (cleanQuery.isEmpty) {
        _filteredBranches = List.from(widget.branches);
      } else {
        _filteredBranches = widget.branches.where((b) {
          return b.branchName.toLowerCase().contains(cleanQuery) ||
              b.branchCity.toLowerCase().contains(cleanQuery) ||
              b.branchArea.toLowerCase().contains(cleanQuery) ||
              b.branchGSTNo.toLowerCase().contains(cleanQuery) ||
              b.branchContactPerson.toLowerCase().contains(cleanQuery) ||
              b.branchId.toString().contains(cleanQuery);
        }).toList();
      }
      _highlightedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalItems = widget.isFilter ? _filteredBranches.length + 1 : _filteredBranches.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.teal.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select ${widget.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isRefreshing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                      tooltip: 'Refresh branches',
                      onPressed: () async {
                        setState(() => _isRefreshing = true);
                        await widget.onRefresh();
                        if (mounted) {
                          setState(() {
                            _isRefreshing = false;
                            _filteredBranches = List.from(widget.branches);
                          });
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search branch by name, city, contact...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // List
            Expanded(
              child: totalItems == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No branches found',
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: totalItems,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemBuilder: (context, index) {
                        if (widget.isFilter && index == 0) {
                          final isSelected = widget.selectedBranch == null;
                          return ListTile(
                            leading: Icon(
                              Icons.all_inclusive,
                              color: isSelected ? theme.colorScheme.primary : Colors.grey,
                            ),
                            title: Text(
                              widget.allOptionLabel,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            selected: isSelected,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onTap: () {
                              Navigator.of(context).pop(
                                BranchListItem(branchId: -1, branchCompId: 0, branchName: widget.allOptionLabel),
                              );
                            },
                          );
                        }

                        final branchIndex = widget.isFilter ? index - 1 : index;
                        final branch = _filteredBranches[branchIndex];
                        final isSelected = widget.selectedBranch?.branchId == branch.branchId;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.shade50)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: Colors.teal, width: 1.5)
                                : null,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.teal
                                  : (isDark ? Colors.grey.shade800 : Colors.teal.shade100),
                              child: Text(
                                branch.branchName.isNotEmpty ? branch.branchName[0].toUpperCase() : 'B',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.teal.shade800),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              branch.branchName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.teal.shade700 : null,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                if (branch.branchCity.isNotEmpty) ...[
                                  Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                  const SizedBox(width: 3),
                                  Text(
                                    branch.branchCity,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (branch.branchContactPerson.isNotEmpty) ...[
                                  Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      branch.branchContactPerson,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.teal, size: 20)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(branch);
                            },
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
