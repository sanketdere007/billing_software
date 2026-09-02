import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../controllers/invoice_pdf_controller.dart';
import '../../models/invoice_pdf_data.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_message_dialog.dart';
import '../../widgets/direct_back_scope.dart';

class PdfPreviewScreen extends StatefulWidget {
  final InvoicePdfData? invoiceData;

  const PdfPreviewScreen({super.key, this.invoiceData});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final InvoicePdfController _controller = InvoicePdfController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final data = widget.invoiceData;
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
    try {
      await _controller.sharePdf();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Unable to share: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _controller.pdfBytes;
    final canAct = bytes != null && !_isBusy;

    final appBar = AppBar(
      title: const Text('PDF Preview'),
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
        _ActionBar(
          enabled: canAct,
          onPrint: _print,
          onDownload: _download,
          onShare: _share,
        ),
        Expanded(
          child: _isBusy
              ? const Center(child: CircularProgressIndicator())
              : widget.invoiceData == null
              ? const Center(
                  child: Text(
                    'No invoice data available. Save a Sales Entry to generate a receipt PDF.',
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

class _ActionBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPrint;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _ActionBar({
    required this.enabled,
    required this.onPrint,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // _ActionButton(
            //   enabled: enabled,
            //   icon: Icons.print_outlined,
            //   label: 'Print',
            //   onPressed: onPrint,
            // ),
            // _ActionButton(
            //   enabled: enabled,
            //   icon: Icons.download_outlined,
            //   label: 'Download',
            //   onPressed: onDownload,
            // ),
            // _ActionButton(
            //   enabled: enabled,
            //   icon: Icons.share_outlined,
            //   label: 'Share',
            //   onPressed: onShare,
            // ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
