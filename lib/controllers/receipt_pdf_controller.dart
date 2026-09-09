import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../models/receipt_pdf_data.dart';
import '../services/receipt_pdf_generator.dart';
import 'dart:io';

class ReceiptPdfController {
  ReceiptPdfController({ReceiptPdfGenerator? generator})
    : _generator = generator ?? ReceiptPdfGenerator();

  final ReceiptPdfGenerator _generator;

  Uint8List? pdfBytes;
  String fileName = 'receipt.pdf';
  bool isLoading = false;
  String? errorMessage;

  Future<Uint8List> generateFromData(ReceiptPdfData data) async {
    isLoading = true;
    errorMessage = null;
    try {
      final rawNo = data.receiptNo.trim().isNotEmpty
          ? data.receiptNo.trim()
          : 'receipt';
      final safeNo = rawNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
      fileName = 'Receipt_$safeNo.pdf';
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
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
  }

  Future<void> shareAsPdf() async {
    final bytes = _requireBytes();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  Future<void> shareAsImage() async {
    final bytes = _requireBytes();

    if (kIsWeb) {
      throw UnsupportedError('Share as Image is not supported on Web');
    }

    // Rasterize the first page
    await for (var page in Printing.raster(bytes, pages: [0], dpi: 200)) {
      final imageBytes = await page.toPng();
      final imageName = fileName.replaceAll(".pdf", ".png");

      await Printing.sharePdf(bytes: imageBytes, filename: imageName);
      break; // Only share the first page
    }
  }

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
