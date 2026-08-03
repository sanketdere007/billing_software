import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/currency.dart';
import '../../services/currency_service.dart';
import '../../widgets/app_drawer.dart';

class AddCurrencyScreen extends StatefulWidget {
  const AddCurrencyScreen({super.key});

  @override
  State<AddCurrencyScreen> createState() => _AddCurrencyScreenState();
}

class _AddCurrencyScreenState extends State<AddCurrencyScreen> {
  final _formKey = GlobalKey<FormState>();
  final CurrencyService _service = CurrencyService();
  bool _isLoading = false;

  String _name = '';
  String _code = '';
  String _symbol = '';
  int _decimalPlaces = 2;
  double _exchangeRate = 1.0;
  bool _isDefault = false;
  bool _isActive = true;

  Future<void> _saveCurrency({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newCurrency = Currency(
        id: 'CUR-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        code: _code,
        symbol: _symbol,
        decimalPlaces: _decimalPlaces,
        exchangeRate: _exchangeRate,
        isDefault: _isDefault,
        isActive: _isActive,
      );

      await _service.addCurrency(newCurrency);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Currency saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (saveAndNew) {
        _formKey.currentState!.reset();
        setState(() {
          _isDefault = false;
          _isActive = true;
          _isLoading = false;
          _decimalPlaces = 2;
          _exchangeRate = 1.0;
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
          content: Text('Error saving currency: $e'),
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
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currency Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildNameField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildCodeField()),
                              ],
                            ),
                          ] else ...[
                            _buildNameField(),
                            const SizedBox(height: 16),
                            _buildCodeField(),
                          ],
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 600) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildSymbolField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDecimalPlacesField()),
                              ],
                            ),
                          ] else ...[
                            _buildSymbolField(),
                            const SizedBox(height: 16),
                            _buildDecimalPlacesField(),
                          ],
                          const SizedBox(height: 16),
                          _buildExchangeRateField(),
                          const SizedBox(height: 16),
                          _buildDefaultField(),
                          const SizedBox(height: 8),
                          _buildStatusField(),
                          const SizedBox(height: 32),
                          _buildActionButtons(constraints.maxWidth >= 600),
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
                    appBar: AppBar(title: const Text('Add Currency')),
                    body: content,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Currency')),
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        }
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Currency Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter currency name';
        }
        return null;
      },
      onSaved: (value) => _name = value!.trim(),
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Currency Code *',
        border: OutlineInputBorder(),
        hintText: 'e.g., USD, INR, EUR',
      ),
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter currency code';
        }
        if (value.trim().length != 3) {
          return 'Currency code should be 3 characters';
        }
        return null;
      },
      onSaved: (value) => _code = value!.trim().toUpperCase(),
    );
  }

  Widget _buildSymbolField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Currency Symbol *',
        border: OutlineInputBorder(),
        hintText: 'e.g., \$, ₹, €',
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter currency symbol';
        }
        return null;
      },
      onSaved: (value) => _symbol = value!.trim(),
    );
  }

  Widget _buildDecimalPlacesField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Decimal Places',
        border: OutlineInputBorder(),
      ),
      initialValue: '2',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _decimalPlaces = int.tryParse(value) ?? 2;
        }
      },
    );
  }

  Widget _buildExchangeRateField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Exchange Rate',
        border: OutlineInputBorder(),
        hintText: 'Base currency exchange rate',
      ),
      initialValue: '1.0',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter exchange rate';
        }
        if (double.tryParse(value) == null || double.parse(value) <= 0) {
          return 'Please enter a valid rate > 0';
        }
        return null;
      },
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _exchangeRate = double.tryParse(value) ?? 1.0;
        }
      },
    );
  }

  Widget _buildDefaultField() {
    return SwitchListTile(
      title: const Text('Set as Default Currency'),
      value: _isDefault,
      onChanged: (value) {
        setState(() {
          _isDefault = value;
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildStatusField() {
    return SwitchListTile(
      title: const Text('Status (Active)'),
      value: _isActive,
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          FilledButton.tonal(
            onPressed: () => _saveCurrency(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => _saveCurrency(saveAndNew: false),
            child: const Text('Save'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => _saveCurrency(saveAndNew: false),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _saveCurrency(saveAndNew: true),
            child: const Text('Save & New'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
  }
}
