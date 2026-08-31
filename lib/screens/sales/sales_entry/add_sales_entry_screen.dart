import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/product.dart';
import '../../../models/sales_entry.dart';
import '../../../services/sales_entry_service.dart';
import '../../../services/customer_service.dart';
import '../../../services/product_service.dart';
import '../../../services/session_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_message_dialog.dart';
import '../../../widgets/customer_dropdown.dart';
import 'sales_entry_list_screen.dart';
import '../../purchases/purchase_entry/product_selection_dialog.dart';
import '../../../widgets/save_clear_shortcuts.dart';

class AddSalesEntryScreen extends StatefulWidget {
  const AddSalesEntryScreen({super.key});

  @override
  State<AddSalesEntryScreen> createState() => _AddSalesEntryScreenState();
}

class _AddSalesEntryScreenState extends State<AddSalesEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Focus Nodes for Main Fields
  final _invoiceDateNode = FocusNode();
  final _customerNode = FocusNode();

  final _billDiscountController = TextEditingController(text: '0');
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  int? _selectedCustomer;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final List<Map<String, dynamic>> _products = [];

  double _totalQuantity = 0.0;
  double _grossTotal = 0.0;
  double _totalProductDiscount = 0.0;
  double _totalGST = 0.0;
  double _billDiscount = 0.0;
  double _finalPayable = 0.0;

  bool _isLoading = false;

  final CustomerService _customerService = CustomerService();
  final ProductService _productService = productService;

  @override
  void initState() {
    super.initState();
    _customerService.getAllCustomers();
    _productService.getAllProducts();
    _billDiscountController.addListener(_calculateTotals);

    // Auto-add first empty row
    _addNewEmptyRow();

    // Focus customer on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _customerNode.requestFocus();
    });
  }

  void _addNewEmptyRow() {
    _products.add({
      'product': null, // null indicates empty row
      'qty': 1.0,
      'rate': 0.0,
      'discAmt': 0.0,
      'gstPct': 0.0,
      'gross': 0.0,
      'discounted': 0.0,
      'gstAmt': 0.0,
      'net': 0.0,
      'qtyController': TextEditingController(text: '1.0'),
      'rateController': TextEditingController(text: '0.0'),
      'discAmtController': TextEditingController(text: '0.0'),
      'productNode': FocusNode(),
      'qtyNode': FocusNode(),
      'rateNode': FocusNode(),
      'discNode': FocusNode(),
    });
  }

  @override
  void dispose() {
    _invoiceDateNode.dispose();
    _customerNode.dispose();
    _billDiscountController.dispose();

    for (var p in _products) {
      (p['qtyController'] as TextEditingController).dispose();
      (p['rateController'] as TextEditingController).dispose();
      (p['discAmtController'] as TextEditingController).dispose();
      (p['productNode'] as FocusNode).dispose();
      (p['qtyNode'] as FocusNode).dispose();
      (p['rateNode'] as FocusNode).dispose();
      (p['discNode'] as FocusNode).dispose();
    }
    super.dispose();
  }

  void _calculateTotals() {
    double totalQty = 0;
    double grossTotal = 0;
    double totalProdDisc = 0;
    double totalGST = 0;
    double subTotal = 0;

    for (var p in _products) {
      if (p['product'] == null) continue; // Skip empty rows in calculation

      double qty = p['qty'] ?? 0.0;
      double rate = p['rate'] ?? 0.0;
      double disc = p['discAmt'] ?? 0.0;
      double gstPct = p['gstPct'] ?? 0.0;

      double gross = qty * rate;
      double discounted = gross - disc;
      if (discounted < 0) discounted = 0;

      double gstAmt = discounted * (gstPct / 100);
      double net = discounted + gstAmt;

      p['gross'] = gross;
      p['discounted'] = discounted;
      p['gstAmt'] = gstAmt;
      p['net'] = net;

      totalQty += qty;
      grossTotal += gross;
      totalProdDisc += disc;
      totalGST += gstAmt;
      subTotal += net;
    }

    double bDisc = double.tryParse(_billDiscountController.text) ?? 0.0;
    double finalPay = subTotal - bDisc;
    if (finalPay < 0) finalPay = 0;

    setState(() {
      _totalQuantity = totalQty;
      _grossTotal = grossTotal;
      _totalProductDiscount = totalProdDisc;
      _totalGST = totalGST;
      _billDiscount = bDisc;
      _finalPayable = finalPay;
    });
  }

  Future<void> _selectProductForEmptyRow(int index) async {
    final selectedProduct = await showDialog<ProductListItem>(
      context: context,
      builder: (context) => const ProductSelectionDialog(),
    );

    if (selectedProduct != null) {
      // Check if product already exists in another row
      final exists = _products.asMap().entries.any(
        (e) =>
            e.key != index &&
            e.value['product']?.prodId == selectedProduct.prodId,
      );

      if (exists) {
        if (!mounted) return;
        await showWarningDialog(context, 'Product already added!');
        return;
      }

      setState(() {
        final p = _products[index];
        p['product'] = selectedProduct;
        p['gstPct'] = selectedProduct.prodGSTPercent;
        // Keep existing values or reset if needed, currently keeping default 1.0 qty, 0.0 rate
      });
      _calculateTotals();

      // Auto-focus quantity field of this row
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          (_products[index]['qtyNode'] as FocusNode).requestFocus();
        }
      });
    } else {
      // Returned without selection, re-focus product node
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          (_products[index]['productNode'] as FocusNode).requestFocus();
        }
      });
    }
  }

  void _removeProduct(int index) {
    if (_products.length == 1) {
      // Don't remove the last row, just clear it
      final p = _products[index];
      setState(() {
        p['product'] = null;
        p['qty'] = 1.0;
        p['rate'] = 0.0;
        p['discAmt'] = 0.0;
        p['gstPct'] = 0.0;
        (p['qtyController'] as TextEditingController).text = '1.0';
        (p['rateController'] as TextEditingController).text = '0.0';
        (p['discAmtController'] as TextEditingController).text = '0.0';
      });
    } else {
      setState(() {
        final removed = _products.removeAt(index);
        (removed['qtyController'] as TextEditingController).dispose();
        (removed['rateController'] as TextEditingController).dispose();
        (removed['discAmtController'] as TextEditingController).dispose();
        (removed['productNode'] as FocusNode).dispose();
        (removed['qtyNode'] as FocusNode).dispose();
        (removed['rateNode'] as FocusNode).dispose();
        (removed['discNode'] as FocusNode).dispose();
      });
    }
    _calculateTotals();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
    // Move focus to first product in grid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _products.isNotEmpty) {
        (_products.first['productNode'] as FocusNode).requestFocus();
      }
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      await showWarningDialog(context, 'Please select a customer');
      return;
    }

    final validProducts = _products.where((p) => p['product'] != null).toList();
    if (validProducts.isEmpty) {
      await showWarningDialog(context, 'Please add at least one product');
      return;
    }

    final hasZeroRate = validProducts.any((p) => (p['rate'] ?? 0.0) <= 0.0);
    if (hasZeroRate) {
      await showWarningDialog(context, 'Product rate cannot be 0');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await sessionService.getUserData();
      int compId = sessionService.selectedCompId ?? 1;
      int branchId = sessionService.selectedBranchId ?? 1;
      int empId = user?.empId ?? 1;

      int ledgerId = 0;
      try {
        final customer = _customerService.customers.firstWhere(
          (c) => c.custId == _selectedCustomer,
        );
        ledgerId = customer.custLedgerId;
      } catch (e) {
        // ignore
      }

      final masterData = SalesEntryMasterData(
        compId: compId,
        branchId: branchId,
        customerId: _selectedCustomer!,
        invoiceNo: 'AUTO', // Or empty string, depends on backend
        invoiceDate: _selectedDate.toIso8601String(),
        subTotal: _grossTotal,
        discountAmount: _totalProductDiscount + _billDiscount,
        gstAmount: _totalGST,
        otherCharges: 0,
        netAmount: _finalPayable,
        paidAmount: 0,
        balanceAmount: _finalPayable,
        status: 'Completed',
        remark: '',
        createdBy: empId,
        modifiedBy: empId,
        ledgerId: ledgerId,
      );

      final detailData = validProducts.map((p) {
        final ProductListItem prod = p['product'];
        return SalesEntryDetailData(
          compId: compId,
          branchId: branchId,
          productId: prod.prodId,
          barcode: '',
          eanCode: '',
          qty: p['qty'],
          mrp: p['rate'],
          sellingPrice: p['rate'],
          discountPercent: 0,
          discountAmount: p['discAmt'],
          gstPercent: p['gstPct'],
          gstAmount: p['gstAmt'],
          totalAmount: p['net'],
        );
      }).toList();

      final request = SalesEntryUpsertRequest(
        masterData: masterData,
        detailData: detailData,
      );

      final response = await SalesEntryService().insertOrUpdateSalesEntry(
        request,
      );

      if (mounted) {
        await showSuccessDialog(context, response.message);
        if (!mounted) return;
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _billDiscountController.text = '0';
      _selectedCustomer = null;

      // Clear and re-init products
      for (var p in _products) {
        (p['qtyController'] as TextEditingController).dispose();
        (p['rateController'] as TextEditingController).dispose();
        (p['discAmtController'] as TextEditingController).dispose();
        (p['productNode'] as FocusNode).dispose();
        (p['qtyNode'] as FocusNode).dispose();
        (p['rateNode'] as FocusNode).dispose();
        (p['discNode'] as FocusNode).dispose();
      }
      _products.clear();
      _addNewEmptyRow();

      _selectedDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      _calculateTotals();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _customerNode.requestFocus();
    });
  }

  KeyEventResult _handleGridKeyEvent(
    FocusNode node,
    KeyEvent event,
    int index,
    String fieldName,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final p = _products[index];

    // 1. Delete row
    if (key == LogicalKeyboardKey.delete && fieldName == 'product') {
      if (p['product'] != null) {
        _removeProduct(index);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final targetIndex = index < _products.length
                ? index
                : _products.length - 1;
            (_products[targetIndex]['productNode'] as FocusNode).requestFocus();
          }
        });
        return KeyEventResult.handled;
      }
    }

    // Enter key for Product
    if (fieldName == 'product' &&
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space)) {
      _selectProductForEmptyRow(index);
      return KeyEventResult.handled;
    }

    // 2. Up Arrow
    if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) {
        (_products[index - 1]['${fieldName}Node'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      }
    }

    // 3. Down Arrow
    if (key == LogicalKeyboardKey.arrowDown) {
      if (index < _products.length - 1) {
        (_products[index + 1]['${fieldName}Node'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      }
    }

    // 4. Left / Right Arrow text editing check
    if ((key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight) &&
        fieldName != 'product') {
      String controllerKey = fieldName == 'disc'
          ? 'discAmtController'
          : '${fieldName}Controller';
      final controller = p[controllerKey] as TextEditingController;
      if (controller.selection.isValid) {
        if (controller.selection.baseOffset !=
            controller.selection.extentOffset) {
          return KeyEventResult.ignored;
        }
        if (key == LogicalKeyboardKey.arrowLeft &&
            controller.selection.baseOffset > 0) {
          return KeyEventResult.ignored;
        }
        if (key == LogicalKeyboardKey.arrowRight &&
            controller.selection.baseOffset < controller.text.length) {
          return KeyEventResult.ignored;
        }
      }
    }

    // 5. Left Arrow move focus
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (fieldName == 'disc') {
        (p['rateNode'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      } else if (fieldName == 'rate') {
        (p['qtyNode'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      } else if (fieldName == 'qty') {
        (p['productNode'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      } else if (fieldName == 'product') {
        if (index > 0) {
          final prevP = _products[index - 1];
          if ((prevP['rate'] ?? 0.0) > 0.0) {
            (prevP['discNode'] as FocusNode).requestFocus();
          } else {
            (prevP['rateNode'] as FocusNode).requestFocus();
          }
          return KeyEventResult.handled;
        }
      }
    }

    // 6. Right Arrow move focus
    if (key == LogicalKeyboardKey.arrowRight) {
      if (fieldName == 'product') {
        if (p['product'] != null) {
          (p['qtyNode'] as FocusNode).requestFocus();
          return KeyEventResult.handled;
        }
      } else if (fieldName == 'qty') {
        (p['rateNode'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      } else if (fieldName == 'rate') {
        if ((p['rate'] ?? 0.0) > 0.0) {
          (p['discNode'] as FocusNode).requestFocus();
        } else if (index < _products.length - 1) {
          (_products[index + 1]['productNode'] as FocusNode).requestFocus();
        }
        return KeyEventResult.handled;
      } else if (fieldName == 'disc') {
        if (index < _products.length - 1) {
          (_products[index + 1]['productNode'] as FocusNode).requestFocus();
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  Widget _buildProductTable() {
    final theme = Theme.of(context);

    // Fixed widths for columns
    const double colProductName = 260;
    const double colQty = 100;
    const double colRate = 120;
    const double colGross = 100;
    const double colDiscount = 110;
    const double colGstPct = 80;
    const double colGstAmt = 100;
    const double colNet = 120;
    const double colAction = 60;
    const double totalWidth =
        colProductName +
        colQty +
        colRate +
        colGross +
        colDiscount +
        colGstPct +
        colGstAmt +
        colNet +
        colAction;

    Widget buildHeaderCell(
      String text,
      double width, {
      bool isNumeric = false,
      bool isLast = false,
    }) {
      return Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
        ),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Widget buildDataCell(
      Widget child,
      double width, {
      bool isNumeric = false,
      EdgeInsets? padding,
      bool isLast = false,
    }) {
      return Container(
        width: width,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
        ),
        child: child,
      );
    }

    return SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveEntry();
      },
      onClear: _resetForm,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tableWidth = constraints.maxWidth > totalWidth
              ? constraints.maxWidth
              : totalWidth;
          final double extraWidth = constraints.maxWidth > totalWidth
              ? constraints.maxWidth - totalWidth
              : 0.0;
          final double effectiveProductNameWidth = colProductName + extraWidth;

        return Container(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildHeaderCell(
                            'Product Name',
                            effectiveProductNameWidth,
                          ),
                          buildHeaderCell('Qty', colQty, isNumeric: true),
                          buildHeaderCell('Selling Price', colRate, isNumeric: true),
                          buildHeaderCell('Gross', colGross, isNumeric: true),
                          buildHeaderCell(
                            'Discount',
                            colDiscount,
                            isNumeric: true,
                          ),
                          buildHeaderCell('GST %', colGstPct, isNumeric: true),
                          buildHeaderCell(
                            'GST Amt',
                            colGstAmt,
                            isNumeric: true,
                          ),
                          buildHeaderCell('Net Amt', colNet, isNumeric: true),
                          buildHeaderCell(
                            'Act',
                            colAction,
                            isNumeric: true,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Scrollable Data Rows
                  Expanded(
                    child: ListView.separated(
                      itemCount: _products.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.5,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final p = _products[index];
                        final ProductListItem? prod = p['product'];
                        final isEven = index.isEven;

                        final bool isEmptyRow = prod == null;

                        (p['productNode'] as FocusNode).onKeyEvent =
                            (node, event) => _handleGridKeyEvent(
                              node,
                              event,
                              index,
                              'product',
                            );
                        (p['qtyNode'] as FocusNode).onKeyEvent =
                            (node, event) =>
                                _handleGridKeyEvent(node, event, index, 'qty');
                        (p['rateNode'] as FocusNode).onKeyEvent =
                            (node, event) =>
                                _handleGridKeyEvent(node, event, index, 'rate');
                        (p['discNode'] as FocusNode).onKeyEvent =
                            (node, event) =>
                                _handleGridKeyEvent(node, event, index, 'disc');

                        return AnimatedBuilder(
                          animation: Listenable.merge([
                            p['productNode'] as FocusNode,
                            p['qtyNode'] as FocusNode,
                            p['rateNode'] as FocusNode,
                            p['discNode'] as FocusNode,
                          ]),
                          builder: (context, child) {
                            final isRowFocused =
                                (p['productNode'] as FocusNode).hasFocus ||
                                (p['qtyNode'] as FocusNode).hasFocus ||
                                (p['rateNode'] as FocusNode).hasFocus ||
                                (p['discNode'] as FocusNode).hasFocus;
                            return Container(
                              key: ValueKey(prod?.prodId ?? 'empty_$index'),
                              color: isRowFocused
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.4)
                                  : (isEven
                                        ? theme.colorScheme.surfaceVariant
                                              .withOpacity(0.1)
                                        : null),
                              child: child,
                            );
                          },
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buildDataCell(
                                  Focus(
                                    focusNode: p['productNode'],
                                    child: Builder(
                                      builder: (context) {
                                        final isFocused = Focus.of(
                                          context,
                                        ).hasFocus;
                                        return InkWell(
                                          onTap: () =>
                                              _selectProductForEmptyRow(index),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isFocused
                                                    ? theme.colorScheme.primary
                                                    : Colors.transparent,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isFocused
                                                  ? theme
                                                        .colorScheme
                                                        .primaryContainer
                                                        .withOpacity(0.2)
                                                  : Colors.transparent,
                                            ),
                                            child: isEmptyRow
                                                ? Row(
                                                    children: [
                                                      Icon(
                                                        Icons.search,
                                                        size: 16,
                                                        color: theme.hintColor,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Select Product (Enter)',
                                                        style: TextStyle(
                                                          color:
                                                              theme.hintColor,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        prod.prodName,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        'Code: ${prod.prodCode} | Unit: ${prod.prodUnitShortName}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  effectiveProductNameWidth,
                                ),
                                buildDataCell(
                                  Focus(
                                    focusNode: p['qtyNode'],
                                    onFocusChange: (focused) {
                                      if (focused) {
                                        (p['qtyController']
                                                as TextEditingController)
                                            .selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: (p['qtyController']
                                                  as TextEditingController)
                                              .text
                                              .length,
                                        );
                                      }
                                    },
                                    child: TextFormField(
                                      controller: p['qtyController'],
                                      enabled: !isEmptyRow,
                                      textAlign: TextAlign.right,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'),
                                        ),
                                      ],
                                      decoration: _gridInputDecoration(theme),
                                      onChanged: (val) {
                                        p['qty'] = double.tryParse(val) ?? 0.0;
                                        _calculateTotals();
                                      },
                                      onFieldSubmitted: (_) {
                                        (p['rateNode'] as FocusNode)
                                            .requestFocus();
                                      },
                                    ),
                                  ),
                                  colQty,
                                  isNumeric: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                buildDataCell(
                                  Focus(
                                    focusNode: p['rateNode'],
                                    onFocusChange: (focused) {
                                      if (focused) {
                                        (p['rateController']
                                                as TextEditingController)
                                            .selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: (p['rateController']
                                                  as TextEditingController)
                                              .text
                                              .length,
                                        );
                                      }
                                    },
                                    child: TextFormField(
                                      controller: p['rateController'],
                                      enabled: !isEmptyRow,
                                      textAlign: TextAlign.right,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'),
                                        ),
                                      ],
                                      decoration: _gridInputDecoration(theme),
                                      onChanged: (val) {
                                        final newRate = double.tryParse(val) ?? 0.0;
                                        p['rate'] = newRate;
                                        if (newRate <= 0.0) {
                                          p['discAmt'] = 0.0;
                                          (p['discAmtController'] as TextEditingController).text = '0.0';
                                        }
                                        _calculateTotals();
                                      },
                                      onFieldSubmitted: (_) {
                                        if ((p['rate'] ?? 0.0) > 0.0) {
                                          (p['discNode'] as FocusNode).requestFocus();
                                        } else {
                                          if (index == _products.length - 1) {
                                            setState(() {
                                              _addNewEmptyRow();
                                            });
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (mounted) {
                                                final newNode = _products.last['productNode'] as FocusNode;
                                                newNode.requestFocus();
                                              }
                                            });
                                          } else {
                                            (_products[index + 1]['productNode'] as FocusNode).requestFocus();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  colRate,
                                  isNumeric: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                buildDataCell(
                                  Text(
                                    (p['gross'] as double? ?? 0.0)
                                        .toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  colGross,
                                  isNumeric: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                buildDataCell(
                                  Focus(
                                    focusNode: p['discNode'],
                                    onFocusChange: (focused) {
                                      if (focused) {
                                        (p['discAmtController']
                                                as TextEditingController)
                                            .selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: (p['discAmtController']
                                                  as TextEditingController)
                                              .text
                                              .length,
                                        );
                                      }
                                    },
                                    child: TextFormField(
                                      controller: p['discAmtController'],
                                      enabled: !isEmptyRow && (p['rate'] ?? 0.0) > 0.0,
                                      textAlign: TextAlign.right,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'),
                                        ),
                                      ],
                                      decoration: _gridInputDecoration(theme),
                                      onChanged: (val) {
                                        p['discAmt'] =
                                            double.tryParse(val) ?? 0.0;
                                        _calculateTotals();
                                      },
                                      onFieldSubmitted: (_) {
                                        if (index == _products.length - 1) {
                                          setState(() {
                                            _addNewEmptyRow();
                                          });
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (mounted) {
                                              final newNode = _products.last['productNode'] as FocusNode;
                                              newNode.requestFocus();
                                            }
                                          });
                                        } else {
                                          (_products[index + 1]['productNode']
                                                  as FocusNode)
                                              .requestFocus();
                                        }
                                      },
                                    ),
                                  ),
                                  colDiscount,
                                  isNumeric: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                buildDataCell(
                                  Text(
                                    '${(p['gstPct'] as double? ?? 0.0).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  colGstPct,
                                  isNumeric: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                buildDataCell(
                                  Text(
                                    (p['gstAmt'] as double? ?? 0.0)
                                        .toStringAsFixed(2),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  colGstAmt,
                                  isNumeric: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                buildDataCell(
                                  Text(
                                    (p['net'] as double? ?? 0.0).toStringAsFixed(
                                      2,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  colNet,
                                  isNumeric: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                buildDataCell(
                                  isEmptyRow
                                      ? const SizedBox()
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          color: theme.colorScheme.error,
                                          tooltip: 'Remove',
                                          iconSize: 20,
                                          splashRadius: 20,
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            _removeProduct(index);
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (mounted) {
                                                final targetIndex =
                                                    index < _products.length
                                                        ? index
                                                        : _products.length - 1;
                                                (_products[targetIndex]['productNode']
                                                        as FocusNode)
                                                    .requestFocus();
                                              }
                                            });
                                          },
                                        ),
                                  colAction,
                                  isNumeric: true,
                                  isLast: true,
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
            ),
          ),
        );
        },
      ),
    );
  }

  InputDecoration _gridInputDecoration(ThemeData theme) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.transparent,
    );
  }

  Widget _buildSummaryPanel() {
    final theme = Theme.of(context);

    Widget buildSummaryItem(String label, String value, {bool isBold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                color: isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 16 : 13,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: summary info
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                buildSummaryItem('Items', '${_products.where((p) => p['product'] != null).length}'),
                buildSummaryItem('Qty', _totalQuantity.toStringAsFixed(2)),
                Container(height: 24, width: 1, color: theme.colorScheme.outlineVariant),
                buildSummaryItem('Gross', '₹${_grossTotal.toStringAsFixed(2)}'),
                buildSummaryItem('Item Disc', '-₹${_totalProductDiscount.toStringAsFixed(2)}'),
                buildSummaryItem('GST', '+₹${_totalGST.toStringAsFixed(2)}'),
                Container(height: 24, width: 1, color: theme.colorScheme.outlineVariant),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bill Disc: ',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 80,
                      height: 32,
                      child: TextField(
                        controller: _billDiscountController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: theme.colorScheme.outlineVariant),
                buildSummaryItem('Net', '₹${_finalPayable.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
          
          // Right side: action buttons
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Clear'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveEntry,
                icon: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(_isLoading ? 'Saving...' : 'Save Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;

    Widget content = Form(
      key: _formKey,
      child: Column(
        children: [
          // Top Header / Master Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomerDropdown(
                        focusNode: _customerNode,
                        nextFocusNode: _invoiceDateNode,
                        selectedCustomerId: _selectedCustomer,
                        isRequired: true,
                        onChanged: (customer) {
                          setState(() {
                            _selectedCustomer = customer?.custId;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Focus(
                        focusNode: _invoiceDateNode,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && 
                              (event.logicalKey == LogicalKeyboardKey.enter || 
                               event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                               event.logicalKey == LogicalKeyboardKey.space)) {
                            _selectDate(context);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (context) {
                            final isFocused = Focus.of(context).hasFocus;
                            return InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                isFocused: isFocused,
                                decoration: InputDecoration(
                                  labelText: 'Invoice Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2.0,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  isDense: true,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_dateFormat.format(_selectedDate)),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Body: Grid and Summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildProductTable()),
                Container(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
                _buildSummaryPanel(),
              ],
            ),
          ),
        ],
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
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SalesEntryListScreen()),
                      );
                    },
                  ),
                  title: const Text('New Sales Invoice'),
                  actions: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SalesEntryListScreen()),
                        );
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('View All Invoices'),
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
          title: const Text('New Sales Invoice'),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SalesEntryListScreen()),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(isPermanent: false),
        body: content,
      );
    }
  }
}
