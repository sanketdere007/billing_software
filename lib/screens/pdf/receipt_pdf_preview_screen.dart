import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/receipt_pdf_controller.dart';
import '../../models/receipt_pdf_data.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class ReceiptPdfPreviewScreen extends StatefulWidget {
  final ReceiptPdfData? receiptData;

  const ReceiptPdfPreviewScreen({super.key, this.receiptData});

  @override
  State<ReceiptPdfPreviewScreen> createState() => _ReceiptPdfPreviewScreenState();
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
      await _controller.printPdf();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to print: $e');
    }
  }

  Future<void> _download() async {
    try {
      final path = await _controller.downloadPdf();
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF saved: $path')));
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to download: $e');
    }
  }

  Future<void> _share() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Share Receipt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Share as Image'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Share as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in WhatsApp Web'),
                onTap: () {
                  Navigator.pop(context);
                  _shareViaWhatsAppWeb();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareAsImage() async {
    try {
      await _controller.shareAsImage();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to share as image: $e');
    }
  }

  Future<void> _shareAsPdf() async {
    try {
      await _controller.shareAsPdf();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to share as PDF: $e');
    }
  }

  Future<void> _shareViaWhatsAppWeb() async {
    try {
      final phone = widget.receiptData?.customerMobile ?? '';
      final parsedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Save PDF to downloads so user can attach it easily
      final path = await _controller.downloadPdf();
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $path. Please attach this file in WhatsApp!'),
            duration: const Duration(seconds: 4),
          )
        );
      }

      final url = Uri.parse('https://web.whatsapp.com/send?phone=$parsedPhone&text=Hello, please find your receipt attached.');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        await showErrorDialog(context, 'Could not open WhatsApp Web. Please check your browser.');
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to open WhatsApp Web: $e');
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
