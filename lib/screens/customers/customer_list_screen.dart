import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';
import '../../models/city.dart';
import '../../models/area.dart';
import '../../models/state_model.dart';
import '../../services/customer_service.dart';
import '../../services/customer_excel_export_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/city_dropdown.dart';
import '../../widgets/area_dropdown.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/state_dropdown.dart';
import 'customer_master_screen.dart';

/// Customer List Screen with search, state filter, city filter, status filter,
/// keyboard navigation, responsive layout, and Customer Details dialog
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = customerService;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  int? _selectedStateId;
  String? _selectedStateName;
  int? _selectedCityId;
  String? _selectedCityName;
  int? _selectedAreaId;
  String? _selectedAreaName;
  bool? _selectedStatus; // null = All, true = Active, false = Inactive
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;
  List<CustomerListItem> _allCustomers = [];
  List<CustomerListItem> _customers = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    sessionService.addListener(_onSessionChanged);
    _fetchCustomers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  void _onSessionChanged() {
    if (mounted) {
      _fetchCustomers();
    }
  }

  @override
  void dispose() {
    sessionService.removeListener(_onSessionChanged);
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _screenFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _customers.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _customers.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _customers.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _customers.length) {
        _navigateToEditCustomer(_customers[_highlightedIndex]);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double rowHeight = 58.0;
      final targetOffset = index * rowHeight;
      final currentOffset = _scrollController.offset;
      final viewportHeight = _scrollController.position.viewportDimension;
      final maxOffset = _scrollController.position.maxScrollExtent;

      if (targetOffset < currentOffset) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxOffset),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      } else if (targetOffset + rowHeight > currentOffset + viewportHeight) {
        _scrollController.animateTo(
          (targetOffset + rowHeight - viewportHeight).clamp(0.0, maxOffset),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<CustomerListItem> _applyFilters(List<CustomerListItem> source) {
    final search = _searchController.text.trim().toLowerCase();
    final stateId = _selectedStateId;
    final stateName = _selectedStateName?.trim().toLowerCase();
    final cityId = _selectedCityId;
    final cityName = _selectedCityName?.trim().toLowerCase();
    final areaId = _selectedAreaId;
    final areaName = _selectedAreaName?.trim().toLowerCase();
    final status = _selectedStatus;

    return source.where((c) {
      // 1. Status Filter
      if (status != null && c.custIsActive != status) {
        return false;
      }

      // 2. State Filter
      if (stateId != null && stateId > 0 && c.custStateId > 0) {
        if (c.custStateId != stateId) return false;
      } else if (stateName != null &&
          stateName.isNotEmpty &&
          c.custState.trim().isNotEmpty) {
        if (c.custState.trim().toLowerCase() != stateName) return false;
      }

      // 3. City Filter
      if (cityId != null && cityId > 0 && c.custCityId > 0) {
        if (c.custCityId != cityId) return false;
      } else if (cityName != null &&
          cityName.isNotEmpty &&
          c.custCity.trim().isNotEmpty) {
        if (c.custCity.trim().toLowerCase() != cityName) return false;
      }

      // 4. Area Filter
      if (areaId != null && areaId > 0 && c.custAreaId > 0) {
        if (c.custAreaId != areaId) return false;
      } else if (areaName != null &&
          areaName.isNotEmpty &&
          c.custArea.trim().isNotEmpty) {
        if (c.custArea.trim().toLowerCase() != areaName) return false;
      }

      // 5. Search Text Filter
      if (search.isNotEmpty) {
        final matches =
            c.custName.toLowerCase().contains(search) ||
            c.custMobileNo.toLowerCase().contains(search) ||
            c.custAlternateMobileNo.toLowerCase().contains(search) ||
            c.custCode.toLowerCase().contains(search) ||
            c.custCompanyName.toLowerCase().contains(search) ||
            c.custEmail.toLowerCase().contains(search) ||
            c.custGSTNo.toLowerCase().contains(search) ||
            c.custPANNo.toLowerCase().contains(search) ||
            c.custAddress.toLowerCase().contains(search) ||
            c.custCity.toLowerCase().contains(search) ||
            c.custState.toLowerCase().contains(search) ||
            c.custArea.toLowerCase().contains(search) ||
            c.custPincode.toLowerCase().contains(search) ||
            'c-${c.custId}'.contains(search);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _updateFilteredCustomers() {
    _customers = _applyFilters(_allCustomers);
    if (_customers.isNotEmpty) {
      _highlightedIndex = _highlightedIndex.clamp(0, _customers.length - 1);
    } else {
      _highlightedIndex = 0;
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _updateFilteredCustomers();
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchCustomers();
    });
  }

  void _onStateChanged(StateModel? state) {
    setState(() {
      _selectedStateId = state?.stateId;
      _selectedStateName = state?.stateName;
      _selectedCityId = null;
      _selectedCityName = null;
      _selectedAreaId = null;
      _selectedAreaName = null;
      _updateFilteredCustomers();
    });
    _fetchCustomers();
  }

  void _onCityChanged(CityListItem? city) {
    setState(() {
      _selectedCityId = city?.cityId;
      _selectedCityName = city?.cityName;
      if (city != null &&
          city.stateId != null &&
          city.stateId! > 0 &&
          _selectedStateId == null) {
        _selectedStateId = city.stateId;
        _selectedStateName = city.stateName;
      }
      _selectedAreaId = null;
      _selectedAreaName = null;
      _updateFilteredCustomers();
    });
    _fetchCustomers();
  }

  void _onAreaChanged(AreaListItem? area) {
    setState(() {
      _selectedAreaId = area?.areaId;
      _selectedAreaName = area?.areaName;
      if (area != null) {
        if (area.cityId != null &&
            area.cityId! > 0 &&
            _selectedCityId == null) {
          _selectedCityId = area.cityId;
          _selectedCityName = area.cityName;
        }
        if (area.stateId != null &&
            area.stateId! > 0 &&
            _selectedStateId == null) {
          _selectedStateId = area.stateId;
          _selectedStateName = area.stateName;
        }
      }
      _updateFilteredCustomers();
    });
    _fetchCustomers();
  }

  void _onStatusChanged(bool? status) {
    setState(() {
      _selectedStatus = status;
      _updateFilteredCustomers();
    });
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customers = await _customerService.getAllCustomers(
        search: _searchController.text.trim(),
        stateId: _selectedStateId,
        state: _selectedStateName,
        cityId: _selectedCityId,
        city: _selectedCityName,
        areaId: _selectedAreaId,
        area: _selectedAreaName,
        isActive: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          if (_customerService.customers.isNotEmpty) {
            _allCustomers = _customerService.customers;
          } else if (!_hasActiveFilters) {
            _allCustomers = customers;
          }
          _customers = _applyFilters(
            _allCustomers.isNotEmpty ? _allCustomers : customers,
          );
          _isLoading = false;
          if (_customers.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(
              0,
              _customers.length - 1,
            );
          } else {
            _highlightedIndex = 0;
          }
        });
        _scrollToIndex(_highlightedIndex);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedStateId = null;
      _selectedStateName = null;
      _selectedCityId = null;
      _selectedCityName = null;
      _selectedAreaId = null;
      _selectedAreaName = null;
      _selectedStatus = null;
      _highlightedIndex = 0;
      _updateFilteredCustomers();
    });
    _fetchCustomers();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedStateId != null ||
      (_selectedStateName != null && _selectedStateName!.isNotEmpty) ||
      _selectedCityId != null ||
      (_selectedCityName != null && _selectedCityName!.isNotEmpty) ||
      _selectedAreaId != null ||
      (_selectedAreaName != null && _selectedAreaName!.isNotEmpty) ||
      _selectedStatus != null;

  void _navigateToEditCustomer([CustomerListItem? customer]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CustomerMasterScreen(customerToEdit: customer),
      ),
    );

    if (result == true) {
      _fetchCustomers();
    }
  }

  Future<void> _exportToExcel() async {
    if (_customers.isEmpty) {
      await showWarningDialog(
        context,
        'No customer records available to export.',
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final result = await CustomerExcelExportService.exportCustomers(
        customers: _customers,
      );

      if (!mounted) return;

      if (result.success) {
        final message = _hasActiveFilters
            ? 'Exported ${result.recordCount} filtered customer ${_customers.length == 1 ? 'record' : 'records'} to Excel.'
            : 'Exported all ${result.recordCount} customer ${_customers.length == 1 ? 'record' : 'records'} to Excel.';

        await showSuccessDialog(context, message);
      } else {
        await showErrorDialog(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Failed to export customers: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showCustomerDetailsDialog(CustomerListItem customer) {
    showDialog(
      context: context,
      builder: (context) => _CustomerDetailsDialog(
        customer: customer,
        onEdit: () {
          Navigator.of(context).pop();
          _navigateToEditCustomer(customer);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: DirectBackScope(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;

            if (isDesktop) {
              return Scaffold(
                body: Row(
                  children: [
                    const SizedBox(
                      width: 250,
                      child: AppDrawer(isPermanent: true),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: Scaffold(
                        appBar: AppBar(
                          title: const Text('Customer Master'),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh Customers',
                              onPressed: _isLoading ? null : _fetchCustomers,
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _isExporting || _isLoading
                                  ? null
                                  : _exportToExcel,
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.table_view_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                _isExporting
                                    ? 'Exporting...'
                                    : 'Export to Excel',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _navigateToEditCustomer(),
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 18,
                              ),
                              label: const Text('Add Customer'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                        body: Column(
                          children: [
                            _buildDesktopFilterBar(),
                            Expanded(child: _buildBodyContent(isDesktop: true)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile Layout
            return Scaffold(
              appBar: AppBar(
                title: const Text('Customer Master'),
                actions: [
                  IconButton(
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    tooltip: 'Export to Excel',
                    onPressed: _isExporting || _isLoading
                        ? null
                        : _exportToExcel,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : _fetchCustomers,
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _navigateToEditCustomer(),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add Customer'),
              ),
              body: Column(
                children: [
                  _buildMobileFilterBar(),
                  Expanded(child: _buildBodyContent(isDesktop: false)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Filter Bars ---

  Widget _buildDesktopFilterBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Mobile, Email, GST...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _updateFilteredCustomers();
                                });
                                _fetchCustomers();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                          : Colors.grey.shade50,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // State Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: StateDropdown(
                    selectedStateId: _selectedStateId,
                    isFilter: true,
                    allOptionLabel: 'All States',
                    labelText: 'State Filter',
                    hintText: 'All States',
                    onChanged: _onStateChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // City Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: CityDropdown(
                    selectedCityId: _selectedCityId,
                    stateId: _selectedStateId,
                    isFilter: true,
                    allOptionLabel: 'All Cities',
                    labelText: 'City Filter',
                    hintText: 'All Cities',
                    onChanged: _onCityChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Area Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: AreaDropdown(
                    selectedAreaId: _selectedAreaId,
                    selectedAreaName: _selectedAreaName,
                    cityId: _selectedCityId,
                    stateId: _selectedStateId,
                    isFilter: true,
                    allOptionLabel: 'All Areas',
                    labelText: 'Area Filter',
                    hintText: 'All Areas',
                    onChanged: _onAreaChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Status Filter
              _buildStatusFilterSegment(),
              const SizedBox(width: 12),

              // Clear Filter Button
              if (_hasActiveFilters)
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Showing ${_customers.length} ${_customers.length == 1 ? 'customer' : 'customers'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.keyboard_outlined, size: 14, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(
                'Use ↑ / ↓ arrows to navigate, Enter to edit, click row to view details',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _updateFilteredCustomers();
                        });
                        _fetchCustomers();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StateDropdown(
                  selectedStateId: _selectedStateId,
                  isFilter: true,
                  allOptionLabel: 'All States',
                  labelText: 'State',
                  hintText: 'All States',
                  onChanged: _onStateChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CityDropdown(
                  selectedCityId: _selectedCityId,
                  stateId: _selectedStateId,
                  isFilter: true,
                  allOptionLabel: 'All Cities',
                  labelText: 'City',
                  hintText: 'All Cities',
                  onChanged: _onCityChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AreaDropdown(
                  selectedAreaId: _selectedAreaId,
                  selectedAreaName: _selectedAreaName,
                  cityId: _selectedCityId,
                  stateId: _selectedStateId,
                  isFilter: true,
                  allOptionLabel: 'All Areas',
                  labelText: 'Area',
                  hintText: 'All Areas',
                  onChanged: _onAreaChanged,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<bool?>(
                initialValue: _selectedStatus,
                tooltip: 'Filter Status',
                onSelected: _onStatusChanged,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('All Statuses')),
                  const PopupMenuItem(value: true, child: Text('Active Only')),
                  const PopupMenuItem(
                    value: false,
                    child: Text('Inactive Only'),
                  ),
                ],
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedStatus == null
                            ? Icons.filter_list_rounded
                            : (_selectedStatus!
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedStatus == null
                            ? 'Status'
                            : (_selectedStatus! ? 'Active' : 'Inactive'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  tooltip: 'Reset Filters',
                  onPressed: _clearFilters,
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                tooltip: 'Export (${_customers.length})',
                onPressed: _isExporting || _isLoading ? null : _exportToExcel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterSegment() {
    return SizedBox(
      height: 44,
      child: SegmentedButton<bool?>(
        segments: const [
          ButtonSegment<bool?>(value: null, label: Text('All')),
          ButtonSegment<bool?>(value: true, label: Text('Active')),
          ButtonSegment<bool?>(value: false, label: Text('Inactive')),
        ],
        selected: {_selectedStatus},
        onSelectionChanged: (Set<bool?> newSelection) {
          _onStatusChanged(newSelection.first);
        },
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // --- Main Body Content ---

  Widget _buildBodyContent({required bool isDesktop}) {
    if (_isLoading && _customers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading customers...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchCustomers,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _hasActiveFilters
                    ? 'No customers match your filter criteria.'
                    : 'No customers added yet.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try clearing filters or search query.'
                    : 'Click "Add Customer" to create your first customer record.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (_hasActiveFilters)
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Clear Filters'),
                )
              else
                FilledButton.icon(
                  onPressed: () => _navigateToEditCustomer(),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add New Customer'),
                ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopDataTable();
    } else {
      return _buildMobileListView();
    }
  }

  // --- Desktop Sticky Header Data Table ---

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      child: Column(
        children: [
          // Sticky Table Header
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildHeaderCell('#', width: 50, alignment: Alignment.center),
                _buildHeaderCell('Customer Name', flex: 3),
                _buildHeaderCell('Mobile No', width: 140),
                _buildHeaderCell('City', flex: 2),
                _buildHeaderCell('Area', flex: 2),
             //   _buildHeaderCell('GSTIN', width: 150),
                _buildHeaderCell(
                  'Status',
                  width: 100,
                  alignment: Alignment.center,
                ),
                _buildHeaderCell(
                  'Actions',
                  width: 120,
                  alignment: Alignment.centerRight,
                ),
              ],
            ),
          ),

          // Table Rows
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                final isHighlighted = _highlightedIndex == index;

                Color rowBackground;
                if (isHighlighted) {
                  rowBackground = theme.colorScheme.primaryContainer
                      .withOpacity(isDark ? 0.35 : 0.25);
                } else if (index.isOdd) {
                  rowBackground = isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.white;
                } else {
                  rowBackground = isDark
                      ? Colors.transparent
                      : Colors.grey.shade50.withOpacity(0.5);
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _highlightedIndex = index;
                    });
                    _showCustomerDetailsDialog(customer);
                  },
                  onDoubleTap: () => _navigateToEditCustomer(customer),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: rowBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.06),
                          width: 1,
                        ),
                        left: isHighlighted
                            ? BorderSide(
                                color: theme.colorScheme.primary,
                                width: 4,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Row Index
                        SizedBox(
                          width: 50,
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // Customer Name & Company
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.custName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (customer.custCompanyName.isNotEmpty)
                                Text(
                                  customer.custCompanyName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Mobile Number
                        SizedBox(
                          width: 140,
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                customer.custMobileNo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // City & State
                        Expanded(
                          flex: 2,
                          child: Text(
                            [
                              if (customer.custCity.isNotEmpty)
                                customer.custCity,
                              // if (customer.custState.isNotEmpty)
                              //   customer.custState,
                            ].join(', '),
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Area
                        Expanded(
                          flex: 2,
                          child: Text(
                            customer.custArea.isNotEmpty
                                ? customer.custArea
                                : '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: customer.custArea.isNotEmpty
                                  ? null
                                  : theme.hintColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // GSTIN
                        // SizedBox(
                        //   width: 150,
                        //   child: Text(
                        //     customer.custGSTNo.isNotEmpty
                        //         ? customer.custGSTNo
                        //         : '—',
                        //     style: TextStyle(
                        //       fontFamily: 'monospace',
                        //       fontSize: 12,
                        //       color: customer.custGSTNo.isNotEmpty
                        //           ? null
                        //           : theme.hintColor,
                        //     ),
                        //   ),
                        // ),

                        // Status Badge
                        SizedBox(
                          width: 100,
                          child: Center(
                            child: _buildStatusBadge(customer.custIsActive),
                          ),
                        ),

                        // Actions
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                tooltip: 'View Details',
                                splashRadius: 18,
                                onPressed: () =>
                                    _showCustomerDetailsDialog(customer),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit Customer',
                                splashRadius: 18,
                                onPressed: () =>
                                    _navigateToEditCustomer(customer),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String title, {
    int flex = 1,
    double? width,
    Alignment alignment = Alignment.centerLeft,
  }) {
    final theme = Theme.of(context);

    final child = Align(
      alignment: alignment,
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isActive ? Colors.green : Colors.grey).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Mobile Responsive Card List ---

  Widget _buildMobileListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1.5,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showCustomerDetailsDialog(customer),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar, Name, Status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          customer.custName.isNotEmpty
                              ? customer.custName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.custName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (customer.custCompanyName.isNotEmpty)
                              Text(
                                customer.custCompanyName,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(customer.custIsActive),
                    ],
                  ),
                  const Divider(height: 20),

                  // Info Rows
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_iphone_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        customer.custMobileNo,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (customer.custEmail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            customer.custEmail,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (customer.custCity.isNotEmpty ||
                      customer.custArea.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (customer.custArea.isNotEmpty)
                                customer.custArea,
                              if (customer.custCity.isNotEmpty)
                                customer.custCity,
                              if (customer.custState.isNotEmpty)
                                customer.custState,
                            ].join(', '),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Action Buttons
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        onPressed: () => _showCustomerDetailsDialog(customer),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        onPressed: () => _navigateToEditCustomer(customer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dialog displaying full customer details fetched from `/api/Customer/GetCustomerById/{Cust_Id}`
class _CustomerDetailsDialog extends StatefulWidget {
  final CustomerListItem customer;
  final VoidCallback onEdit;

  const _CustomerDetailsDialog({required this.customer, required this.onEdit});

  @override
  State<_CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<_CustomerDetailsDialog> {
  late CustomerListItem _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _fetchLiveDetails();
  }

  Future<void> _fetchLiveDetails() async {
    if (_customer.custId <= 0) return;
    try {
      final updated = await customerService.getCustomerById(_customer.custId);
      if (updated != null && mounted) {
        setState(() {
          _customer = updated;
        });
      }
    } catch (_) {
      // Ignore background refresh error, display existing data
    }
  }

  Future<void> _copyToClipboard(String label, String text) async {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    await showSuccessDialog(context, '$label copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      _customer.custName.isNotEmpty
                          ? _customer.custName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _customer.custName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildDialogStatusBadge(_customer.custIsActive),
                          ],
                        ),
                        if (_customer.custCompanyName.isNotEmpty)
                          Text(
                            _customer.custCompanyName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code & General Info Section
                    _buildSectionHeader(
                      'Basic & Contact Information',
                      Icons.contact_page_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailTile(
                      'Mobile Number',
                      _customer.custMobileNo,
                      icon: Icons.phone_iphone_rounded,
                      onCopy: () => _copyToClipboard(
                        'Mobile Number',
                        _customer.custMobileNo,
                      ),
                    ),
                    if (_customer.custAlternateMobileNo.isNotEmpty)
                      _buildDetailTile(
                        'Alternate Mobile',
                        _customer.custAlternateMobileNo,
                        icon: Icons.phone_outlined,
                        onCopy: () => _copyToClipboard(
                          'Alternate Mobile',
                          _customer.custAlternateMobileNo,
                        ),
                      ),
                    if (_customer.custEmail.isNotEmpty)
                      _buildDetailTile(
                        'Email Address',
                        _customer.custEmail,
                        icon: Icons.email_outlined,
                        onCopy: () =>
                            _copyToClipboard('Email', _customer.custEmail),
                      ),
                    const SizedBox(height: 16),

                    // Tax & Identification
                    _buildSectionHeader(
                      'Tax & Registration Details',
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile(
                            'GSTIN',
                            _customer.custGSTNo.isNotEmpty
                                ? _customer.custGSTNo
                                : 'Not Provided',
                            onCopy: _customer.custGSTNo.isNotEmpty
                                ? () => _copyToClipboard(
                                    'GSTIN',
                                    _customer.custGSTNo,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailTile(
                            'PAN Number',
                            _customer.custPANNo.isNotEmpty
                                ? _customer.custPANNo
                                : 'Not Provided',
                            onCopy: _customer.custPANNo.isNotEmpty
                                ? () => _copyToClipboard(
                                    'PAN',
                                    _customer.custPANNo,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location & Address
                    _buildSectionHeader(
                      'Address & Location',
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 10),
                    if (_customer.custAddress.isNotEmpty)
                      _buildDetailTile('Address', _customer.custAddress),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile(
                            'Area',
                            _customer.custArea.isNotEmpty
                                ? _customer.custArea
                                : '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailTile(
                            'City',
                            _customer.custCity.isNotEmpty
                                ? _customer.custCity
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailTile(
                            'State',
                            _customer.custState.isNotEmpty
                                ? _customer.custState
                                : '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailTile(
                            'Pincode',
                            _customer.custPincode.isNotEmpty
                                ? _customer.custPincode
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailTile(
                      'Country',
                      _customer.custCountry.isNotEmpty
                          ? _customer.custCountry
                          : 'India',
                    ),
                    const SizedBox(height: 16),

                    // Audit Timestamps
                    if (_customer.custCreatedDate != null ||
                        _customer.custModifiedDate != null) ...[
                      _buildSectionHeader(
                        'Audit Information',
                        Icons.history_rounded,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (_customer.custCreatedDate != null)
                            Expanded(
                              child: _buildDetailTile(
                                'Created Date',
                                _customer.custCreatedDate!.split('T').first,
                              ),
                            ),
                          if (_customer.custModifiedDate != null)
                            Expanded(
                              child: _buildDetailTile(
                                'Modified Date',
                                _customer.custModifiedDate!.split('T').first,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Customer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    String label,
    String value, {
    IconData? icon,
    VoidCallback? onCopy,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.hintColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14),
              tooltip: 'Copy $label',
              splashRadius: 14,
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _buildDialogStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
