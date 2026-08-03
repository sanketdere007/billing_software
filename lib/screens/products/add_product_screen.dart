import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/app_drawer.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  bool _isLoading = false;

  // Form values
  String _name = '';
  String _code = '';
  String _barcode = '';
  String _category = '';
  String _brand = '';
  String _unit = '';
  String _hsnSac = '';
  String _gst = '';
  double _purchasePrice = 0.0;
  double _sellingPrice = 0.0;
  double _mrp = 0.0;
  double _openingStock = 0.0;
  double _minimumStock = 0.0;
  bool _isActive = true;

  Future<void> _saveProduct({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newProduct = Product(
        id: 'PROD-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        code: _code.isNotEmpty ? _code : null,
        barcode: _barcode.isNotEmpty ? _barcode : null,
        category: _category,
        brand: _brand,
        unit: _unit,
        hsnSac: _hsnSac,
        gst: _gst,
        purchasePrice: _purchasePrice,
        sellingPrice: _sellingPrice,
        mrp: _mrp,
        openingStock: _openingStock,
        minimumStock: _minimumStock,
        isActive: _isActive,
      );

      await _productService.addProduct(newProduct);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _isActive = true;
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        Widget content = _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildNameField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildCodeField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildBarcodeField()),
                              ],
                            ),
                          ] else ...[
                            _buildNameField(),
                            const SizedBox(height: 16),
                            _buildCodeField(),
                            const SizedBox(height: 16),
                            _buildBarcodeField(),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Classification',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildCategoryField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildBrandField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildUnitField()),
                              ],
                            ),
                          ] else ...[
                            _buildCategoryField(),
                            const SizedBox(height: 16),
                            _buildBrandField(),
                            const SizedBox(height: 16),
                            _buildUnitField(),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Tax Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildHSNField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildGSTField()),
                              ],
                            ),
                          ] else ...[
                            _buildHSNField(),
                            const SizedBox(height: 16),
                            _buildGSTField(),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Pricing',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildPurchasePriceField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSellingPriceField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMRPField()),
                              ],
                            ),
                          ] else ...[
                            _buildPurchasePriceField(),
                            const SizedBox(height: 16),
                            _buildSellingPriceField(),
                            const SizedBox(height: 16),
                            _buildMRPField(),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Inventory',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildOpeningStockField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMinimumStockField()),
                              ],
                            ),
                          ] else ...[
                            _buildOpeningStockField(),
                            const SizedBox(height: 16),
                            _buildMinimumStockField(),
                          ],
                          const SizedBox(height: 16),
                          _buildStatusField(),
                          const SizedBox(height: 32),
                          _buildActionButtons(constraints.maxWidth >= 600),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
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
                    appBar: AppBar(title: const Text('Add Product')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Product')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
      validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Product Code/SKU', border: OutlineInputBorder()),
      onSaved: (value) => _code = value?.trim() ?? '',
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder()),
      onSaved: (value) => _barcode = value?.trim() ?? '',
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
        DropdownMenuItem(value: 'Furniture', child: Text('Furniture')),
      ],
      validator: (value) => value == null ? 'Required' : null,
      onChanged: (value) {},
      onSaved: (value) => _category = value ?? '',
    );
  }

  Widget _buildBrandField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Brand *', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'Logitech', child: Text('Logitech')),
        DropdownMenuItem(value: 'Corsair', child: Text('Corsair')),
      ],
      validator: (value) => value == null ? 'Required' : null,
      onChanged: (value) {},
      onSaved: (value) => _brand = value ?? '',
    );
  }

  Widget _buildUnitField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Unit *', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'Pieces', child: Text('Pieces')),
        DropdownMenuItem(value: 'Box', child: Text('Box')),
      ],
      validator: (value) => value == null ? 'Required' : null,
      onChanged: (value) {},
      onSaved: (value) => _unit = value ?? '',
    );
  }

  Widget _buildHSNField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'HSN/SAC *', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: '8471', child: Text('8471')),
        DropdownMenuItem(value: '8517', child: Text('8517')),
      ],
      validator: (value) => value == null ? 'Required' : null,
      onChanged: (value) {},
      onSaved: (value) => _hsnSac = value ?? '',
    );
  }

  Widget _buildGSTField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'GST *', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: '0%', child: Text('0%')),
        DropdownMenuItem(value: '5%', child: Text('5%')),
        DropdownMenuItem(value: '12%', child: Text('12%')),
        DropdownMenuItem(value: '18%', child: Text('18%')),
        DropdownMenuItem(value: '28%', child: Text('28%')),
      ],
      validator: (value) => value == null ? 'Required' : null,
      onChanged: (value) {},
      onSaved: (value) => _gst = value ?? '',
    );
  }

  Widget _buildPurchasePriceField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Purchase Price', border: OutlineInputBorder(), prefixText: '₹ '),
      keyboardType: TextInputType.number,
      onSaved: (value) => _purchasePrice = double.tryParse(value ?? '') ?? 0.0,
    );
  }

  Widget _buildSellingPriceField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Selling Price', border: OutlineInputBorder(), prefixText: '₹ '),
      keyboardType: TextInputType.number,
      onSaved: (value) => _sellingPrice = double.tryParse(value ?? '') ?? 0.0,
    );
  }

  Widget _buildMRPField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'MRP', border: OutlineInputBorder(), prefixText: '₹ '),
      keyboardType: TextInputType.number,
      onSaved: (value) => _mrp = double.tryParse(value ?? '') ?? 0.0,
    );
  }

  Widget _buildOpeningStockField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Opening Stock', border: OutlineInputBorder()),
      keyboardType: TextInputType.number,
      onSaved: (value) => _openingStock = double.tryParse(value ?? '') ?? 0.0,
    );
  }

  Widget _buildMinimumStockField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Minimum Stock', border: OutlineInputBorder()),
      keyboardType: TextInputType.number,
      onSaved: (value) => _minimumStock = double.tryParse(value ?? '') ?? 0.0,
    );
  }

  Widget _buildStatusField() {
    return SwitchListTile(
      title: const Text('Status (Active)'),
      value: _isActive,
      onChanged: (value) => setState(() => _isActive = value),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          const SizedBox(width: 16),
          FilledButton.tonal(onPressed: () => _saveProduct(saveAndNew: true), child: const Text('Save & New')),
          const SizedBox(width: 16),
          FilledButton(onPressed: () => _saveProduct(saveAndNew: false), child: const Text('Save')),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(onPressed: () => _saveProduct(saveAndNew: false), child: const Text('Save')),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: () => _saveProduct(saveAndNew: true), child: const Text('Save & New')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      );
    }
  }
}
