import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../controllers/receipt_pdf_controller.dart';
import '../../models/receipt_pdf_data.dart';
import '../../utils/platform_helper.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class ReceiptPdfPreviewScreen extends StatefulWidget {
  final ReceiptPdfData? receiptData;

  const ReceiptPdfPreviewScreen({super.key, this.receiptData});

  @override
  State<ReceiptPdfPreviewScreen> createState() =>
      _ReceiptPdfPreviewScreenState();
}

class _ReceiptPdfPreviewScreenState extends State<ReceiptPdfPreviewScreen> {
  final ReceiptPdfController _controller = ReceiptPdfController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final data = widget.receiptData;
    if (data == null) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await _controller.generateFromData(data);
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, _controller.errorMessage ?? e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _print() async {
    try {
      if (_controller.pdfBytes == null && widget.receiptData != null) {
        await _generate();
      }
      await _controller.printPdf();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to print: $e');
    }
  }

  Future<void> _download() async {
    try {
      if (_controller.pdfBytes == null && widget.receiptData != null) {
        await _generate();
      }
      final path = await _controller.downloadPdf();
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Receipt downloaded successfully to $path')),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to download: $e');
    }
  }

  Future<void> _share() async {
    try {
      if (_controller.pdfBytes == null && widget.receiptData != null) {
        await _generate();
      }
      await _controller.shareAsPdf();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to share as PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _controller.pdfBytes;
    final canAct = bytes != null && !_isBusy;

    final appBar = AppBar(
      title: const Text('Receipt Preview'),
      actions: [
        IconButton(
          tooltip: 'Print',
          onPressed: canAct ? _print : null,
          icon: const Icon(Icons.print_outlined),
        ),
        IconButton(
          tooltip: 'Download',
          onPressed: canAct ? _download : null,
          icon: const Icon(Icons.download_outlined),
        ),
        if (PlatformHelper.isMobile)
          IconButton(
            tooltip: 'Share',
            onPressed: canAct ? _share : null,
            icon: const Icon(Icons.share_outlined),
          ),
        const SizedBox(width: 8),
      ],
    );

    final content = Column(
      children: [
        Expanded(
          child: _isBusy
              ? const Center(child: CircularProgressIndicator())
              : widget.receiptData == null
              ? const Center(
                  child: Text(
                    'No receipt data available.',
                    textAlign: TextAlign.center,
                  ),
                )
              : bytes == null
              ? const Center(child: Text('PDF could not be generated.'))
              : PdfPreview(
                  build: (format) async => bytes,
                  pdfFileName: _controller.fileName,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  padding: const EdgeInsets.all(16),
                ),
        ),
      ],
    );

    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;

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
                    child: Scaffold(appBar: appBar, body: content),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: appBar,
            drawer: const AppDrawer(isPermanent: false),
            body: content,
          );
        },
      ),
    );
  }
}
