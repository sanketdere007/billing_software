import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../utils/platform_helper.dart';

class SalesPaymentMode {
  static const cash = 'Cash';
  static const upi = 'UPI';
  static const cheque = 'Cheque';
  static const bank = 'Bank';
  static const card = 'Card';
  static const other = 'Other';
  static const credit = 'Credit';

  static const List<String> all = [
    cash,
    upi,
    cheque,
    bank,
    card,
    other,
    credit,
  ];
}

class SalesPaymentDetails {
  final Map<String, double> amounts;
  final String cashRemark;
  final String upiTransactionNo;
  final String upiReferenceNo;
  final String chequeNo;
  final DateTime? chequeDate;
  final String chequeRemark;
  final String bankName;
  final String bankReferenceNo;
  final String neftType;
  final String neftReferenceNo;
  final String cardRemark;
  final String otherType;
  final String otherReferenceNo;
  final DateTime? otherDate;
  final String otherRemark;
  final String creditRemark;

  SalesPaymentDetails({
    String? mode,
    double amount = 0,
    Map<String, double>? amounts,
    this.cashRemark = '',
    this.upiTransactionNo = '',
    this.upiReferenceNo = '',
    this.chequeNo = '',
    this.chequeDate,
    this.chequeRemark = '',
    this.bankName = '',
    this.bankReferenceNo = '',
    this.neftType = '',
    this.neftReferenceNo = '',
    this.cardRemark = '',
    this.otherType = '',
    this.otherReferenceNo = '',
    this.otherDate,
    this.otherRemark = '',
    this.creditRemark = '',
  }) : amounts = Map.unmodifiable(
         amounts ?? (mode != null ? {mode: amount} : const <String, double>{}),
       );

  /// Primary mode: the only mode used, or `Split` when more than one has an amount.
  String get mode {
    final active = amounts.entries.where((e) => e.value > 0).toList();
    if (active.isEmpty) return '';
    if (active.length == 1) return active.first.key;
    return 'Split';
  }

  double get amount =>
      amounts.values.fold<double>(0, (sum, value) => sum + value);

  bool get isSplit => amounts.entries.where((e) => e.value > 0).length > 1;

  double get collectedAmount {
    double total = 0;
    amounts.forEach((mode, value) {
      if (mode != SalesPaymentMode.credit) total += value;
    });
    return total;
  }

  double get cashAmount => amounts[SalesPaymentMode.cash] ?? 0;
  double get upiAmount => amounts[SalesPaymentMode.upi] ?? 0;
  double get chequeAmount => amounts[SalesPaymentMode.cheque] ?? 0;
  double get bankAmount => amounts[SalesPaymentMode.bank] ?? 0;
  double get cardAmount => amounts[SalesPaymentMode.card] ?? 0;
  double get otherAmount => amounts[SalesPaymentMode.other] ?? 0;
  double get creditAmount => amounts[SalesPaymentMode.credit] ?? 0;

  String get otherPaymentType {
    if (otherAmount > 0) {
      return otherType.trim().isNotEmpty
          ? otherType.trim()
          : SalesPaymentMode.other;
    }
    if (creditAmount > 0) return SalesPaymentMode.credit;
    return '';
  }

  String get remark {
    final parts = <String>[];
    if (cashRemark.trim().isNotEmpty) parts.add(cashRemark.trim());
    if (upiTransactionNo.trim().isNotEmpty) {
      parts.add('UPI Txn: ${upiTransactionNo.trim()}');
    }
    if (upiReferenceNo.trim().isNotEmpty) {
      parts.add('UPI Ref: ${upiReferenceNo.trim()}');
    }
    if (chequeRemark.trim().isNotEmpty) parts.add(chequeRemark.trim());
    if (cardRemark.trim().isNotEmpty) parts.add(cardRemark.trim());
    if (creditRemark.trim().isNotEmpty) parts.add(creditRemark.trim());
    return parts.join(' | ');
  }

