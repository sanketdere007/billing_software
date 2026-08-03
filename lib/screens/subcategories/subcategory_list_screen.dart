import 'package:flutter/material.dart';
import '../../models/subcategory.dart';
import '../../models/category.dart';
import '../../services/subcategory_service.dart';
import '../../services/category_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_subcategory_screen.dart';

class SubcategoryListScreen extends StatefulWidget {
  const SubcategoryListScreen({super.key});

  @override
  State<SubcategoryListScreen> createState() => _SubcategoryListScreenState();
}

class _SubcategoryListScreenState extends State<SubcategoryListScreen> {
  final SubcategoryService _subcategoryService = SubcategoryService();
  final CategoryService _categoryService = CategoryService();
  
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool? _selectedStatus; // null = All, true = Active, false = Inactive

  @override
  void initState() {
    super.initState();
    _subcategoryService.initializeDummyData();
    _categoryService.initializeDummyData();
    _subcategoryService.addListener(_onDataChanged);
    _categoryService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _subcategoryService.removeListener(_onDataChanged);
    _categoryService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  List<Subcategory> get _filteredSubcategories {
    return _subcategoryService.subcategories.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            s.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryId == null || s.categoryId == _selectedCategoryId;
      final matchesStatus = _selectedStatus == null || s.isActive == _selectedStatus;
      
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  void _navigateToAddSubcategory([Subcategory? subcategory]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AddSubcategoryScreen(subcategoryToEdit: subcategory),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Subcategory subcategory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${subcategory.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _subcategoryService.deleteSubcategory(subcategory.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subcategory deleted successfully')));
      }
    }
  }

  Future<void> _confirmToggleStatus(BuildContext context, Subcategory subcategory) async {
    final action = subcategory.isActive ? 'Deactivate' : 'Activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action ${subcategory.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(action, style: TextStyle(color: subcategory.isActive ? Colors.red : Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _subcategoryService.toggleStatus(subcategory.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subcategory ${subcategory.isActive ? 'deactivated' : 'activated'} successfully')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = Column(
          children: [
            _buildFilters(constraints.maxWidth),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final subcategories = _filteredSubcategories;
                  if (subcategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No subcategories found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  if (innerConstraints.maxWidth >= 600) return _buildDataTable(subcategories);
                  return _buildListView(subcategories);
                },
              ),
            ),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Subcategory Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: () => _navigateToAddSubcategory(), 
                            icon: const Icon(Icons.add), 
                            label: const Text('Add Subcategory'),
                          ),
                        ),
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
              title: const Text('Subcategory Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: () => _navigateToAddSubcategory(), 
                      icon: const Icon(Icons.add), 
                      label: const Text('Add Subcategory'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600 
                ? FloatingActionButton(onPressed: () => _navigateToAddSubcategory(), child: const Icon(Icons.add)) 
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildFilters(double maxWidth) {
    bool isMobile = maxWidth < 600;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isMobile 
          ? Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField()),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildCategoryDropdown()),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildStatusDropdown()),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedCategoryId = null;
                      _selectedStatus = null;
                    });
                  }, 
                  icon: const Icon(Icons.clear_all), 
                  label: const Text('Reset'),
                )
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by Name or Code...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
      controller: TextEditingController(text: _searchQuery)..selection = TextSelection.fromPosition(TextPosition(offset: _searchQuery.length)),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String?>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
      value: _selectedCategoryId,
      hint: const Text('Category'),
      items: [
        const DropdownMenuItem(value: null, child: Text('All Categories')),
        ..._categoryService.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
      ],
      onChanged: (value) => setState(() => _selectedCategoryId = value),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<bool?>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
      value: _selectedStatus,
      hint: const Text('Status'),
      items: const [
        DropdownMenuItem(value: null, child: Text('All Status')),
        DropdownMenuItem(value: true, child: Text('Active')),
        DropdownMenuItem(value: false, child: Text('Inactive')),
      ],
      onChanged: (value) => setState(() => _selectedStatus = value),
    );
  }

  Widget _buildListView(List<Subcategory> subcategories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final subcat = subcategories[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${subcat.code} - ${subcat.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Chip(
                      label: Text(
                        subcat.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(color: subcat.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
                      ),
                      backgroundColor: subcat.isActive ? Colors.green.shade100 : Colors.red.shade100,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Category: ${subcat.categoryName}', style: TextStyle(color: Colors.grey.shade700)),
                if (subcat.description != null && subcat.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subcat.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue), 
                      onPressed: () => _navigateToAddSubcategory(subcat),
                    ),
                    IconButton(
                      icon: Icon(subcat.isActive ? Icons.toggle_on : Icons.toggle_off, size: 24, color: subcat.isActive ? Colors.green : Colors.grey), 
                      onPressed: () => _confirmToggleStatus(context, subcat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red), 
                      onPressed: () => _confirmDelete(context, subcat),
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

  Widget _buildDataTable(List<Subcategory> subcategories) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith((states) => Theme.of(context).colorScheme.surfaceContainerHighest),
              columns: const [
                DataColumn(label: Text('Sr. No.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: subcategories.asMap().entries.map((entry) {
                final index = entry.key;
                final subcat = entry.value;
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(subcat.code)),
                    DataCell(Text(subcat.name)),
                    DataCell(Text(subcat.categoryName)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: subcat.isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          subcat.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(color: subcat.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(Text(subcat.createdAt?.toString().split(' ')[0] ?? '-')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.blue), 
                            onPressed: () => _navigateToAddSubcategory(subcat),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: Icon(subcat.isActive ? Icons.toggle_on : Icons.toggle_off, size: 24, color: subcat.isActive ? Colors.green : Colors.grey), 
                            onPressed: () => _confirmToggleStatus(context, subcat),
                            tooltip: subcat.isActive ? 'Deactivate' : 'Activate',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red), 
                            onPressed: () => _confirmDelete(context, subcat),
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
    );
  }
}
