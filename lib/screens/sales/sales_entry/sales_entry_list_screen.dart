import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sales_entry.dart';
import '../../../services/sales_entry_service.dart';
import '../../../widgets/app_drawer.dart';

enum ViewMode { table, grid, list }

class SalesEntryListScreen extends StatefulWidget {
  const SalesEntryListScreen({super.key});

  @override
  State<SalesEntryListScreen> createState() => _SalesEntryListScreenState();
}

class _SalesEntryListScreenState extends State<SalesEntryListScreen> {
  final SalesEntryService _salesEntryService = SalesEntryService();
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  ViewMode? _selectedViewMode;

  @override
  void initState() {
    super.initState();
    _salesEntryService.initializeDummyData();
    _salesEntryService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _salesEntryService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<SalesEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) {
      return _salesEntryService.entries;
    }
    return _salesEntryService.entries.where((e) {
      final query = _searchQuery.toLowerCase();
      return e.invoiceNo.toLowerCase().contains(query) ||
             e.customerName.toLowerCase().contains(query) ||
             e.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1000;
    final bool isMobile = screenWidth < 600;

    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search invoices...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                ToggleButtons(
                  isSelected: [
                    (_selectedViewMode ?? (isDesktop ? ViewMode.table : ViewMode.grid)) == ViewMode.table,
                    (_selectedViewMode ?? (isDesktop ? ViewMode.table : ViewMode.grid)) == ViewMode.grid,
                    (_selectedViewMode ?? (isDesktop ? ViewMode.table : ViewMode.grid)) == ViewMode.list,
                  ],
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) _selectedViewMode = ViewMode.table;
                      else if (index == 1) _selectedViewMode = ViewMode.grid;
                      else _selectedViewMode = ViewMode.list;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                  children: const [
                    Tooltip(message: 'Table View', child: Icon(Icons.table_chart_outlined)),
                    Tooltip(message: 'Grid View', child: Icon(Icons.grid_view)),
                    Tooltip(message: 'List View', child: Icon(Icons.list)),
                  ],
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ]
            ],
          ),
        ),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ToggleButtons(
                      isSelected: [
                        (_selectedViewMode ?? ViewMode.list) == ViewMode.table,
                        (_selectedViewMode ?? ViewMode.list) == ViewMode.grid,
                        (_selectedViewMode ?? ViewMode.list) == ViewMode.list,
                      ],
                      onPressed: (index) {
                        setState(() {
                          if (index == 0) _selectedViewMode = ViewMode.table;
                          else if (index == 1) _selectedViewMode = ViewMode.grid;
                          else _selectedViewMode = ViewMode.list;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
                      children: const [
                        Tooltip(message: 'Table View', child: Icon(Icons.table_chart_outlined)),
                        Tooltip(message: 'Grid View', child: Icon(Icons.grid_view)),
                        Tooltip(message: 'List View', child: Icon(Icons.list)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              final entries = _filteredEntries;
              
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.point_of_sale, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No sales entries found',
                        style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              final currentMode = _selectedViewMode ?? 
                  (isDesktop ? ViewMode.table : (isTablet ? ViewMode.grid : ViewMode.list));

              switch (currentMode) {
                case ViewMode.table:
                  return _buildDataTable(entries);
                case ViewMode.grid:
                  return _buildGridView(entries);
                case ViewMode.list:
                default:
                  return _buildListView(entries);
              }
            },
          ),
        ),
      ],
    );

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
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text('Sales Invoice List'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                body: content,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sales Invoice List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {},
            ),
          ],
        ),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }


  Widget _buildListView(List<SalesEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  entry.invoiceNo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₹${entry.grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(entry.customerName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(_dateFormat.format(entry.invoiceDate), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.status).shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.status,
                        style: TextStyle(
                          color: _getStatusColor(entry.status).shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // Navigate to details
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<SalesEntry> entries) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.invoiceNo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${entry.grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.customerName, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(_dateFormat.format(entry.invoiceDate), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.status).shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.status,
                        style: TextStyle(
                          color: _getStatusColor(entry.status).shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                          tooltip: 'Edit',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  MaterialColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'hold': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildDataTable(List<SalesEntry> entries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth > 32 ? constraints.maxWidth - 32 : 0),
                  child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(label: Text('Invoice No', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: entries.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(Text(entry.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(_dateFormat.format(entry.invoiceDate))),
                    DataCell(Text(entry.customerName)),
                    DataCell(Text(entry.payments.keys.join(', '))),
                    DataCell(Text(entry.grandTotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(entry.status).shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.status,
                          style: TextStyle(
                            color: _getStatusColor(entry.status).shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.print_outlined, size: 20, color: Colors.blueGrey),
                            onPressed: () {},
                            tooltip: 'Print',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () {},
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () {},
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
                  ),
                ),
              ),
            ),
        );
      },
    );
  }
}
