import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/batch.dart';
import '../../../models/product.dart';
import '../../../models/purchase_return.dart';
import '../../../models/supplier.dart';
import '../../../models/company.dart';
import '../../../models/login_response.dart';
import '../../../services/purchase_return_service.dart';
import '../../../services/supplier_service.dart';
import '../../../services/company_service.dart';
import '../../../services/batch_service.dart';
import '../../../services/product_service.dart';
import '../../../services/session_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_message_dialog.dart';
import '../../../widgets/supplier_dropdown.dart';
import '../../sales/sales_entry/batch_selection_dialog.dart';
import '../../purchases/purchase_entry/product_selection_dialog.dart';
import '../../../widgets/save_clear_shortcuts.dart';
import '../../../services/shortcut_service.dart';
import 'purchase_return_list_screen.dart';

class PurchasePersistResult {
  final PurchaseReturnUpsertResponse purchaseResponse;
  final PurchaseReturnMasterData masterData;
  final List<PurchaseReturnDetailData> detailData;
  final List<Map<String, dynamic>> productRows;
  final SupplierListItem? supplier;
  final CompanyListItem? company;
  final UserData? user;

  const PurchasePersistResult({
    required this.purchaseResponse,
    required this.masterData,
    required this.detailData,
    required this.productRows,
    this.supplier,
    this.company,
    this.user,
  });
}

class AddPurchaseReturnScreen extends StatefulWidget {
  const AddPurchaseReturnScreen({super.key});

  @override
  State<AddPurchaseReturnScreen> createState() => _AddPurchaseReturnScreenState();
}

class _AddPurchaseReturnScreenState extends State<AddPurchaseReturnScreen> {
  final _formKey = GlobalKey<FormState>();

  // Focus Nodes for Main Fields
  final _invoiceDateNode = FocusNode();
  final _supplierNode = FocusNode();

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
  int? _selectedSupplier;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final List<Map<String, dynamic>> _products = [];
  final ScrollController _listScrollController = ScrollController();

  double _totalQuantity = 0.0;
  double _grossTotal = 0.0;
  double _totalProductDiscount = 0.0;
  double _totalGST = 0.0;
  double _billDiscount = 0.0;
  double _finalPayable = 0.0;

  bool _isLoading = false;
  bool _isViewMode = false;

  final SupplierService _supplierService = supplierService;
  final BatchService _batchService = batchService;

  @override
  void initState() {
    super.initState();
    _supplierService.getAllSuppliers();
    _batchService.getAllBatches();
    _billDiscountPctController.addListener(_calculateTotals);
    _billDiscountController.addListener(_calculateTotals);

    // Auto-add first empty row
    _addNewEmptyRow();

    // Focus supplier on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _supplierNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateEscBehavior();
  }