  double paidAmountFor(double grandTotal) {
    if (collectedAmount > grandTotal) return grandTotal;
    return collectedAmount < 0 ? 0 : collectedAmount;
  }

  double balanceAmountFor(double grandTotal) {
    final balance = grandTotal - paidAmountFor(grandTotal);
    return balance < 0 ? 0 : balance;
  }
}

Future<SalesPaymentDetails?> showPaymentModeDialog(
  BuildContext context, {
  required double payableAmount,
  Future<bool> Function(SalesPaymentDetails details)? onConfirm,
}) {
  return showDialog<SalesPaymentDetails>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        PaymentModeDialog(payableAmount: payableAmount, onConfirm: onConfirm),
  );
}

class PaymentModeDialog extends StatefulWidget {
  final double payableAmount;
  final Future<bool> Function(SalesPaymentDetails details)? onConfirm;

  const PaymentModeDialog({
    super.key,
    required this.payableAmount,
    this.onConfirm,
  });

  @override
  State<PaymentModeDialog> createState() => _PaymentModeDialogState();
}

class _PaymentModeDialogState extends State<PaymentModeDialog> {
  static const _modes = SalesPaymentMode.all;
  static const _epsilon = 0.01;
  static const _bankTransferTypes = ['NEFT', 'RTGS', 'IMPS', 'Fund Transfer'];
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  final _cashRemarkController = TextEditingController();
  final _upiTxnController = TextEditingController();
  final _upiRefController = TextEditingController();
  final _chequeNoController = TextEditingController();
  final _chequeRemarkController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankRefController = TextEditingController();
  final _neftRefController = TextEditingController();
  final _cardRemarkController = TextEditingController();
  final _otherTypeController = TextEditingController();
  final _otherRefController = TextEditingController();
  final _otherRemarkController = TextEditingController();
  final _creditRemarkController = TextEditingController();

  late final FocusNode _cashRemarkNode;
  late final FocusNode _upiTxnNode;
  late final FocusNode _upiRefNode;
  late final FocusNode _chequeNoNode;
  late final FocusNode _chequeDateNode;
  late final FocusNode _chequeRemarkNode;
  late final FocusNode _neftTypeNode;
  late final FocusNode _bankNameNode;
  late final FocusNode _bankRefNode;
  late final FocusNode _neftRefNode;
  late final FocusNode _cardRemarkNode;
  late final FocusNode _otherTypeNode;
  late final FocusNode _otherRefNode;
  late final FocusNode _otherDateNode;
  late final FocusNode _otherRemarkNode;
  late final FocusNode _creditRemarkNode;

  DateTime? _chequeDate;
  DateTime? _otherDate;
  String? _neftType;

  bool _isSubmitting = false;
  bool _hasClosed = false;
  String? _errorText;

