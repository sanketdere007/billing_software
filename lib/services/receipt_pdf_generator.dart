import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/receipt_pdf_data.dart';

class ReceiptPdfGenerator {
  static const _border = PdfColor.fromInt(0xFF000000);
  static const _lineWidth = 0.6;
  static const _headerSize = 12.0;
  static const _bodySize = 9.0;
  static const _smallSize = 8.0;

  Future<Uint8List> generate(ReceiptPdfData data) async {
    final doc = pw.Document(
      title: 'Payment Receipt ${data.receiptNo}',
      author: data.companyName,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => _buildPage(data),
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPage(ReceiptPdfData data) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: _lineWidth),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildHeader(data),
          _buildReceiptDetails(data),
          _buildCustomerDetails(data),
          _buildPaymentTable(data),
          _buildRemarks(data),
          _buildFooter(data),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(ReceiptPdfData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: _lineWidth)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'PAYMENT RECEIPT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            data.companyName,
            style: pw.TextStyle(
              fontSize: _headerSize,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (data.branchName.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              data.branchName,
              style: pw.TextStyle(fontSize: _bodySize, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ],
          if (data.companyAddress.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              data.companyAddress,
              style: const pw.TextStyle(fontSize: _smallSize, lineSpacing: 1.2),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildReceiptDetails(ReceiptPdfData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: _lineWidth)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _kv('Receipt No', data.receiptNo.isNotEmpty ? data.receiptNo : 'N/A'),
              if (data.invoiceNo.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                _kv('Invoice No', data.invoiceNo),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _kv('Date', data.receiptDate, alignRight: true),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerDetails(ReceiptPdfData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: _lineWidth)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Received With Thanks From:',
            style: pw.TextStyle(fontSize: _smallSize, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.customerName,
            style: pw.TextStyle(fontSize: _bodySize, fontWeight: pw.FontWeight.bold),
          ),
          if (data.customerMobile.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('Phone: ${data.customerMobile}', style: const pw.TextStyle(fontSize: _smallSize)),
          ],
          if (data.customerAddress.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('Address: ${data.customerAddress}', style: const pw.TextStyle(fontSize: _smallSize)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPaymentTable(ReceiptPdfData data) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _border, width: _lineWidth)),
          color: PdfColor.fromInt(0xFFEEEEEE),
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Payment Mode', style: pw.TextStyle(fontSize: _bodySize, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Amount', style: pw.TextStyle(fontSize: _bodySize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    ];

    void addRow(String label, double amount) {
      if (amount > 0) {
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.3)),
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(label, style: const pw.TextStyle(fontSize: _bodySize)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(amount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: _bodySize), textAlign: pw.TextAlign.right),
              ),
            ],
          ),
        );
      }
    }

    addRow('Cash', data.cashAmount);
    addRow('Card', data.cardAmount);
    addRow('UPI', data.upiAmount);
    addRow('Bank', data.bankAmount);
    addRow('Cheque', data.chequeAmount);
    addRow('Other', data.otherAmount);

    return pw.Container(
      child: pw.Column(
        children: [
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
            },
            children: rows,
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _border, width: _lineWidth)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Amount', style: pw.TextStyle(fontSize: _bodySize, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  'Rs. ${data.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: _bodySize, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          if (data.amountInWords.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.centerLeft,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _border, width: _lineWidth)),
              ),
              child: pw.Text(
                'In Words: ${data.amountInWords}',
                style: pw.TextStyle(fontSize: _smallSize, fontWeight: pw.FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildRemarks(ReceiptPdfData data) {
    final remarksList = <String>[];
    
    if (data.cashRemark.isNotEmpty) remarksList.add('Cash: ${data.cashRemark}');
    
    if (data.upiTransactionNo.isNotEmpty) remarksList.add('UPI Txn: ${data.upiTransactionNo}');
    if (data.upiReferenceNo.isNotEmpty) remarksList.add('UPI Ref: ${data.upiReferenceNo}');
    
    if (data.bankTransferType.isNotEmpty) remarksList.add('Bank Transfer Type: ${data.bankTransferType}');
    if (data.bankName.isNotEmpty) remarksList.add('Bank Name: ${data.bankName}');
    if (data.bankAccountNo.isNotEmpty) remarksList.add('Bank A/C: ${data.bankAccountNo}');
    if (data.bankTransactionNo.isNotEmpty) remarksList.add('Bank Txn: ${data.bankTransactionNo}');
    if (data.bankReferenceNo.isNotEmpty) remarksList.add('Bank Ref: ${data.bankReferenceNo}');
    
    if (data.chequeNo.isNotEmpty) remarksList.add('Cheque No: ${data.chequeNo}');
    if (data.chequeBankName.isNotEmpty) remarksList.add('Cheque Bank: ${data.chequeBankName}');
    
    if (data.otherType.isNotEmpty) remarksList.add('Other Type: ${data.otherType}');
    if (data.otherReference.isNotEmpty) remarksList.add('Other Ref: ${data.otherReference}');
    if (data.otherRemark.isNotEmpty) remarksList.add('Other Remark: ${data.otherRemark}');
    
    if (data.remarks.isNotEmpty) remarksList.add(data.remarks);

    if (remarksList.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: _lineWidth)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Remarks / Payment Details:', style: pw.TextStyle(fontSize: _smallSize, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(remarksList.join(' | '), style: const pw.TextStyle(fontSize: _smallSize)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(ReceiptPdfData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Customer Signature', style: pw.TextStyle(fontSize: _smallSize, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),
              pw.Container(width: 100, height: 1, color: _border),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Authorised Signature', style: pw.TextStyle(fontSize: _smallSize, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),
              pw.Container(width: 120, height: 1, color: _border),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _kv(String label, String value, {bool alignRight = false}) {
    return pw.RichText(
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontSize: _smallSize, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(fontSize: _smallSize, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
