import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/company.dart';
import '../services/company_service.dart';

/// A reusable Company Dropdown widget that connects to `/api/Company/GetAllCompanies`.
/// Supports search dialog, keyboard navigation, and responsive layouts.
class CompanyDropdown extends StatefulWidget {
  final int? selectedCompId;
  final ValueChanged<CompanyListItem?>? onChanged;
  final String? Function(CompanyListItem?)? validator;
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

  const CompanyDropdown({
    super.key,
    this.selectedCompId,
    this.onChanged,
    this.validator,
    this.labelText = 'Company',
    this.hintText = 'Select Company',
    this.isRequired = false,
    this.isFilter = false,
    this.allOptionLabel = 'All Companies',
    this.enabled = true,
    this.contentPadding,
    this.prefixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.onSelectionComplete,
  });

  @override
  State<CompanyDropdown> createState() => _CompanyDropdownState();
}

class _CompanyDropdownState extends State<CompanyDropdown> {
  final CompanyService _companyService = companyService;
  bool _isLoading = false;
  String? _error;
  CompanyListItem? _selectedCompany;
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<CompanyListItem> _availableCompanies = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _loadCompanies();
  }

  @override
  void didUpdateWidget(covariant CompanyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.selectedCompId != widget.selectedCompId) {
      _syncSelectedCompany();
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

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _companyService.getAllCompanies(isActive: widget.isFilter ? null : true);
      if (mounted) {
        setState(() {
          _availableCompanies = list;
          _isLoading = false;
          _syncSelectedCompany();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
          if (_companyService.companies.isNotEmpty) {
            _availableCompanies = _companyService.companies;
            _syncSelectedCompany();
          }
        });
      }
    }
  }

  void _syncSelectedCompany() {
    if (widget.selectedCompId == null || widget.selectedCompId == 0) {
      _selectedCompany = null;
    } else {
      try {
        _selectedCompany = _availableCompanies.firstWhere(
          (c) => c.compId == widget.selectedCompId,
        );
      } catch (_) {
        _selectedCompany = null;
      }
    }
  }

  void _showSelectionDialog() async {
    if (!widget.enabled || _isLoading) return;

    if (_availableCompanies.isEmpty && !_isLoading) {
      await _loadCompanies();
    }

    if (!mounted) return;

    final selected = await showDialog<CompanyListItem>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CompanySearchDialog(
        companies: _availableCompanies,
        selectedCompany: _selectedCompany,
        isFilter: widget.isFilter,
        allOptionLabel: widget.allOptionLabel ?? 'All Companies',
        title: widget.labelText,
        onRefresh: _loadCompanies,
      ),
    );

    if (!mounted) return;

    if (selected != null || (widget.isFilter && selected == null)) {
      setState(() {
        _selectedCompany = (selected?.compId == -1) ? null : selected;
      });
      widget.onChanged?.call(_selectedCompany);
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

    final displayText = _selectedCompany != null
        ? _selectedCompany!.compName
        : (widget.isFilter ? (widget.allOptionLabel ?? 'All Companies') : widget.hintText);

    final isPlaceholder = _selectedCompany == null && !widget.isFilter;

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
          isEmpty: _selectedCompany == null,
          decoration: InputDecoration(
            labelText: widget.isRequired ? '${widget.labelText} *' : widget.labelText,
            labelStyle: TextStyle(
              color: _isFocused ? theme.colorScheme.primary : null,
              fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
            ),
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon ??
                Icon(
                  Icons.business_rounded,
                  color: _isFocused ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.blue.shade700),
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
                else if (widget.enabled && _selectedCompany != null && widget.isFilter)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear selection',
                    onPressed: () {
                      setState(() {
                        _selectedCompany = null;
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
              fontWeight: _selectedCompany != null ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _CompanySearchDialog extends StatefulWidget {
  final List<CompanyListItem> companies;
  final CompanyListItem? selectedCompany;
  final bool isFilter;
  final String allOptionLabel;
  final String title;
  final Future<void> Function() onRefresh;

  const _CompanySearchDialog({
    required this.companies,
    this.selectedCompany,
    this.isFilter = false,
    required this.allOptionLabel,
    required this.title,
    required this.onRefresh,
  });

  @override
  State<_CompanySearchDialog> createState() => _CompanySearchDialogState();
}

class _CompanySearchDialogState extends State<_CompanySearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<CompanyListItem> _filteredCompanies = [];
  int _highlightedIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _filteredCompanies = List.from(widget.companies);
    if (widget.selectedCompany != null) {
      final idx = _filteredCompanies.indexWhere((c) => c.compId == widget.selectedCompany!.compId);
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
        _filteredCompanies = List.from(widget.companies);
      } else {
        _filteredCompanies = widget.companies.where((c) {
          return c.compName.toLowerCase().contains(cleanQuery) ||
              c.compGSTNo.toLowerCase().contains(cleanQuery) ||
              c.compCity.toLowerCase().contains(cleanQuery) ||
              c.compState.toLowerCase().contains(cleanQuery) ||
              c.compId.toString().contains(cleanQuery);
        }).toList();
      }
      _highlightedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalItems = widget.isFilter ? _filteredCompanies.length + 1 : _filteredCompanies.length;

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
                color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, color: Colors.white, size: 24),
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
                      tooltip: 'Refresh companies',
                      onPressed: () async {
                        setState(() => _isRefreshing = true);
                        await widget.onRefresh();
                        if (mounted) {
                          setState(() {
                            _isRefreshing = false;
                            _filteredCompanies = List.from(widget.companies);
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
                  hintText: 'Search company by name, city, GST...',
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
                            Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No companies found',
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
                          final isSelected = widget.selectedCompany == null;
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
                                CompanyListItem(compId: -1, compName: widget.allOptionLabel),
                              );
                            },
                          );
                        }

                        final compIndex = widget.isFilter ? index - 1 : index;
                        final company = _filteredCompanies[compIndex];
                        final isSelected = widget.selectedCompany?.compId == company.compId;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                                : null,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey.shade800 : Colors.blue.shade100),
                              child: Text(
                                company.compName.isNotEmpty ? company.compName[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.blue.shade800),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              company.compName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                if (company.compCity.isNotEmpty) ...[
                                  Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                  const SizedBox(width: 3),
                                  Text(
                                    company.compCity,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (company.compGSTNo.isNotEmpty) ...[
                                  Text(
                                    'GST: ${company.compGSTNo}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(company);
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
