import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice_pdf_data.dart';

/// Builds a Care-Software-style GST tax invoice PDF from [InvoicePdfData].
/// Layout is independent of how the data is obtained (hardcoded JSON or API).
class InvoicePdfGenerator {
  static const _border = PdfColor.fromInt(0xFF000000);
  static const _lineWidth = 0.6;
  static const _headerSize = 11.0;
  static const _bodySize = 7.5;
  static const _smallSize = 7.0;
  static const _tinySize = 6.5;

  static const _columns = <_InvoiceColumn>[
    _InvoiceColumn('Com', 3.8, pw.Alignment.centerLeft),
    _InvoiceColumn('Product Name', 16.2, pw.Alignment.centerLeft),
    _InvoiceColumn('Pack', 6.2, pw.Alignment.center),
    _InvoiceColumn('HSN', 8.0, pw.Alignment.center),
    _InvoiceColumn('Qty', 4.6, pw.Alignment.centerRight),
    _InvoiceColumn('Scm', 4.0, pw.Alignment.center),
    _InvoiceColumn('Disc', 5.0, pw.Alignment.centerRight),
    _InvoiceColumn('Batch', 10.2, pw.Alignment.centerLeft),
    _InvoiceColumn('Exp', 5.4, pw.Alignment.center),
    _InvoiceColumn('MRP', 7.6, pw.Alignment.centerRight),
    _InvoiceColumn('Rate', 7.6, pw.Alignment.centerRight),
    _InvoiceColumn('GST%', 5.0, pw.Alignment.centerRight),
    _InvoiceColumn('GST AMT', 7.2, pw.Alignment.centerRight),
    _InvoiceColumn('Amount', 9.2, pw.Alignment.centerRight),
  ];

