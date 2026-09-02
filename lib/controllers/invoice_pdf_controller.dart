import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../services/invoice_pdf_generator.dart';
import '../services/invoice_pdf_repository.dart';

/// Coordinates invoice PDF generation and platform actions.
/// Not tied to a UI framework (GetX is not used in this project).
class InvoicePdfController {
  InvoicePdfController({
    InvoicePdfRepository? repository,
    InvoicePdfGenerator? generator,
  })  : _repository = repository ?? InvoicePdfRepository(),
        _generator = generator ?? InvoicePdfGenerator();

  final InvoicePdfRepository _repository;
  final InvoicePdfGenerator _generator;

  Uint8List? pdfBytes;
  String fileName = 'tax-invoice.pdf';
  bool isLoading = false;
  String? errorMessage;

  Future<Uint8List> generate() async {
    isLoading = true;
    errorMessage = null;
    try {
      final data = await _repository.fetchInvoice();
      final safeNo = data.invoice.invoiceNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
      fileName = 'Invoice_$safeNo.pdf';
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

  Future<void> sharePdf() async {
    final bytes = _requireBytes();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Saves the PDF. Returns the saved path/name, or null if the user cancelled.
  Future<String?> downloadPdf() async {
    final bytes = _requireBytes();

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return fileName;
    }

    if (_isDesktop) {
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (location == null) return null;
      final file = XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: fileName,
      );
      await file.saveTo(location.path);
      return location.path;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    final file = XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
      name: fileName,
    );
    await file.saveTo(path);
    return path;
  }

  bool get _isDesktop {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  Uint8List _requireBytes() {
    final bytes = pdfBytes;
    if (bytes == null) {
      throw StateError('PDF has not been generated yet.');
    }
    return bytes;
  }
}
