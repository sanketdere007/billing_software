import 'package:billing_software/screens/sales/sales_return/sales_return_view_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/batch.dart';
import '../../../models/sales_return.dart';
import '../../../models/customer.dart';
import '../../../models/company.dart';
import '../../../models/login_response.dart';
import '../../../services/sales_return_service.dart';
import '../../../services/customer_service.dart';
import '../../../services/company_service.dart';
import '../../../services/batch_service.dart';
import '../../../services/product_service.dart';
import '../../../services/session_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_message_dialog.dart';
import '../../../widgets/customer_dropdown.dart';
import '../sales_entry/batch_selection_dialog.dart';
import '../../../widgets/save_clear_shortcuts.dart';
import '../../../services/invoice_pdf_data_factory.dart';
import '../../../services/shortcut_service.dart';
import '../../pdf/pdf_preview_screen.dart';
import '../sales_entry/payment_mode_dialog.dart';

class SalePersistResult {
  final SalesReturnUpsertResponse salesResponse;
  final SalesReturnMasterData masterData;
  final List<SalesReturnDetailData> detailData;
  final List<Map<String, dynamic>> productRows;
  final SalesPaymentDetails payment;
  final CustomerListItem? customer;
  final CompanyListItem? company;
  final UserData? user;

  const SalePersistResult({
    required this.salesResponse,
    required this.masterData,
    required this.detailData,
    required this.productRows,
    required this.payment,
    this.customer,
    this.company,
    this.user,
  });
}

class AddSalesReturnScreen extends StatefulWidget {
  const AddSalesReturnScreen({super.key});

  @override
  State<AddSalesReturnScreen> createState() => _AddSalesReturnScreenState();
}

class _AddSalesReturnScreenState extends State<AddSalesReturnScreen> {
  final _formKey = GlobalKey<FormState>();

  // Focus Nodes for Main Fields
  final _invoiceDateNode = FocusNode();
  final _customerNode = FocusNode();

  final _billDiscountPctController = TextEditingController(text: '0');
  final _billDiscountController = TextEditingController(text: '0');
  final _billDiscountPctNode = FocusNode();
  final _billDiscountAmtNode = FocusNode();
  bool _isDiscountPctLastEdited = false;
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
  bool _isViewMode = false;

  final CustomerService _customerService = CustomerService();
  final BatchService _batchService = batchService;

