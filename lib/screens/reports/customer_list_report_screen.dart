import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer_reports.dart';
import '../../models/city.dart';
import '../../models/area.dart';
import '../../models/state_model.dart';
import '../../models/route_model.dart';
import '../../services/customer_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';
import '../../widgets/city_dropdown.dart';
import '../../widgets/area_dropdown.dart';
import '../../widgets/route_dropdown.dart';

class CustomerListReportScreen extends StatefulWidget {
  const CustomerListReportScreen({super.key});

  @override
  State<CustomerListReportScreen> createState() => _CustomerListReportScreenState();
}

class _CustomerListReportScreenState extends State<CustomerListReportScreen> {
  final CustomerService _customerService = customerService;
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _pageNumber = 1;
  static const int _pageSize = 20;
  
  String _searchQuery = '';
  int? _selectedCityId;
  int? _selectedAreaId;
  int? _selectedRouteId;
  
  String? _errorMessage;
  List<CustomerListReportItem> _reportData = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);
    _fetchReport(refresh: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreData();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchReport(refresh: true);
      }
    });
  }

  void _onCityChanged(CityListItem? city) {
    setState(() {
      _selectedCityId = city?.cityId;
      _selectedAreaId = null;
    });
    _fetchReport(refresh: true);
  }

  void _onAreaChanged(AreaListItem? area) {
    setState(() {
      _selectedAreaId = area?.areaId;
    });
    _fetchReport(refresh: true);
  }

  void _onRouteChanged(RouteListItem? route) {
    setState(() {
      _selectedRouteId = route?.routeId;
    });
    _fetchReport(refresh: true);
  }

  Future<void> _fetchMoreData() async {
    if (_isLoading || _isFetchingMore || !_hasMoreData) return;
    
    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _pageNumber + 1;
      final data = await _customerService.getCustomerListReport(
        pageNumber: nextPage,
        pageSize: _pageSize,
        search: _searchQuery,
        cityId: _selectedCityId?.toString(),
        areaId: _selectedAreaId?.toString(),
        routeId: _selectedRouteId,
      );

      if (mounted) {
        setState(() {
          if (data.isEmpty) {
            _hasMoreData = false;
          } else {
            _pageNumber = nextPage;
            _reportData.addAll(data);
            if (data.length < _pageSize) {
              _hasMoreData = false;
            }
          }
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _reportData.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < 0) {
          _highlightedIndex = 0;
        } else {
          _highlightedIndex = (_highlightedIndex + 1) % _reportData.length;
        }
      });
      _scrollToIndex(_highlightedIndex);
      
      if (_highlightedIndex >= _reportData.length - 5) {
        _fetchMoreData();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex <= 0) {
          _highlightedIndex = _reportData.length - 1;
        } else {
          _highlightedIndex = _highlightedIndex - 1;
        }
      });
      _scrollToIndex(_highlightedIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const double rowHeight = 53.0;
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

  Future<void> _fetchReport({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _pageNumber = 1;
        _hasMoreData = true;
        _reportData.clear();
        _highlightedIndex = 0;
      }
    });

    try {
      final data = await _customerService.getCustomerListReport(
        pageNumber: 1,
        pageSize: _pageSize,
        search: _searchQuery,
        cityId: _selectedCityId?.toString(),
        areaId: _selectedAreaId?.toString(),
        routeId: _selectedRouteId,
      );
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
          _hasMoreData = data.length == _pageSize;
          if (_reportData.isNotEmpty) {
            _highlightedIndex = _highlightedIndex.clamp(0, _reportData.length - 1);
          } else {
            _highlightedIndex = 0;
          }
        });
        if (!refresh) {
          _scrollToIndex(_highlightedIndex);
        }
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
                          title: const Text('Customer List Report'),
                          actions: [
                            Container(
                              width: 250,
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search customer...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                              onPressed: _isLoading ? null : () => _fetchReport(refresh: true),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        body: _buildBodyContent(isDesktop: true),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Customer List Report'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : () => _fetchReport(refresh: true),
                  ),
                ],
              ),
              drawer: const AppDrawer(isPermanent: false),
              body: _buildBodyContent(isDesktop: false),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: CityDropdown(
              selectedCityId: _selectedCityId,
              onChanged: _onCityChanged,
              isFilter: true,
            ),
          ),
          SizedBox(
            width: 200,
            child: AreaDropdown(
              selectedAreaId: _selectedAreaId,
              cityId: _selectedCityId,
              onChanged: _onAreaChanged,
              isFilter: true,
            ),
          ),
          SizedBox(
            width: 200,
            child: RouteDropdown(
              selectedRouteId: _selectedRouteId,
              onChanged: _onRouteChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent({required bool isDesktop}) {
    return Column(
      children: [
        _buildFilters(),
        if (_isLoading && _reportData.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null && _reportData.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load report', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => _fetchReport(refresh: true), child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (_reportData.isEmpty)
          const Expanded(child: Center(child: Text('No customers found.')))
        else
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
                  child: Row(
                    children: [
                      Text(
                        'Showing ${_reportData.length} records',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Use ↑ / ↓ to navigate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isDesktop ? _buildDesktopDataTable() : _buildMobileList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopDataTable() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                    border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('City', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Area', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Route', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Cow', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Buffalo', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Bull', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Goat', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _reportData.length + (_isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _reportData.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = _reportData[index];
                      final isSelected = index == _highlightedIndex;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _highlightedIndex = index;
                          });
                        },
                        child: Container(
                          height: 53,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3))),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 50, child: Text('${index + 1}')),
                              Expanded(flex: 3, child: Text(item.custName)),
                              Expanded(flex: 2, child: Text(item.custMobileNo)),
                              Expanded(flex: 2, child: Text(item.custCityName)),
                              Expanded(flex: 2, child: Text(item.custAreaName)),
                              Expanded(flex: 2, child: Text(item.routeName)),
                              Expanded(flex: 1, child: Text(item.custCowCount.toString())),
                              Expanded(flex: 1, child: Text(item.custBuffaloCount.toString())),
                              Expanded(flex: 1, child: Text(item.custBullCount.toString())),
                              Expanded(flex: 1, child: Text(item.custGoatCount.toString())),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _reportData.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _reportData.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _reportData[index];
        final isSelected = index == _highlightedIndex;
        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
          child: ListTile(
            title: Text(item.custName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mobile: ${item.custMobileNo}'),
                Text('City: ${item.custCityName} | Area: ${item.custAreaName}'),
                Text('Cow: ${item.custCowCount} | Buffalo: ${item.custBuffaloCount} | Bull: ${item.custBullCount} | Goat: ${item.custGoatCount}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            onTap: () {
              setState(() {
                _highlightedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