  void _updateEscBehavior() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null) return;

    final hasProducts = _products.any((p) => p['product'] != null);
    if (_isViewMode || !hasProducts) {
      shortcutService.registerDirectBackRoute(route);
    } else {
      shortcutService.unregisterDirectBackRoute(route);
    }
  }

  void _addNewEmptyRow() {
    _products.add({
      'product': null,
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
    _supplierNode.dispose();
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
    _listScrollController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double totalQty = 0;
    double grossTotal = 0;
    double totalProdDisc = 0;
    double totalGST = 0;
    double subTotal = 0;

    for (var p in _products) {
      if (p['product'] == null) continue;

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

    _updateEscBehavior();
  }

  Future<void> _selectProductForEmptyRow(int index) async {
    final selectedProductItem = await showDialog<ProductListItem>(
      context: context,
      builder: (context) => const ProductSelectionDialog(),
    );

    if (selectedProductItem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          (_products[index]['productNode'] as FocusNode).requestFocus();
        }
      });
      return;
    }

    if (!mounted) return;

    final selectedProduct = await showDialog<BatchListItem>(
      context: context,
      builder: (context) => BatchSelectionDialog(productId: selectedProductItem.prodId),
    );

    if (selectedProduct != null) {
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
        p['rate'] = selectedProduct.batchPurchasePrice;
        (p['rateController'] as TextEditingController).text = selectedProduct
            .batchPurchasePrice
            .toString();
      });
      _calculateTotals();

      if (index == _products.length - 1) {
        setState(() {
          _addNewEmptyRow();
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            (_products[index]['qtyNode'] as FocusNode).requestFocus();
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted && _listScrollController.hasClients) {
                _listScrollController.animateTo(
                  _listScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            (_products[index]['qtyNode'] as FocusNode).requestFocus();
          }
        });
      }
    } else {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _products.isNotEmpty) {
        (_products.first['productNode'] as FocusNode).requestFocus();
      }
    });
  }

  bool _isInterstatePurchase(CompanyListItem? company, SupplierListItem? supplier) {
    final companyGst = (company?.compGSTNo ?? '').trim().toUpperCase();
    final supplierGst = (supplier?.suppGSTNo ?? '').trim().toUpperCase();
    if (companyGst.length >= 2 && supplierGst.length >= 2) {
      return companyGst.substring(0, 2) != supplierGst.substring(0, 2);
    }

    final companyState = (company?.compState ?? '').trim().toLowerCase();
    final supplierState = (supplier?.suppStateName ?? '').trim().toLowerCase();
    if (companyState.isNotEmpty && supplierState.isNotEmpty) {
      return companyState != supplierState;
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
    if (_selectedSupplier == null) {
      await showWarningDialog(context, 'Please select a supplier');
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

    PurchasePersistResult? savedResult;
    try {
      savedResult = await _persistPurchaseReturn();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
      return;
    }

    final result = savedResult;
    if (result == null || !mounted) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      if (!mounted) return;
      _resetForm();
      await showSuccessDialog(context, 'Purchase Return saved successfully.\nReturn No: ${result.purchaseResponse.data?.returnNo ?? ''}');
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

  Future<PurchasePersistResult> _persistPurchaseReturn() async {
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

      SupplierListItem? supplier;
      try {
        supplier = _supplierService.suppliers.firstWhere(
          (s) => s.suppId == _selectedSupplier,
        );
      } catch (_) {
        supplier = null;
      }

      final company = companyService.getCompanyById(compId);

      final detailData = validProducts.map((p) {
        final BatchListItem prod = p['product'];
        final double qty = (p['qty'] as num?)?.toDouble() ?? 0;
        final double rate = (p['rate'] as num?)?.toDouble() ?? 0;
        final double discAmt = (p['discAmt'] as num?)?.toDouble() ?? 0;
        final double gstPct = (p['gstPct'] as num?)?.toDouble() ?? 0;
        final double gstAmt = (p['gstAmt'] as num?)?.toDouble() ?? 0;
        final double net = (p['net'] as num?)?.toDouble() ?? 0;
        final double gross = qty * rate;
        final double discPct = (p['discPct'] as num?)?.toDouble() ?? (gross > 0 ? (discAmt / gross) * 100 : 0);

        return PurchaseReturnDetailData(
          productId: prod.batchProductId,
          batchId: prod.batchId,
          qty: qty,
          landingPrice: prod.batchLandingPrice,
          purchasePrice: rate,
          mrp: prod.batchMRP,
          sellingPrice: prod.batchSellingPrice,
          discountPercent: discPct,
          discountAmount: discAmt,
          gstPercent: gstPct,
          gstAmount: gstAmt,
          totalAmount: net,
          createdBy: empId,
        );
      }).toList();

      final paidAmount = 0.0;
      final balanceAmount = _finalPayable;

      final masterData = PurchaseReturnMasterData(
        purchaseReturnMasterId: 0,
        compId: compId,
        branchId: branchId,
        supplierId: _selectedSupplier!,
        ledgerId: supplier?.suppLedgerId ?? 0,
        returnDate: _selectedDate.toIso8601String(),
        subTotal: _grossTotal,
        discountAmount: _totalProductDiscount,
        billWiseDiscountPercentage: double.tryParse(_billDiscountPctController.text) ?? 0.0,
        billWiseDiscountAmount: double.tryParse(_billDiscountController.text) ?? 0.0,
        gstAmount: _totalGST,
        otherCharges: 0,
        netAmount: _finalPayable,
        refundAmount: paidAmount,
        balanceAmount: balanceAmount,
        status: 'Completed',
        remark: '',
        createdBy: empId,
        modifiedBy: empId,
      );

      final request = PurchaseReturnUpsertRequest(
        masterData: masterData,
        detailData: detailData,
      );

      final response = await PurchaseReturnService().insertOrUpdatePurchaseReturnEntry(
        request,
      );
      final productRows = validProducts
          .map((p) => Map<String, dynamic>.from(p))
          .toList();

      return PurchasePersistResult(
        purchaseResponse: response,
        masterData: masterData,
        detailData: detailData,
        productRows: productRows,
        supplier: supplier,
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
      _selectedSupplier = null;

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
      _products.clear();
      _addNewEmptyRow();

      _selectedDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      _calculateTotals();
    });
    
    _batchService.getAllBatches();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _supplierNode.requestFocus();
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
      if (p['product'] != null) {
        (p['qtyNode'] as FocusNode).requestFocus();
      } else {
        _selectProductForEmptyRow(index);
      }
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
        (p['discPctNode'] as FocusNode).requestFocus();
        return KeyEventResult.handled;
      } else if (fieldName == 'discPct') {
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
          (p['discPctNode'] as FocusNode).requestFocus();
        } else if (index < _products.length - 1) {
          (_products[index + 1]['productNode'] as FocusNode).requestFocus();
        }
        return KeyEventResult.handled;
      } else if (fieldName == 'discPct') {
        (p['discNode'] as FocusNode).requestFocus();
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
                              'Purchase Price',
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
                        controller: _listScrollController,
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
                          (p['discPctNode'] as FocusNode).onKeyEvent =
                              (node, event) => _handleGridKeyEvent(
                                node,
                                event,
                                index,
                                'discPct',
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
                              p['discPctNode'] as FocusNode,
                              p['discNode'] as FocusNode,
                            ]),
                            builder: (context, child) {
                              final isRowFocused =
                                  (p['productNode'] as FocusNode).hasFocus ||
                                  (p['qtyNode'] as FocusNode).hasFocus ||
                                  (p['rateNode'] as FocusNode).hasFocus ||
                                  (p['discPctNode'] as FocusNode).hasFocus ||
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
                                            onTap: () {
                                              if (p['product'] != null) {
                                                (p['qtyNode'] as FocusNode).requestFocus();
                                              } else {
                                                _selectProductForEmptyRow(index);
                                              }
                                            },
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
                                                          'Unit Value : ${_unitValueFor(prod)} ${prod.unitName}',
                                                          style: TextStyle(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontSize: 14,
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
                                          if (index < _products.length - 1) {
                                            (_products[index + 1]['productNode'] as FocusNode).requestFocus();
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
                                        if (index < _products.length - 1) {
                                          (_products[index + 1]['productNode'] as FocusNode).requestFocus();
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
                      child: SupplierDropdown(
                        focusNode: _supplierNode,
                        nextFocusNode: _invoiceDateNode,
                        selectedSupplierId: _selectedSupplier,
                        onChanged: (val) {
                          setState(() {
                            _selectedSupplier = val?.suppId;
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
                      spacing: 16,
                      runSpacing: 10,
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
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${_finalPayable.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(width: 8),
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
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton(
                                  onPressed: _resetForm,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ), child: const Text(
                                  'Clear (F10)',
                                  style: TextStyle(fontSize: 16),
                                ),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 140,
                            height: 40,
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
                                _isLoading ? 'Saving...' : 'Save (F9)',
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
                        title: const Text('Add Purchase Return'),
                        elevation: 0,
                        actions: [
                          TextButton.icon(
                            onPressed: _openPurchaseReturnView,
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
              title: const Text('Add Purchase Return'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: _openPurchaseReturnView,
                  tooltip: 'View Purchase Returns',
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: content,
          );
  }

  Future<void> _openPurchaseReturnView() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PurchaseReturnListScreen()),
    );
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