  bool get _keyboardEnabled => PlatformHelper.isWindowsDesktopEffective;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_modes.length, (index) {
      final controller = TextEditingController();
      if (index == 0 && widget.payableAmount > 0) {
        controller.text = widget.payableAmount.toStringAsFixed(2);
      }
      controller.addListener(() {
        if (mounted) setState(() => _errorText = null);
      });
      return controller;
    });
    _focusNodes = List.generate(_modes.length, (index) {
      return FocusNode(
        onKeyEvent: (node, event) => _handleFieldKey(index, event),
      );
    });

    _cashRemarkNode = _detailNode();
    _upiTxnNode = _detailNode();
    _upiRefNode = _detailNode();
    _chequeNoNode = _detailNode();
    _chequeDateNode = _detailNode();
    _chequeRemarkNode = _detailNode();
    _neftTypeNode = _detailNode();
    _bankNameNode = _detailNode();
    _bankRefNode = _detailNode();
    _neftRefNode = _detailNode();
    _cardRemarkNode = _detailNode();
    _otherTypeNode = _detailNode();
    _otherRefNode = _detailNode();
    _otherDateNode = _detailNode();
    _otherRemarkNode = _detailNode();
    _creditRemarkNode = _detailNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes.first.requestFocus();
      _controllers.first.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controllers.first.text.length,
      );
    });
  }

  FocusNode _detailNode() {
    return FocusNode(
      onKeyEvent: (node, event) => _handleDetailKey(node, event),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in [
      _cashRemarkController,
      _upiTxnController,
      _upiRefController,
      _chequeNoController,
      _chequeRemarkController,
      _bankNameController,
      _bankRefController,
      _neftRefController,
      _cardRemarkController,
      _otherTypeController,
      _otherRefController,
      _otherRemarkController,
      _creditRemarkController,
    ]) {
      controller.dispose();
    }
    for (final node in [
      _cashRemarkNode,
      _upiTxnNode,
      _upiRefNode,
      _chequeNoNode,
      _chequeDateNode,
      _chequeRemarkNode,
      _neftTypeNode,
      _bankNameNode,
      _bankRefNode,
      _neftRefNode,
      _cardRemarkNode,
      _otherTypeNode,
      _otherRefNode,
      _otherDateNode,
      _otherRemarkNode,
      _creditRemarkNode,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  double _parse(int index) =>
      double.tryParse(_controllers[index].text.trim()) ?? 0;

  double _amountOf(String mode) => _parse(_modes.indexOf(mode));

  SalesPaymentDetails get _details {
    final amounts = <String, double>{};
    for (var i = 0; i < _modes.length; i++) {
      final value = _parse(i);
      if (value > 0) amounts[_modes[i]] = value;
    }
    return SalesPaymentDetails(
      amounts: amounts,
      cashRemark: _cashRemarkController.text,
      upiTransactionNo: _upiTxnController.text,
      upiReferenceNo: _upiRefController.text,
      chequeNo: _chequeNoController.text,
      chequeDate: _chequeDate,
      chequeRemark: _chequeRemarkController.text,
      bankName: _bankNameController.text,
      bankReferenceNo: _bankRefController.text,
      neftType: _neftType ?? '',
      neftReferenceNo: _neftRefController.text,
      cardRemark: _cardRemarkController.text,
      otherType: _otherTypeController.text,
      otherReferenceNo: _otherRefController.text,
      otherDate: _otherDate,
      otherRemark: _otherRemarkController.text,
      creditRemark: _creditRemarkController.text,
    );
  }

  double get _collected => _details.collectedAmount;

  List<FocusNode> get _visibleFocusOrder {
    final nodes = <FocusNode>[];
    for (var i = 0; i < _modes.length; i++) {
      nodes.add(_focusNodes[i]);
      if (_parse(i) <= 0) continue;
      switch (_modes[i]) {
        case SalesPaymentMode.cash:
          nodes.add(_cashRemarkNode);
          break;
        case SalesPaymentMode.upi:
          nodes.addAll([_upiTxnNode, _upiRefNode]);
          break;
        case SalesPaymentMode.cheque:
          nodes.addAll([_chequeNoNode, _chequeDateNode, _chequeRemarkNode]);
          break;
        case SalesPaymentMode.bank:
          nodes.addAll([
            _neftTypeNode,
            _bankNameNode,
            _bankRefNode,
            _neftRefNode,
          ]);
          break;
        case SalesPaymentMode.card:
          nodes.add(_cardRemarkNode);
          break;
        case SalesPaymentMode.other:
          nodes.addAll([
            _otherTypeNode,
            _otherRefNode,
            _otherDateNode,
            _otherRemarkNode,
          ]);
          break;
        case SalesPaymentMode.credit:
          nodes.add(_creditRemarkNode);
          break;
      }
    }
    return nodes;
  }

  void _cancel() {
    if (_isSubmitting || _hasClosed) return;
    if (!mounted) return;
    _hasClosed = true;
    Navigator.of(context).pop();
  }

  void _focusIndex(int index) {
    final next = (index + _modes.length) % _modes.length;
    _focusNodes[next].requestFocus();
    final text = _controllers[next].text;
    _controllers[next].selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  void _moveFocus(int current, int delta) {
    _focusIndex(current + delta);
  }

  void _focusNext(FocusNode current) {
    final order = _visibleFocusOrder;
    final index = order.indexOf(current);
    if (index >= 0 && index < order.length - 1) {
      order[index + 1].requestFocus();
      return;
    }
    _confirm();
  }

  String? _validate() {
    for (var i = 0; i < _modes.length; i++) {
      final raw = _controllers[i].text.trim();
      if (raw.isNotEmpty && double.tryParse(raw) == null) {
        return 'Please enter a valid amount';
      }
      if (_parse(i) < 0) return 'Amount cannot be negative';
    }
    if (_collected > widget.payableAmount + _epsilon) {
      return 'Amount cannot exceed payable (₹${widget.payableAmount.toStringAsFixed(2)})';
    }
    final remaining = widget.payableAmount - _collected;
    if (_details.creditAmount > remaining + _epsilon) {
      return 'Credit cannot exceed remaining (₹${remaining.toStringAsFixed(2)})';
    }
    return null;
  }

  Future<void> _confirm() async {
    if (_isSubmitting || _hasClosed) return;

    final error = _validate();
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    final details = _details;
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      _hasClosed = true;
      Navigator.of(context).pop(details);
      return;
    }

    setState(() => _isSubmitting = true);
    final succeeded = await onConfirm(details);
    if (!mounted) return;
    if (succeeded) {
      _hasClosed = true;
      Navigator.of(context).pop(details);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onEnter(int index) async {
    if (_isSubmitting) return;
    final error = _validate();
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    if (index < _modes.length - 1) {
      _focusIndex(index + 1);
      return;
    }
    await _confirm();
  }

  KeyEventResult _handleFieldKey(int index, KeyEvent event) {
    if (!_keyboardEnabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isSubmitting) return KeyEventResult.handled;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(index, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(index, -1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _onEnter(index);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleDetailKey(FocusNode node, KeyEvent event) {
    if (!_keyboardEnabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isSubmitting) return KeyEventResult.handled;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (node == _chequeDateNode) {
        _pickDate(isCheque: true);
        return KeyEventResult.handled;
      }
      if (node == _otherDateNode) {
        _pickDate(isCheque: false);
        return KeyEventResult.handled;
      }
      _focusNext(node);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _pickDate({required bool isCheque}) async {
    final initial = (isCheque ? _chequeDate : _otherDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isCheque) {
          _chequeDate = picked;
        } else {
          _otherDate = picked;
        }
      });
      _focusNext(isCheque ? _chequeDateNode : _otherDateNode);
    } else {
      (isCheque ? _chequeDateNode : _otherDateNode).requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paid = _details.paidAmountFor(widget.payableAmount);
    final balance = _details.balanceAmountFor(widget.payableAmount);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
        elevation: 12,
        backgroundColor: theme.dialogBackgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPayableBanner(theme, isDark),
                _buildBreakupHeader(theme),
                _buildBreakupGrid(theme),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildTotalSummary(theme, paid, balance),
                ..._buildDetailSections(theme, isWide),
                const SizedBox(height: 16),
                _buildSaveButton(theme, isDark),
                if (_keyboardEnabled) ...[
                  const SizedBox(height: 10),
                  _buildKeyboardHints(theme, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailSections(ThemeData theme, bool isWide) {
    final sections = <Widget>[];

    if (_amountOf(SalesPaymentMode.cash) > 0) {
      sections.addAll([
        _sectionHeader(theme, 'Cash Details', Icons.payments_outlined),
        _buildTextField(
          theme,
          controller: _cashRemarkController,
          node: _cashRemarkNode,
          label: 'Cash Remark',
          keyName: 'payment-detail-cash-remark',
        ),
      ]);
    }

    if (_amountOf(SalesPaymentMode.upi) > 0) {
      sections.addAll([
        _sectionHeader(theme, 'UPI Details', Icons.qr_code_rounded),
        _responsiveRow(isWide, [
          _buildTextField(
            theme,
            controller: _upiTxnController,
            node: _upiTxnNode,
            label: 'UPI Transaction No',
            keyName: 'payment-detail-upi-txn',
          ),
          _buildTextField(
            theme,
            controller: _upiRefController,
            node: _upiRefNode,
            label: 'UPI Reference No',
            keyName: 'payment-detail-upi-ref',
          ),
        ]),
      ]);
    }

    if (_amountOf(SalesPaymentMode.cheque) > 0) {
      sections.addAll([
        _sectionHeader(theme, 'Cheque Details', Icons.receipt_long_rounded),
        _responsiveRow(isWide, [
          _buildTextField(
            theme,
            controller: _chequeNoController,
            node: _chequeNoNode,
            label: 'Cheque No',
            keyName: 'payment-detail-cheque-no',
          ),
          _buildDateField(
            theme,
            label: 'Cheque Date',
            date: _chequeDate,
            node: _chequeDateNode,
            keyName: 'payment-detail-cheque-date',
            onPick: () => _pickDate(isCheque: true),
          ),
        ]),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          controller: _chequeRemarkController,
          node: _chequeRemarkNode,
          label: 'Cheque Remark',
          keyName: 'payment-detail-cheque-remark',
        ),
      ]);
    }

    if (_amountOf(SalesPaymentMode.bank) > 0) {
      sections.addAll([
        _sectionHeader(
          theme,
          'Bank Transfer Details',
          Icons.account_balance_rounded,
        ),
        _responsiveRow(isWide, [
          _buildNeftTypeField(theme),
          _buildTextField(
            theme,
            controller: _bankNameController,
            node: _bankNameNode,
            label: 'Bank Name',
            keyName: 'payment-detail-bank-name',
          ),
        ]),
        const SizedBox(height: 12),
        _responsiveRow(isWide, [
          _buildTextField(
            theme,
            controller: _bankRefController,
            node: _bankRefNode,
            label: 'Bank Reference No',
            keyName: 'payment-detail-bank-ref',
          ),
          _buildTextField(
            theme,
            controller: _neftRefController,
            node: _neftRefNode,
            label: 'NEFT Reference No',
            keyName: 'payment-detail-neft-ref',
          ),
        ]),
      ]);
    }

    if (_amountOf(SalesPaymentMode.card) > 0) {
      sections.addAll([
        _sectionHeader(theme, 'Card Details', Icons.credit_card_rounded),
        _buildTextField(
          theme,
          controller: _cardRemarkController,
          node: _cardRemarkNode,
          label: 'Card Remark',
          keyName: 'payment-detail-card-remark',
        ),
      ]);
    }

    if (_amountOf(SalesPaymentMode.other) > 0) {
      sections.addAll([
        _sectionHeader(
          theme,
          'Other Payment Details',
          Icons.more_horiz_rounded,
        ),
        _responsiveRow(isWide, [
          _buildTextField(
            theme,
            controller: _otherTypeController,
            node: _otherTypeNode,
            label: 'Other Payment Type',
            keyName: 'payment-detail-other-type',
          ),
          _buildTextField(
            theme,
            controller: _otherRefController,
            node: _otherRefNode,
            label: 'Other Reference No',
            keyName: 'payment-detail-other-ref',
          ),
        ]),
        const SizedBox(height: 12),
        _responsiveRow(isWide, [
          _buildDateField(
            theme,
            label: 'Other Date',
            date: _otherDate,
            node: _otherDateNode,
            keyName: 'payment-detail-other-date',
            onPick: () => _pickDate(isCheque: false),
          ),
          _buildTextField(
            theme,
            controller: _otherRemarkController,
            node: _otherRemarkNode,
            label: 'Other Remark',
            keyName: 'payment-detail-other-remark',
          ),
        ]),
      ]);
    }

    if (_amountOf(SalesPaymentMode.credit) > 0) {
      sections.addAll([
        _sectionHeader(theme, 'Credit Details', Icons.handshake_rounded),
        _buildTextField(
          theme,
          controller: _creditRemarkController,
          node: _creditRemarkNode,
          label: 'Credit Remark',
          keyName: 'payment-detail-credit-remark',
        ),
      ]);
    }

    return sections;
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }

  Widget _responsiveRow(bool isWide, List<Widget> children) {
    if (!isWide) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required TextEditingController controller,
    required FocusNode node,
    required String label,
    required String keyName,
  }) {
    return TextFormField(
      key: Key(keyName),
      controller: controller,
      focusNode: node,
      enabled: !_isSubmitting,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(label, theme),
      onFieldSubmitted: (_) {
        if (!_keyboardEnabled) _focusNext(node);
      },
    );
  }

  Widget _buildDateField(
    ThemeData theme, {
    required String label,
    required DateTime? date,
    required FocusNode node,
    required String keyName,
    required VoidCallback onPick,
  }) {
    return Focus(
      focusNode: node,
      onFocusChange: (_) {
        if (mounted) setState(() {});
      },
      child: InkWell(
        key: Key(keyName),
        onTap: _isSubmitting ? null : onPick,
        child: InputDecorator(
          isFocused: node.hasFocus,
          decoration: _inputDecoration(
            label,
            theme,
          ).copyWith(prefixIcon: const Icon(Icons.calendar_today, size: 18)),
          child: Text(date != null ? _dateFormat.format(date) : 'Select Date'),
        ),
      ),
    );
  }

  Widget _buildNeftTypeField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      key: const Key('payment-detail-neft-type'),
      value: _neftType,
      focusNode: _neftTypeNode,
      decoration: _inputDecoration('Bank Transfer Type', theme),
      items: _bankTransferTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (val) {
              setState(() => _neftType = val);
              _focusNext(_neftTypeNode);
            },
    );
  }

  Widget _buildBreakupHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Payment Breakup',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          IconButton(
            key: const Key('payment-mode-close'),
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, size: 20),
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
            onPressed: _isSubmitting ? null : _cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildPayableBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : theme.colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Bill Amount',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
            ),
          ),
          const Spacer(),
          Text(
            '₹${widget.payableAmount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakupGrid(ThemeData theme) {
    final fields = List.generate(
      _modes.length,
      (index) => _buildModeAmountField(index, theme),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        if (!isWide) {
          return Column(
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                fields[i],
              ],
            ],
          );
        }

        return Column(
          children: [
            for (int start = 0; start < fields.length; start += 3) ...[
              if (start > 0) const SizedBox(height: 12),
              Row(
                children: [
                  for (int col = 0; col < 3; col++) ...[
                    if (col > 0) const SizedBox(width: 16),
                    Expanded(
                      child: start + col < fields.length
                          ? fields[start + col]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildModeAmountField(int index, ThemeData theme) {
    final label = _modes[index];
    return FocusTraversalOrder(
      order: NumericFocusOrder(index.toDouble()),
      child: TextFormField(
        key: Key('payment-mode-$label'),
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: !_isSubmitting,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
        ),
        onFieldSubmitted: (_) {
          if (!_keyboardEnabled) _onEnter(index);
        },
      ),
    );
  }

  Widget _buildTotalSummary(ThemeData theme, double paid, double balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            'Paid: ₹${paid.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Balance: ₹${balance.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: balance > 0
                  ? Colors.orange.shade700
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        key: const Key('payment-mode-confirm'),
        onPressed: _isSubmitting ? null : _confirm,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(
          _isSubmitting ? 'Saving...' : 'Save',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? Colors.blue.shade700.withOpacity(0.6)
              : Colors.blue.shade600.withOpacity(0.6),
          disabledForegroundColor: Colors.white70,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardHints(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Cash → UPI → Cheque → Bank → Card → Other → Credit  •  Enter next  •  Esc cancel',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
    );
  }
}
