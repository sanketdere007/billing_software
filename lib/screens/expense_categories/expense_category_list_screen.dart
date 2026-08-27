import 'package:flutter/material.dart';
import '../../models/expense_category.dart';
import '../../services/expense_category_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_expense_category_screen.dart';

class ExpenseCategoryListScreen extends StatefulWidget {
  const ExpenseCategoryListScreen({super.key});

  @override
  State<ExpenseCategoryListScreen> createState() => _ExpenseCategoryListScreenState();
}

class _ExpenseCategoryListScreenState extends State<ExpenseCategoryListScreen> {
  final ExpenseCategoryService _service = ExpenseCategoryService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.initializeDummyData();
    _service.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<ExpenseCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return _service.categories;
    }
    return _service.categories.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
             (c.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddExpenseCategoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search expense categories...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final categories = _filteredCategories;
                  
                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No expense categories found',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (innerConstraints.maxWidth >= 600) {
                    return _buildDataTable(categories);
                  } else {
                    return _buildListView(categories);
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
                      title: const Text('Expense Category Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(
                            onPressed: _navigateToAdd,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense Category'),
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
              title: const Text('Expense Category Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: _navigateToAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Expense Category'),
                    ),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600
                ? FloatingActionButton(
                    onPressed: _navigateToAdd,
                    child: const Icon(Icons.add),
                  )
                : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<ExpenseCategory> categories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: category.description != null && category.description!.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(category.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  )
                : null,
            trailing: Chip(
              label: Text(
                category.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: category.isActive ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: category.isActive ? Colors.green.shade100 : Colors.red.shade100,
              side: BorderSide.none,
            ),
            onTap: () {
              // Navigate to details/edit
            },
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<ExpenseCategory> categories) {
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
              headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => Theme.of(context).colorScheme.surfaceContainerHighest),
              columns: const [
                DataColumn(label: Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: categories.map((category) {
                return DataRow(
                  cells: [
                    DataCell(Text(category.name)),
                    DataCell(Text(category.description ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: category.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: category.isActive ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () {},
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
