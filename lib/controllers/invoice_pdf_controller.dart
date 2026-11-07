import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/invoice_pdf_data.dart';
import '../services/invoice_pdf_generator.dart';
import '../services/whatsapp_share_service.dart';
import '../services/pdf_download_service.dart';

/// Coordinates invoice PDF generation and platform actions.
/// Not tied to a UI framework (GetX is not used in this project).
class InvoicePdfController {
  InvoicePdfController({
    InvoicePdfGenerator? generator,
  }) : _generator = generator ?? InvoicePdfGenerator();

  final InvoicePdfGenerator _generator;

  InvoicePdfData? currentData;
  Uint8List? pdfBytes;
  String fileName = 'tax-invoice.pdf';
  bool isLoading = false;
  String? errorMessage;

  /// Builds the PDF from already-mapped [InvoicePdfData].
  /// The generator does not fetch APIs or contain hardcoded records.
  Future<Uint8List> generateFromData(
    InvoicePdfData data, {
    String? customFileName,
  }) async {
    isLoading = true;
    errorMessage = null;
    currentData = data;
    try {
      final rawNo = data.invoice.invoiceNo.trim().isNotEmpty
          ? data.invoice.invoiceNo.trim()
          : 'invoice';
      final safeNo = rawNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
      if (customFileName != null && customFileName.trim().isNotEmpty) {
        fileName = customFileName.trim();
      } else if (safeNo.toLowerCase().startsWith('inv')) {
        fileName = '$safeNo.pdf';
      } else {
        fileName = 'Invoice_$safeNo.pdf';
      }
      pdfBytes = await _generator.generate(data);
      return pdfBytes!;
    } catch (e) {
      errorMessage = 'Unable to generate PDF: $e';
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  Future<void> printPdf() async {
    final bytes = _requireBytes();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }

  Future<void> shareViaWhatsApp({
    required InvoicePdfData invoiceData,
    required BuildContext context,
  }) async {
    final bytes = pdfBytes ?? await generateFromData(invoiceData);
    await whatsAppShareService.shareInvoicePdfViaWhatsApp(
      context: context,
      invoiceData: invoiceData,
      pdfBytes: bytes,
      fileName: fileName,
    );
  }

  Future<void> sharePdf({
    InvoicePdfData? invoiceData,
    BuildContext? context,
  }) async {
    final effectiveData = invoiceData ?? currentData;
    if (context != null && effectiveData != null) {
      await shareViaWhatsApp(
        invoiceData: effectiveData,
        context: context,
      );
      return;
    }
    final bytes = _requireBytes();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Saves the PDF. Returns the saved path/name, or null if the user cancelled.
  Future<String?> downloadPdf() async {
    final bytes = _requireBytes();
    return PdfDownloadService.downloadPdf(bytes: bytes, fileName: fileName);
  }

  Uint8List _requireBytes() {
    final bytes = pdfBytes;
    if (bytes == null) {
      throw StateError('PDF has not been generated yet.');
    }
    return bytes;
  }
}