  Future<Uint8List> generate(InvoicePdfData data) async {
    final doc = pw.Document(
      title: '${data.invoice.title} ${data.invoice.invoiceNo}',
      author: data.company.name,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
        build: (context) => _buildPage(data),
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPage(InvoicePdfData data) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: _lineWidth),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildHeader(data),
          _buildItemsHeader(),
          ...data.items.map(_buildItemRow),
          pw.Expanded(child: _buildEmptyTableBody()),
          _buildFooter(data),
          _buildBottomStrip(data),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(InvoicePdfData data) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _border, width: _lineWidth),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 5, child: _buildSellerBlock(data.company)),
          _vDivider(),
          pw.Expanded(flex: 3, child: _buildInvoiceBlock(data.invoice)),
          _vDivider(),
          pw.Expanded(flex: 5, child: _buildBuyerBlock(data)),
        ],
      ),
    );
  }

  pw.Widget _buildSellerBlock(InvoiceCompany company) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(5, 5, 4, 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            company.name,
            style: pw.TextStyle(
              fontSize: _headerSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            company.address,
            style: const pw.TextStyle(fontSize: _smallSize, lineSpacing: 1.1),
          ),
          pw.SizedBox(height: 3),
          if (company.phones.isNotEmpty)
            _kv('PH', company.phones, size: _smallSize, boldValue: false),
          if (company.dlNumbers.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            _kv('DL NO', company.dlNumbers, size: _tinySize, boldValue: false),
          ],
          if (company.gstNo.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            _kv('GST NO', company.gstNo, size: _smallSize),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceBlock(InvoiceMeta invoice) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(4, 6, 4, 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            invoice.title,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            invoice.invoiceNo,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _kv('Date', invoice.date, size: _bodySize),
          pw.SizedBox(height: 2),
          _kv('Time', invoice.time, size: _bodySize),
          pw.SizedBox(height: 2),
          _kv('S.Man', invoice.salesman.isEmpty ? ' ' : invoice.salesman, size: _bodySize),
        ],
      ),
    );
  }

  pw.Widget _buildBuyerBlock(InvoicePdfData data) {
    final customer = data.customer;
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            customer.name,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            customer.address,
            style: const pw.TextStyle(fontSize: _smallSize, lineSpacing: 1.1),
          ),
          pw.SizedBox(height: 3),
          if (customer.phone.isNotEmpty)
            _kv('PH', customer.phone, size: _smallSize),
          if (customer.registrationNo.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(
              customer.registrationNo,
              style: const pw.TextStyle(fontSize: _tinySize),
            ),
          ],
          pw.SizedBox(height: 2),
          _kv(
            'GST.NO',
            customer.gstNo.isEmpty ? ' ' : customer.gstNo,
            size: _smallSize,
          ),
          pw.SizedBox(height: 1),
          _kv(
            'PAN.No',
            customer.panNo.isEmpty ? ' ' : customer.panNo,
            size: _smallSize,
          ),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page No : ${data.invoice.pageLabel}',
              style: pw.TextStyle(
                fontSize: _smallSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsHeader() {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _border, width: _lineWidth),
        ),
      ),
      child: pw.Row(
        children: [
          for (var i = 0; i < _columns.length; i++)
            _tableCell(
              _columns[i].title,
              flex: _flex(_columns[i].flex),
              align: pw.Alignment.center,
              bold: true,
              fontSize: _tinySize,
              showRightBorder: i != _columns.length - 1,
              padding: const pw.EdgeInsets.symmetric(horizontal: 1.5, vertical: 3),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildItemRow(InvoiceLineItem item) {
    final values = <String>[
      item.companyCode,
      item.productName,
      item.pack,
      item.hsn,
      _qty(item.qty),
      item.scheme,
      _optionalAmount(item.discount),
      item.batch,
      item.expiry,
      _amount(item.mrp),
      _amount(item.rate),
      _optionalAmount(item.gstPercent),
      _optionalAmount(item.gstAmount),
      _amount(item.amount),
    ];

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _border, width: 0.35),
        ),
      ),
      child: pw.Row(
        children: [
          for (var i = 0; i < _columns.length; i++)
            _tableCell(
              values[i],
              flex: _flex(_columns[i].flex),
              align: _columns[i].align,
              fontSize: _smallSize,
              showRightBorder: i != _columns.length - 1,
              padding: const pw.EdgeInsets.symmetric(horizontal: 1.5, vertical: 3),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildEmptyTableBody() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _columns.length; i++)
          pw.Expanded(
            flex: _flex(_columns[i].flex),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  right: i == _columns.length - 1
                      ? pw.BorderSide.none
                      : const pw.BorderSide(color: _border, width: 0.4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildFooter(InvoicePdfData data) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _border, width: _lineWidth),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 5, child: _buildBankBlock(data)),
          _vDivider(),
          pw.Expanded(flex: 4, child: _buildGstSlabBlock(data)),
          _vDivider(),
          pw.Expanded(flex: 4, child: _buildTotalsBlock(data)),
        ],
      ),
    );
  }

  pw.Widget _buildBankBlock(InvoicePdfData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(5, 5, 4, 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _kv('Prev.Bal.', _amount(data.previousBalance), size: _bodySize),
          pw.SizedBox(height: 3),
          _kv('Bank', data.bank.name, size: _smallSize),
          _kv('Branch', data.bank.branch, size: _smallSize),
          _kv('IFSC', data.bank.ifsc, size: _smallSize),
          _kv('Ac/No', data.bank.accountNo, size: _smallSize),
          pw.SizedBox(height: 6),
          pw.Text(
            'In Words : ${data.resolvedAmountInWords}',
            style: pw.TextStyle(
              fontSize: _tinySize,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 1.15,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Remark : ${data.remark}',
            style: const pw.TextStyle(fontSize: _tinySize, lineSpacing: 1.1),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGstSlabBlock(InvoicePdfData data) {
    final slabs = data.gstSlabs.isEmpty
        ? const [
            InvoiceGstSlab(label: '2.5%'),
            InvoiceGstSlab(label: '6.0%'),
            InvoiceGstSlab(label: '9.0%'),
            InvoiceGstSlab(label: '14%'),
          ]
        : data.gstSlabs;

    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'SGST',
                  style: pw.TextStyle(
                    fontSize: _tinySize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'CGST',
                  style: pw.TextStyle(
                    fontSize: _tinySize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          for (final slab in slabs) ...[
            pw.Row(
              children: [
                pw.Expanded(child: _gstRatePair(slab.label, slab.sgst)),
                pw.SizedBox(width: 8),
                pw.Expanded(child: _gstRatePair(slab.label, slab.cgst)),
              ],
            ),
            pw.SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  pw.Widget _gstRatePair(String label, double amount) {
    return pw.Row(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: _tinySize)),
        pw.Expanded(
          child: pw.Text(
            amount.toStringAsFixed(3),
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(fontSize: _tinySize),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalsBlock(InvoicePdfData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(5, 5, 6, 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _totalRow('Gross', _amount(data.gross)),
          _totalRow('Add', _amount(data.addAmount)),
          _totalRow('Less', _amount(data.lessAmount)),
          _totalRow('GST', _amount(data.gstTotal)),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _border, width: 0.5),
                bottom: pw.BorderSide(color: _border, width: 0.5),
              ),
            ),
            child: _totalRow('Net Amount', _amount(data.netAmount), bold: true),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'For ${data.company.name}',
              style: pw.TextStyle(
                fontSize: _tinySize,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Authorised Signature',
              style: const pw.TextStyle(fontSize: _tinySize),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: _bodySize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(':  ', style: style),
          pw.SizedBox(
            width: 62,
            child: pw.Text(value, style: style, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBottomStrip(InvoicePdfData data) {
    final parts = <String>[
      if (data.jurisdiction.isNotEmpty)
        'Subject to ${data.jurisdiction} jurisdiction',
      if (data.stateName.isNotEmpty)
        '${data.stateName} CODE: ${data.stateCode}',
      if (data.softwareCredit.isNotEmpty) data.softwareCredit,
      if (data.printedBy.isNotEmpty) data.printedBy,
      if (data.errorsAndOmissionsExcepted) 'E & OE',
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(5, 3, 5, 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _border, width: _lineWidth),
        ),
      ),
      child: pw.Text(
        parts.join('    '),
        style: const pw.TextStyle(fontSize: 6.2),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _vDivider() {
    return pw.Container(width: _lineWidth, color: _border);
  }

  pw.Widget _kv(
    String label,
    String value, {
    double size = _bodySize,
    bool boldValue = true,
  }) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label : ',
            style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              fontSize: size,
              fontWeight: boldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    required int flex,
    required pw.Alignment align,
    bool bold = false,
    double fontSize = _smallSize,
    bool showRightBorder = true,
    pw.EdgeInsets padding = const pw.EdgeInsets.all(2),
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: padding,
        alignment: align,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: showRightBorder
                ? const pw.BorderSide(color: _border, width: 0.4)
                : pw.BorderSide.none,
          ),
        ),
        child: pw.Text(
          text,
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          textAlign: _textAlign(align),
        ),
      ),
    );
  }

  pw.TextAlign _textAlign(pw.Alignment align) {
    if (align == pw.Alignment.centerRight) return pw.TextAlign.right;
    if (align == pw.Alignment.center) return pw.TextAlign.center;
    return pw.TextAlign.left;
  }

  int _flex(double value) => (value * 10).round();

  String _amount(double value) => value.toStringAsFixed(2);

  String _optionalAmount(double value) {
    if (value == 0) return '';
    return value.toStringAsFixed(2);
  }

  String _qty(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _InvoiceColumn {
  final String title;
  final double flex;
  final pw.Alignment align;

  const _InvoiceColumn(this.title, this.flex, this.align);
}
