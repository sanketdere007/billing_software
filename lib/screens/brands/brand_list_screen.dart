import 'package:flutter/material.dart';
import '../../models/brand.dart';
import '../../services/brand_service.dart';
import '../../widgets/app_drawer.dart';
import 'add_brand_screen.dart';

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({super.key});

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  final BrandService _brandService = BrandService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _brandService.initializeDummyData();
    _brandService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _brandService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  List<Brand> get _filteredBrands {
    if (_searchQuery.isEmpty) return _brandService.brands;
    return _brandService.brands.where((b) {
      return b.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _navigateToAddBrand() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddBrandScreen()));
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
                  hintText: 'Search brands...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final brands = _filteredBrands;
                  if (brands.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.branding_watermark_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No brands found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  if (innerConstraints.maxWidth >= 600) return _buildDataTable(brands);
                  return _buildListView(brands);
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
                      title: const Text('Brand Master'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilledButton.icon(onPressed: _navigateToAddBrand, icon: const Icon(Icons.add), label: const Text('Add Brand')),
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
              title: const Text('Brand Master'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing list...'))),
                ),
                if (constraints.maxWidth >= 600)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(onPressed: _navigateToAddBrand, icon: const Icon(Icons.add), label: const Text('Add Brand')),
                  ),
              ],
            ),
            drawer: const AppDrawer(isPermanent: false),
            floatingActionButton: constraints.maxWidth < 600 ? FloatingActionButton(onPressed: _navigateToAddBrand, child: const Icon(Icons.add)) : null,
            body: content,
          );
        }
      },
    );
  }

  Widget _buildListView(List<Brand> brands) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(brand.name.substring(0, 1).toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ),
            title: Text(brand.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: brand.description != null ? Text(brand.description!) : null,
            trailing: Chip(
              label: Text(
                brand.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: brand.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
              ),
              backgroundColor: brand.isActive ? Colors.green.shade100 : Colors.red.shade100,
              side: BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<Brand> brands) {
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
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: brands.map((brand) {
                return DataRow(
                  cells: [
                    DataCell(Text(brand.name)),
                    DataCell(Text(brand.description ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: brand.isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          brand.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(color: brand.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
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