  @override
  void initState() {
    super.initState();
    _customerService.getAllCustomers();
    _batchService.getAllBatches();
    productService.getAllProducts(isActive: true);
    _billDiscountPctController.addListener(_calculateTotals);
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
      'discPct': 0.0,
      'discAmt': 0.0,
      'gstPct': 0.0,
      'gross': 0.0,
      'discounted': 0.0,
      'gstAmt': 0.0,
      'net': 0.0,
      'qtyController': TextEditingController(text: '1.0'),
      'rateController': TextEditingController(text: '0.0'),
      'discPctController': TextEditingController(text: '0'),
      'discAmtController': TextEditingController(text: '0.0'),
      'productNode': FocusNode(),
      'qtyNode': FocusNode(),
      'rateNode': FocusNode(),
      'discPctNode': FocusNode(),
      'discNode': FocusNode(),
    });
  }

  @override
  void dispose() {
    _invoiceDateNode.dispose();
    _customerNode.dispose();
    _billDiscountPctController.dispose();
    _billDiscountController.dispose();
    _billDiscountPctNode.dispose();
    _billDiscountAmtNode.dispose();

    for (var p in _products) {
      (p['qtyController'] as TextEditingController).dispose();
      (p['rateController'] as TextEditingController).dispose();
      (p['discPctController'] as TextEditingController).dispose();
      (p['discAmtController'] as TextEditingController).dispose();
      (p['productNode'] as FocusNode).dispose();
      (p['qtyNode'] as FocusNode).dispose();
      (p['rateNode'] as FocusNode).dispose();
      (p['discPctNode'] as FocusNode).dispose();
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

      double qty = (p['qty'] as num?)?.toDouble() ?? 0.0;
      double rate = (p['rate'] as num?)?.toDouble() ?? 0.0;
      double gstPct = (p['gstPct'] as num?)?.toDouble() ?? 0.0;

      double gross = qty * rate;
      double disc = 0.0;

      if ((p['discPctNode'] as FocusNode).hasFocus) {
        double pct = (p['discPct'] as num?)?.toDouble() ?? 0.0;
        disc = gross * (pct / 100);
        p['discAmt'] = disc;
        final amtStr = disc.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        if ((p['discAmtController'] as TextEditingController).text != amtStr &&
            (p['discAmtController'] as TextEditingController).text != disc.toString()) {
          (p['discAmtController'] as TextEditingController).text = amtStr;
        }
      } else {
        disc = (p['discAmt'] as num?)?.toDouble() ?? 0.0;
        if (gross > 0) {
          double pct = (disc / gross) * 100;
          p['discPct'] = pct;
          final pctStr = pct.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
          if ((p['discPctController'] as TextEditingController).text != pctStr &&
              (p['discPctController'] as TextEditingController).text != pct.toString()) {
            (p['discPctController'] as TextEditingController).text = pctStr;
          }
        } else {
          p['discPct'] = 0.0;
          if ((p['discPctController'] as TextEditingController).text != '0' &&
              (p['discPctController'] as TextEditingController).text != '0.0') {
            (p['discPctController'] as TextEditingController).text = '0';
          }
        }
      }

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

    if (_billDiscountPctNode.hasFocus) {
      _isDiscountPctLastEdited = true;
    } else if (_billDiscountAmtNode.hasFocus) {
      _isDiscountPctLastEdited = false;
    }

    double bDisc = 0.0;
    if (_isDiscountPctLastEdited) {
      double pct = double.tryParse(_billDiscountPctController.text) ?? 0.0;
      bDisc = subTotal * (pct / 100);
      final amtStr = bDisc.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
      if (_billDiscountController.text != amtStr &&
          _billDiscountController.text != bDisc.toString()) {
        _billDiscountController.text = amtStr;
      }
    } else {
      bDisc = double.tryParse(_billDiscountController.text) ?? 0.0;
      if (subTotal > 0) {
        double pct = (bDisc / subTotal) * 100;
        final pctStr = pct.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        if (_billDiscountPctController.text != pctStr &&
            _billDiscountPctController.text != pct.toString()) {
          _billDiscountPctController.text = pctStr;
        }
      } else {
        if (_billDiscountPctController.text != '0' &&
            _billDiscountPctController.text != '0.0') {
          _billDiscountPctController.text = '0';
        }
      }
    }

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
    final selectedProduct = await showDialog<BatchListItem>(
      context: context,
      builder: (context) => const BatchSelectionDialog(),
    );

    if (selectedProduct != null) {
      // Check if product already exists in another row
      final exists = _products.asMap().entries.any(
        (e) =>
            e.key != index &&
            e.value['product']?.batchId == selectedProduct.batchId,
      );

      if (exists) {
        if (!mounted) return;
        await showWarningDialog(context, 'This batch number is already added.');
        return;
      }

      final gstPct = await _resolveGstPercent(selectedProduct);
      if (!mounted) return;

      setState(() {
        final p = _products[index];
        p['product'] = selectedProduct;
        p['gstPct'] = gstPct;
        p['rate'] = selectedProduct.batchSellingPrice;
        (p['rateController'] as TextEditingController).text = selectedProduct
            .batchSellingPrice
            .toString();
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

  Future<double> _resolveGstPercent(BatchListItem batch) async {
    final cached = productService.getProductByIdFromCache(batch.batchProductId);
    if (cached != null) return cached.prodGSTPercent;
    try {
      await productService.getAllProducts(isActive: true);
      final loaded = productService.getProductByIdFromCache(batch.batchProductId);
      if (loaded != null) return loaded.prodGSTPercent;
    } catch (_) {}
    return batch.prodGSTPercent;
  }

  String _unitValueFor(BatchListItem batch) {
    final cached = productService.getProductByIdFromCache(batch.batchProductId);
    if (cached != null) return cached.formattedUnitValue;
    return batch.formattedUnitValue;
  }

  void _addProductFromButton() {
    if (_products.last['product'] != null) {
      setState(() {
        _addNewEmptyRow();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        (_products.last['productNode'] as FocusNode).requestFocus();
        _selectProductForEmptyRow(_products.length - 1);
      }
    });
  }

  void _removeProduct(int index) {
    if (_products.length == 1) {
      // Don't remove the last row, just clear it
      final p = _products[index];
      setState(() {
        p['product'] = null;
        p['qty'] = 1.0;
        p['rate'] = 0.0;
        p['discPct'] = 0.0;
        p['discAmt'] = 0.0;
        p['gstPct'] = 0.0;
        (p['qtyController'] as TextEditingController).text = '1.0';
        (p['rateController'] as TextEditingController).text = '0.0';
        (p['discPctController'] as TextEditingController).text = '0';
        (p['discAmtController'] as TextEditingController).text = '0.0';
      });
    } else {
      setState(() {
        final removed = _products.removeAt(index);
        (removed['qtyController'] as TextEditingController).dispose();
        (removed['rateController'] as TextEditingController).dispose();
        (removed['discPctController'] as TextEditingController).dispose();
        (removed['discAmtController'] as TextEditingController).dispose();
        (removed['productNode'] as FocusNode).dispose();
        (removed['qtyNode'] as FocusNode).dispose();
        (removed['rateNode'] as FocusNode).dispose();
        (removed['discPctNode'] as FocusNode).dispose();
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
    // After date, move focus to first product row
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _products.isNotEmpty) {
        (_products.first['productNode'] as FocusNode).requestFocus();
      }
    });
  }

  bool _isInterstateSale(CompanyListItem? company, CustomerListItem? customer) {
    final companyGst = (company?.compGSTNo ?? '').trim().toUpperCase();
    final customerGst = (customer?.custGSTNo ?? '').trim().toUpperCase();
    if (companyGst.length >= 2 && customerGst.length >= 2) {
      return companyGst.substring(0, 2) != customerGst.substring(0, 2);
    }

    final companyState = (company?.compState ?? '').trim().toLowerCase();
    final customerState =
        (customer?.custStateName.isNotEmpty == true
                ? customer!.custStateName
                : (customer?.custState ?? ''))
            .trim()
            .toLowerCase();
    if (companyState.isNotEmpty && customerState.isNotEmpty) {
      return companyState != customerState;
    }

    return false;
  }

  Future<void> _saveEntry() async {
    if (_isViewMode) {
      await showWarningDialog(context, 'Cannot save in view mode. Please click Clear to start a new entry.');
      return;
    }
    if (_isLoading) return;
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

    if (!mounted) return;

    SalePersistResult? savedResult;
    final payment = await showPaymentModeDialog(
      context,
      payableAmount: _finalPayable,
      onConfirm: (details) async {
        try {
          savedResult = await _persistSalesReturn(details);
          return true;
        } catch (e) {
          if (mounted) {
            await showErrorDialog(context, e.toString());
          }
          return false;
        }
      },
    );

    final result = savedResult;
    if (payment == null || result == null || !mounted) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // No PDF generation for sales return yet, just show success dialog
      if (!mounted) return;
      _resetForm();
      await showSuccessDialog(context, 'Sales Return saved successfully.');
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Error after saving: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<SalePersistResult> _persistSalesReturn(
    SalesPaymentDetails payment,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final validProducts = _products
          .where((p) => p['product'] != null)
          .toList();
      final user = await sessionService.getUserData();
      int compId = sessionService.selectedCompId ?? 1;
      int branchId = sessionService.selectedBranchId ?? 1;
      int empId = user?.empId ?? 1;

      CustomerListItem? customer;
      try {
        customer = _customerService.customers.firstWhere(
          (c) => c.custId == _selectedCustomer,
        );
      } catch (_) {
        customer = null;
      }

      final company = companyService.getCompanyById(compId);
      final isInterstate = _isInterstateSale(company, customer);

      final detailData = validProducts.map((p) {
        final BatchListItem prod = p['product'];
        final double qty = (p['qty'] as num?)?.toDouble() ?? 0;
        final double rate = (p['rate'] as num?)?.toDouble() ?? 0;
        final double discAmt = (p['discAmt'] as num?)?.toDouble() ?? 0;
        final double gstPct = (p['gstPct'] as num?)?.toDouble() ?? 0;
        final double gstAmt = (p['gstAmt'] as num?)?.toDouble() ?? 0;
        final double taxable = (p['discounted'] as num?)?.toDouble() ?? 0;
        final double net = (p['net'] as num?)?.toDouble() ?? 0;
        final double gross = qty * rate;
        final double discPct = (p['discPct'] as num?)?.toDouble() ?? (gross > 0 ? (discAmt / gross) * 100 : 0);

        return SalesReturnDetailData(
          productId: prod.batchProductId,
          batchId: prod.batchId,
          unitId: productService.getProductByIdFromCache(prod.batchProductId)?.prodUnitId ?? 0,
          qty: qty,
          freeQty: 0,
          sellingPrice: rate,
          mrp: rate,
          discountPercentage: discPct,
          discountAmount: discAmt,
          taxPercentage: gstPct,
          taxAmount: gstAmt,
          subTotal: taxable,
          totalAmount: net,
          remark: '',
          isActive: true,
          modifiedBy: empId,
        );
      }).toList();

      final totalQty = detailData.fold<double>(0, (s, d) => s + d.qty);

      final paidAmount = payment.paidAmountFor(_finalPayable);
      final balanceAmount = payment.balanceAmountFor(_finalPayable);

      final masterData = SalesReturnMasterData(
        salesReturnMasterId: 0,
        compId: compId,
        branchId: branchId,
        customerId: _selectedCustomer!,
        ledgerId: customer?.custLedgerId ?? 0,
        date: _selectedDate.toIso8601String(),
        totalQty: totalQty,
        subTotal: _grossTotal,
        discountAmount: _totalProductDiscount + _billDiscount,
        taxAmount: _totalGST,
        billWiseDiscountPercentage: double.tryParse(_billDiscountPctController.text) ?? 0.0,
        billWiseDiscountAmount: double.tryParse(_billDiscountController.text) ?? 0.0,
        grandTotal: _finalPayable,
        paidAmount: paidAmount,
        balanceAmount: balanceAmount,
        cashAmount: payment.cashAmount,
        upiAmount: payment.upiAmount,
        chequeAmount: payment.chequeAmount,
        creditAmount: payment.creditAmount,
        status: 'Completed',
        remark: payment.remark,
        isActive: true,
        createdBy: empId,
        modifiedBy: empId,
      );

      final request = SalesReturnUpsertRequest(
        masterData: masterData,
        detailData: detailData,
      );

      final response = await SalesReturnService().insertOrUpdateSalesReturnEntry(
        request,
      );
      final productRows = validProducts
          .map((p) => Map<String, dynamic>.from(p))
          .toList();

      return SalePersistResult(
        salesResponse: response,
        masterData: masterData,
        detailData: detailData,
        productRows: productRows,
        payment: payment,
        customer: customer,
        company: company,
        user: user,
      );
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
      _isViewMode = false;
      _billDiscountController.text = '0';
      _billDiscountPctController.text = '0';
      _selectedCustomer = null;

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

    if (fieldName == 'product' &&
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space)) {
      _selectProductForEmptyRow(index);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) {
        (_products[index - 1]['${fieldName}Node'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (index < _products.length - 1) {
        (_products[index + 1]['${fieldName}Node'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      }
    }

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

    const double colProductName = 260;
    const double colQty = 100;
    const double colRate = 120;
    const double colGross = 100;
    const double colDiscPct = 80;
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
        colDiscPct +
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
                            buildHeaderCell(
                              'Selling Price',
                              colRate,
                              isNumeric: true,
                            ),
                            buildHeaderCell('Gross', colGross, isNumeric: true),
                            buildHeaderCell(
                              'Disc (%)',
                              colDiscPct,
                              isNumeric: true,
                            ),
                            buildHeaderCell(
                              'Discount',
                              colDiscount,
                              isNumeric: true,
                            ),
                            buildHeaderCell(
                              'GST %',
                              colGstPct,
                              isNumeric: true,
                            ),
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
                          final BatchListItem? prod = p['product'];
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
                              (node, event) => _handleGridKeyEvent(
                                node,
                                event,
                                index,
                                'qty',
                              );
                          (p['rateNode'] as FocusNode).onKeyEvent =
                              (node, event) => _handleGridKeyEvent(
                                node,
                                event,
                                index,
                                'rate',
                              );
                          (p['discNode'] as FocusNode).onKeyEvent =
                              (node, event) => _handleGridKeyEvent(
                                node,
                                event,
                                index,
                                'disc',
                              );

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
                                key: ValueKey(
                                  prod?.batchProductId ?? 'empty_$index',
                                ),
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
                                                _selectProductForEmptyRow(
                                                  index,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isFocused
                                                      ? theme
                                                            .colorScheme
                                                            .primary
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
                                                          color:
                                                              theme.hintColor,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Select Product (Enter)',
                                                          style: TextStyle(
                                                            color:
                                                                theme.hintColor,
                                                            fontStyle: FontStyle
                                                                .italic,
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
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          'Unit: ${prod.unitName} | Unit Value: ${_unitValueFor(prod)}',
                                                          style: TextStyle(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    effectiveProductNameWidth,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                  ),
                                  buildDataCell(
                                    TextFormField(
                                      controller: p['qtyController'],
                                      focusNode: p['qtyNode'],
                                      enabled: !isEmptyRow,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d*'),
                                        ),
                                      ],
                                      decoration: _gridInputDecoration(theme),
                                      onChanged: (val) {
                                        p['qty'] = double.tryParse(val) ?? 0.0;
                                        _calculateTotals();
                                      },
                                      onFieldSubmitted: (_) =>
                                          (p['rateNode'] as FocusNode)
                                              .requestFocus(),
                                    ),
                                    colQty,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                  ),
                                  buildDataCell(
                                    TextFormField(
                                      controller: p['rateController'],
                                      focusNode: p['rateNode'],
                                      enabled: !isEmptyRow,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d*'),
                                        ),
                                      ],
                                      decoration: _gridInputDecoration(theme),
                                      onChanged: (val) {
                                        final newRate =
                                            double.tryParse(val) ?? 0.0;
                                        p['rate'] = newRate;
                                        if (newRate <= 0.0) {
                                          p['discAmt'] = 0.0;
                                          (p['discAmtController']
                                                      as TextEditingController)
                                                  .text =
                                              '0.0';
                                        }
                                        _calculateTotals();
                                      },
                                      onFieldSubmitted: (_) {
                                        if ((p['rate'] ?? 0.0) > 0.0) {
                                          (p['discPctNode'] as FocusNode)
                                              .requestFocus();
                                        } else {
                                          if (index == _products.length - 1) {
                                            setState(() {
                                              _addNewEmptyRow();
                                            });
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    final newNode =
                                                        _products
                                                                .last['productNode']
                                                            as FocusNode;
                                                    newNode.requestFocus();
                                                  }
                                                });
                                          } else {
                                            (_products[index + 1]['productNode']
                                                    as FocusNode)
                                                .requestFocus();
                                          }
                                        }
                                      },
                                    ),
                                    colRate,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                  ),
                                  buildDataCell(
                                    Text(
                                      isEmptyRow
                                          ? '-'
                                          : (p['gross'] as double)
                                                .toStringAsFixed(2),
                                      style: TextStyle(
                                        color: isEmptyRow
                                            ? theme.hintColor
                                            : null,
                                      ),
                                    ),
                                    colGross,
                                    isNumeric: true,
                                  ),
                                  buildDataCell(
                                    TextFormField(
                                      controller: p['discPctController'],
                                      focusNode: p['discPctNode'],
                                      enabled:
                                          !isEmptyRow &&
                                          (p['rate'] ?? 0.0) > 0.0,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d*'),
                                        ),
                                      ],
                                      decoration: _gridInputDecoration(theme),
                                      onChanged: (val) {
                                        p['discPct'] =
                                            double.tryParse(val) ?? 0.0;
                                        _calculateTotals();
                                      },
                                      onFieldSubmitted: (_) {
                                        (p['discNode'] as FocusNode).requestFocus();
                                      },
                                    ),
                                    colDiscPct,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                  ),
                                  buildDataCell(
                                    TextFormField(
                                      controller: p['discAmtController'],
                                      focusNode: p['discNode'],
                                      enabled:
                                          !isEmptyRow &&
                                          (p['rate'] ?? 0.0) > 0.0,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d*'),
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
                                                  final newNode =
                                                      _products
                                                              .last['productNode']
                                                          as FocusNode;
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
                                    colDiscount,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                  ),
                                  buildDataCell(
                                    Text(
                                      isEmptyRow
                                          ? '-'
                                          : ((p['gstPct'] as num?)
                                                      ?.toDouble() ??
                                                  0)
                                              .toStringAsFixed(2),
                                      style: TextStyle(
                                        color: isEmptyRow
                                            ? theme.hintColor
                                            : null,
                                      ),
                                    ),
                                    colGstPct,
                                    isNumeric: true,
                                  ),
                                  buildDataCell(
                                    Text(
                                      isEmptyRow
                                          ? '-'
                                          : ((p['gstAmt'] as num?)
                                                      ?.toDouble() ??
                                                  0)
                                              .toStringAsFixed(2),
                                      style: TextStyle(
                                        color: isEmptyRow
                                            ? theme.hintColor
                                            : null,
                                      ),
                                    ),
                                    colGstAmt,
                                    isNumeric: true,
                                  ),
                                  buildDataCell(
                                    Text(
                                      isEmptyRow
                                          ? '-'
                                          : (p['net'] as double)
                                                .toStringAsFixed(2),
                                      style: TextStyle(
                                        fontWeight: isEmptyRow
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        fontSize: isEmptyRow ? 14 : 15,
                                        color: isEmptyRow
                                            ? theme.hintColor
                                            : null,
                                      ),
                                    ),
                                    colNet,
                                    isNumeric: true,
                                  ),
                                  buildDataCell(
                                    isEmptyRow
                                        ? const SizedBox.shrink()
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Remove',
                                            splashRadius: 20,
                                            onPressed: () =>
                                                _removeProduct(index),
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
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1000;
    final bool isMobile = screenWidth < 600;

    Widget content = SaveClearShortcuts(
      onSave: () {
        if (!_isLoading) _saveEntry();
      },
      onClear: _resetForm,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 280,
                      child: CustomerDropdown(
                        focusNode: _customerNode,
                        nextFocusNode: _invoiceDateNode,
                        selectedCustomerId: _selectedCustomer,
                        isRequired: true,
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomer = val?.custId;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 220,
                      child: Focus(
                        focusNode: _invoiceDateNode,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.numpadEnter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.space)) {
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
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                isFocused: isFocused,
                                decoration: InputDecoration(
                                  labelText: 'Return Date',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                child: Text(_dateFormat.format(_selectedDate)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Items (${_products.where((p) => p['product'] != null).length})',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          FilledButton.icon(
                            onPressed: _addProductFromButton,
                            icon: const Icon(Icons.add_shopping_cart, size: 20),
                            label: const Text(
                              'Add Product',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildProductTable()),
                  ],
                ),
              ),
            ),
            // Footer totals
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildSummaryItem(
                          'Total Qty',
                          _totalQuantity.toStringAsFixed(2),
                        ),
                        _buildSummaryItem(
                          'Gross Total',
                          '₹${_grossTotal.toStringAsFixed(2)}',
                        ),
                        _buildSummaryItem(
                          'Prod. Discount',
                          '₹${_totalProductDiscount.toStringAsFixed(2)}',
                        ),
                        _buildSummaryItem(
                          'Total GST',
                          '₹${_totalGST.toStringAsFixed(2)}',
                        ),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _billDiscountPctController,
                            focusNode: _billDiscountPctNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Bill Dis %',
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: '%',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _billDiscountController,
                            focusNode: _billDiscountAmtNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Bill Discount',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Final Payable',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '₹${_finalPayable.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isViewMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _resetForm,
                                  icon: const Icon(Icons.clear_all_rounded),
                                  label: const Text(
                                    'Clear',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 200,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _isLoading ? null : _saveEntry,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(
                                _isLoading ? 'Saving...' : 'Save Return',
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return isDesktop
        ? Scaffold(
            body: Row(
              children: [
                const AppDrawer(),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        title: const Text('Add Sales Return'),
                        elevation: 0,
                        actions: [
                          TextButton.icon(
                            onPressed: _openSalesReturnView,
                            icon: const Icon(Icons.list),
                            label: const Text('View'),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Add Sales Return'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: _openSalesReturnView,
                  tooltip: 'View Sales Returns',
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: content,
          );
  }

  Future<void> _openSalesReturnView() async {
    final selectedEntry = await Navigator.of(context).push<SalesReturnMasterDataListItem>(
      MaterialPageRoute(builder: (context) => const SalesReturnViewList()),
    );
    if (selectedEntry != null) {
      _loadSalesReturnEntry(selectedEntry);
    }
  }

  Future<void> _loadSalesReturnEntry(SalesReturnMasterDataListItem master) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final int masterId = master.raw['salesReturnMaster_Id'] ?? 0;
      final detailsResponse = await SalesReturnService().getSalesReturnDetailList(masterId);
      
      if (!mounted) return;

      setState(() {
        _isViewMode = true;
        _selectedCustomer = master.raw['salesReturnMaster_CustomerId'];
        if (master.raw['salesReturnMaster_Date'] != null) {
          final dateStr = master.raw['salesReturnMaster_Date'].toString();
          _selectedDate = DateTime.tryParse(dateStr) ?? _selectedDate;
        }
        
        final pctStr = ((master.raw['salesReturnMaster_BillWiseDiscountPercentage'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        final amtStr = ((master.raw['salesReturnMaster_BillWiseDiscountAmount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        _billDiscountPctController.text = pctStr;
        _billDiscountController.text = amtStr;

        // Clear existing products
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

        // Load details
        for (final detail in detailsResponse.data) {
          final raw = detail.raw;
          final batchId = raw['salesReturnDetail_BatchId'] ?? 0;
          final productId = raw['salesReturnDetail_ProductId'] ?? 0;

          // Find batch
          BatchListItem? batch;
          try {
            batch = _batchService.batches.firstWhere((b) => b.batchId == batchId);
          } catch (_) {
            // Try to find by productId if batch not found (fallback)
            try {
               batch = _batchService.batches.firstWhere((b) => b.batchProductId == productId);
            } catch (_) {}
          }
          
          if (batch == null) {
             // Create dummy batch if not found to show data
             batch = BatchListItem(
                batchId: batchId,
                batchProductId: productId,
                batchBarcode: raw['salesReturnDetail_Barcode']?.toString() ?? '',
                batchEANCode: raw['salesReturnDetail_EANCode']?.toString() ?? '',
                batchLandingPrice: 0,
                batchPurchasePrice: 0,
                batchMRP: 0,
                batchSellingPrice: (raw['salesReturnDetail_SellingPrice'] as num?)?.toDouble() ?? 0,
                batchStock: 0,
                batchAvailableStock: 0,
                prodCode: raw['prod_Code']?.toString() ?? '',
                prodName: raw['prod_Name']?.toString() ?? raw['salesReturnDetail_ProductName']?.toString() ?? '',
                prodGSTPercent: (raw['salesReturnDetail_TaxPercentage'] as num?)?.toDouble() ?? 0,
                unitName: raw['unit_ShortName']?.toString() ?? '',
                prodUnitValue: 1.0,
                batchCompId: 0,
                compName: '',
                batchBranchId: 0,
                branchName: '',
             );
          }

          final qty = (raw['salesReturnDetail_Qty'] as num?)?.toDouble() ?? 0.0;
          final rate = (raw['salesReturnDetail_SellingPrice'] as num?)?.toDouble() ?? 0.0;
          final discAmt = (raw['salesReturnDetail_DiscountAmount'] as num?)?.toDouble() ?? 0.0;
          final discPct = (raw['salesReturnDetail_DiscountPercentage'] as num?)?.toDouble() ?? 0.0;
          final gstPct = (raw['salesReturnDetail_TaxPercentage'] as num?)?.toDouble() ?? 0.0;
          
          _products.add({
            'product': batch,
            'qty': qty,
            'rate': rate,
            'discPct': discPct,
            'discAmt': discAmt,
            'gstPct': gstPct,
            'gross': 0.0,
            'discounted': 0.0,
            'gstAmt': 0.0,
            'net': 0.0,
            'qtyController': TextEditingController(text: qty.toString()),
            'rateController': TextEditingController(text: rate.toString()),
            'discPctController': TextEditingController(text: discPct.toString()),
            'discAmtController': TextEditingController(text: discAmt.toString()),
            'productNode': FocusNode(),
            'qtyNode': FocusNode(),
            'rateNode': FocusNode(),
            'discPctNode': FocusNode(),
            'discNode': FocusNode(),
          });
        }
        
        // Add empty row at end if there are products
        if (_products.isNotEmpty) {
           _addNewEmptyRow();
        } else {
           _addNewEmptyRow();
        }

        _calculateTotals();
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Failed to load details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}


