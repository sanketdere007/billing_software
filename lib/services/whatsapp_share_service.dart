import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/invoice_pdf_data.dart';
import '../utils/platform_helper.dart';
import '../widgets/app_message_dialog.dart';

/// Result object for mobile number validation.
class PhoneValidationResult {
  final bool isValid;
  final String? normalizedPhone;
  final String? errorMessage;

  const PhoneValidationResult.valid(this.normalizedPhone)
      : isValid = true,
        errorMessage = null;

  const PhoneValidationResult.invalid(this.errorMessage)
      : isValid = false,
        normalizedPhone = null;
}

/// Result object for PDF byte-level verification.
class PdfDataVerification {
  final bool isValid;
  final int byteLength;
  final String? errorMessage;

  const PdfDataVerification.valid(this.byteLength)
      : isValid = true,
        errorMessage = null;

  const PdfDataVerification.invalid(this.errorMessage)
      : isValid = false,
        byteLength = 0;
}

/// Result object for on-disk PDF file verification.
class FileVerificationResult {
  final bool isValid;
  final File? file;
  final int sizeBytes;
  final String? errorMessage;

  const FileVerificationResult.valid({
    required this.file,
    required this.sizeBytes,
  })  : isValid = true,
        errorMessage = null;

  const FileVerificationResult.invalid(this.errorMessage)
      : isValid = false,
        file = null,
        sizeBytes = 0;
}

/// Service that manages invoice PDF sharing on Windows Desktop and other platforms.
///
/// Features:
/// 1. Verifies that generated PDF bytes are valid and non-zero (magic %PDF- header).
/// 2. Saves and verifies the actual .pdf file on disk before sharing.
/// 3. Windows Native Share via `share_plus` (passes physical XFile attachment).
/// 4. Direct WhatsApp to customer mobile with pre-filled message, clipboard text,
///    and File Explorer file-selection for effortless drag-and-drop attachment.
class WhatsAppShareService {
  static final WhatsAppShareService _instance = WhatsAppShareService._internal();
  factory WhatsAppShareService() => _instance;
  WhatsAppShareService._internal();

  /// Validates in-memory PDF data: checks for non-empty bytes and valid %PDF- magic bytes.
  PdfDataVerification verifyPdfBytes(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return const PdfDataVerification.invalid('PDF data is empty (0 bytes).');
    }

    if (bytes.length < 5) {
      return const PdfDataVerification.invalid(
        'PDF data is too short to be a valid document.',
      );
    }

    // PDF magic header: %PDF- (0x25, 0x50, 0x44, 0x46, 0x2D)
    if (bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2D) {
      return const PdfDataVerification.invalid(
        'Generated data does not contain a valid PDF header (%PDF-).',
      );
    }

    return PdfDataVerification.valid(bytes.length);
  }

  /// Saves the PDF to disk and verifies it exists, has non-zero size, and matches bytes.
  Future<FileVerificationResult> saveAndVerifyPdfFile(
    Uint8List bytes,
    String fileName,
  ) async {
    final byteCheck = verifyPdfBytes(bytes);
    if (!byteCheck.isValid) {
      return FileVerificationResult.invalid(byteCheck.errorMessage!);
    }

    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = await getTemporaryDirectory();
    }

    final basePath = PlatformHelper.isWindowsDesktop
        ? baseDir.path.replaceAll('/', '\\')
        : baseDir.path;
    final invoicesPath = PlatformHelper.isWindowsDesktop
        ? '$basePath\\Invoices'
        : '$basePath/Invoices';
    final invoicesDir = Directory(invoicesPath);
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    final cleanName = fileName.trim().isNotEmpty ? fileName.trim() : 'invoice.pdf';
    final safeName = cleanName.toLowerCase().endsWith('.pdf')
        ? cleanName
        : '$cleanName.pdf';

    final filePath = PlatformHelper.isWindowsDesktop
        ? '${invoicesDir.path}\\$safeName'
        : '${invoicesDir.path}/$safeName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // Also write a copy to temp directory to guarantee cross-app read access
    try {
      final tempDir = await getTemporaryDirectory();
      final tempBasePath = PlatformHelper.isWindowsDesktop
          ? tempDir.path.replaceAll('/', '\\')
          : tempDir.path;
      final tempInvoicesPath = PlatformHelper.isWindowsDesktop
          ? '$tempBasePath\\Invoices'
          : '$tempBasePath/Invoices';
      final tempInvoicesDir = Directory(tempInvoicesPath);
      if (!await tempInvoicesDir.exists()) {
        await tempInvoicesDir.create(recursive: true);
      }
      final tempFilePath = PlatformHelper.isWindowsDesktop
          ? '${tempInvoicesDir.path}\\$safeName'
          : '${tempInvoicesDir.path}/$safeName';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(bytes, flush: true);
    } catch (_) {}

    if (!await file.exists()) {
      return FileVerificationResult.invalid(
        'Failed to save PDF file to ${file.path}. File does not exist.',
      );
    }

    final size = await file.length();
    if (size == 0) {
      return const FileVerificationResult.invalid(
        'Saved PDF file is empty (0 bytes).',
      );
    }

    if (size != bytes.length) {
      return FileVerificationResult.invalid(
        'Saved PDF size ($size bytes) does not match in-memory size (${bytes.length} bytes).',
      );
    }

    return FileVerificationResult.valid(file: file, sizeBytes: size);
  }

  /// Formats byte sizes into human-readable strings (e.g. "245.2 KB").
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Validates and normalizes the customer's mobile number for WhatsApp.
  PhoneValidationResult validatePhoneNumber(
    String? rawPhone, {
    String? customerName,
  }) {
    final name = (customerName != null && customerName.trim().isNotEmpty)
        ? customerName.trim()
        : 'the customer';

    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return PhoneValidationResult.invalid(
        'Customer mobile number is missing. Please update the mobile number for $name to share via WhatsApp.',
      );
    }

    final trimmed = rawPhone.trim();

    // If multiple numbers separated by slash or comma, test segments
    String candidate = trimmed;
    if (trimmed.contains('/') || trimmed.contains(',')) {
      final segments = trimmed.split(RegExp(r'[/,]'));
      for (final seg in segments) {
        final segDigits = seg.replaceAll(RegExp(r'\D'), '');
        if (segDigits.length >= 10 && segDigits.length <= 15) {
          candidate = seg.trim();
          break;
        }
      }
    }

    final digits = candidate.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return PhoneValidationResult.invalid(
        'Customer mobile number is missing. Please update the mobile number for $name to share via WhatsApp.',
      );
    }

    // Reject dummy numbers with all same digits e.g. "0000000000"
    if (digits.replaceAll('0', '').isEmpty) {
      return PhoneValidationResult.invalid(
        'The mobile number "$trimmed" is invalid. Please provide a valid 10-digit mobile number.',
      );
    }

    // 10 digits - standard Indian mobile number
    if (digits.length == 10) {
      return PhoneValidationResult.valid('91$digits');
    }

    // 11 digits starting with '0' - Indian mobile with leading trunk zero
    if (digits.length == 11 && digits.startsWith('0')) {
      final tenDigits = digits.substring(1);
      return PhoneValidationResult.valid('91$tenDigits');
    }

    // 12 digits starting with '91' - Indian mobile with country code
    if (digits.length == 12 && digits.startsWith('91')) {
      return PhoneValidationResult.valid(digits);
    }

    // International numbers (10 to 15 digits)
    if (digits.length >= 10 && digits.length <= 15) {
      return PhoneValidationResult.valid(digits);
    }

    return PhoneValidationResult.invalid(
      'The mobile number "$trimmed" is invalid. Please provide a valid 10-digit mobile number.',
    );
  }

  /// Formats a concise, professional message pre-filled in WhatsApp chat.
  String formatWhatsAppMessage(InvoicePdfData invoiceData) {
    final customerName = invoiceData.customer.name.trim();
    final invoiceNo = invoiceData.invoice.invoiceNo.trim();
    final date = invoiceData.invoice.date.trim();
    final totalFormatted = invoiceData.netAmount > 0
        ? '₹${NumberFormat('#,##,##0.00', 'en_IN').format(invoiceData.netAmount)}'
        : '';
    final companyName = invoiceData.company.name.trim();

    final buffer = StringBuffer();
    if (customerName.isNotEmpty) {
      buffer.writeln('Dear $customerName,');
      buffer.writeln();
    }
    buffer.writeln('Please find your Sales Invoice details below:');
    if (invoiceNo.isNotEmpty) buffer.writeln('• Invoice No: $invoiceNo');
    if (date.isNotEmpty) buffer.writeln('• Date: $date');
    if (totalFormatted.isNotEmpty) buffer.writeln('• Total Amount: $totalFormatted');
    buffer.writeln('• Status: Completed');

    if (companyName.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Thank you for your business!');
      buffer.writeln(companyName);
    }

    return buffer.toString().trim();
  }

  /// On Windows Desktop, copies the PDF file to the Windows Clipboard (CF_HDROP).
  Future<bool> copyPdfFileToClipboard(String filePath) async {
    if (!PlatformHelper.isWindowsDesktop) return false;

    try {
      final normalized = filePath.replaceAll('/', '\\');
      final file = File(normalized);
      if (!await file.exists()) {
        debugPrint('copyPdfFileToClipboard: file does not exist: $normalized');
        return false;
      }

      final escapedPath = normalized.replaceAll("'", "''");
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "Set-Clipboard -LiteralPath '$escapedPath'",
        ],
        runInShell: true,
      );
      return result.exitCode == 0;
    } on ProcessException catch (e) {
      debugPrint('ProcessException in copyPdfFileToClipboard: $e');
      return false;
    } catch (e) {
      debugPrint('PowerShell Set-Clipboard error: $e');
      return false;
    }
  }

  /// Opens Windows Explorer with the generated PDF file highlighted (/select).
  ///
  /// Uses [Process.start] with `runInShell: true` to prevent `CreateProcess` `Access is denied`
  /// errors on Windows 10/11 and detached execution.
  /// If highlighting the file fails or the file does not exist, falls back gracefully to opening
  /// the containing directory without crashing the sharing workflow.
  Future<bool> openInExplorer(String filePath) async {
    if (!PlatformHelper.isWindowsDesktop) return false;

    final normalized = filePath.replaceAll('/', '\\');
    final file = File(normalized);

    if (!file.existsSync()) {
      debugPrint('openInExplorer: file does not exist: $normalized');
      return openContainingFolder(filePath);
    }

    try {
      // Use Process.start with runInShell: true so cmd.exe invokes explorer.exe with shell elevation,
      // avoiding CreateProcess Win32 ERROR_ACCESS_DENIED.
      final process = await Process.start(
        'explorer.exe',
        ['/select,', normalized],
        runInShell: true,
      );
      process.exitCode.catchError((e) {
        debugPrint('Explorer process async error: $e');
        return -1;
      });
      return true;
    } on ProcessException catch (e) {
      debugPrint('ProcessException in openInExplorer (/select): $e');
      return openContainingFolder(filePath);
    } catch (e) {
      debugPrint('General error in openInExplorer (/select): $e');
      return openContainingFolder(filePath);
    }
  }

  /// Opens the containing folder of the PDF file in Windows Explorer.
  Future<bool> openContainingFolder(String filePath) async {
    if (!PlatformHelper.isWindowsDesktop) return false;

    try {
      final normalized = filePath.replaceAll('/', '\\');
      final parentDir = File(normalized).parent.path.replaceAll('/', '\\');
      final dir = Directory(parentDir);

      if (!dir.existsSync()) {
        debugPrint('openContainingFolder: directory does not exist: $parentDir');
        return false;
      }

      final process = await Process.start(
        'explorer.exe',
        [parentDir],
        runInShell: true,
      );
      process.exitCode.catchError((e) {
        debugPrint('Explorer folder async error: $e');
        return -1;
      });
      return true;
    } on ProcessException catch (e) {
      debugPrint('ProcessException in openContainingFolder: $e');
      return false;
    } catch (e) {
      debugPrint('General error in openContainingFolder: $e');
      return false;
    }
  }

  /// Launches WhatsApp directed specifically to the customer's phone number.
  Future<bool> launchWhatsAppChat({
    required String phone,
    required String message,
  }) async {
    final encodedText = Uri.encodeComponent(message);

    // 1. Attempt native desktop app protocol
    final nativeUri = Uri.parse('whatsapp://send?phone=$phone&text=$encodedText');
    bool launched = false;
    try {
      if (await canLaunchUrl(nativeUri)) {
        launched = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Native WhatsApp protocol launch error: $e');
      launched = false;
    }

    // 2. Fallback to WhatsApp Web link (wa.me)
    if (!launched) {
      final webUri = Uri.parse('https://wa.me/$phone?text=$encodedText');
      try {
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('WhatsApp Web (wa.me) launch error: $e');
        launched = false;
      }
    }

    // 3. Fallback to api.whatsapp.com
    if (!launched) {
      final apiUri = Uri.parse(
        'https://api.whatsapp.com/send?phone=$phone&text=$encodedText',
      );
      try {
        launched = await launchUrl(
          apiUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('WhatsApp API link launch error: $e');
        launched = false;
      }
    }

    return launched;
  }

  /// Shares the actual verified PDF document file via Windows Share contract (`share_plus` with `XFile`).
  /// This passes the physical `.pdf` file to Windows DataTransferManager so the user can choose
  /// WhatsApp, Email, or any other installed application to send the document attachment.
  Future<void> sharePdfViaWindowsShare({
    required BuildContext context,
    required InvoicePdfData invoiceData,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final verification = await saveAndVerifyPdfFile(pdfBytes, fileName);
    if (!verification.isValid) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          'PDF Verification Failed: ${verification.errorMessage}',
        );
      }
      return;
    }

    final file = verification.file!;
    final safeName = file.uri.pathSegments.last;

    try {
      final xFile = XFile(
        file.path,
        mimeType: 'application/pdf',
        name: safeName,
      );

      final message = formatWhatsAppMessage(invoiceData);
      final invoiceNo = invoiceData.invoice.invoiceNo.trim();
      final subject = invoiceNo.isNotEmpty ? 'Sales Invoice $invoiceNo' : 'Sales Invoice';

      await Share.shareXFiles(
        [xFile],
        text: message,
        subject: subject,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Windows Share opened with PDF document ($safeName • ${formatFileSize(verification.sizeBytes)}).',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Windows Share error: $e');
      if (context.mounted) {
        await showErrorDialog(
          context,
          'Failed to open Windows Share: $e',
        );
      }
    }
  }

  /// Opens WhatsApp directly to the customer's phone number with the invoice summary,
  /// verifies and saves the actual PDF file on disk, copies message text & file to clipboard,
  /// opens File Explorer with the PDF selected, and provides a clear workflow dialog.
  Future<void> shareViaDirectWhatsAppChat({
    required BuildContext context,
    required InvoicePdfData invoiceData,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    // 1. Validate customer mobile number
    final rawPhone = invoiceData.customer.phone;
    final customerName = invoiceData.customer.name;
    final validation = validatePhoneNumber(rawPhone, customerName: customerName);

    if (!validation.isValid) {
      if (context.mounted) {
        await showWarningDialog(
          context,
          validation.errorMessage ?? 'Customer mobile number is missing or invalid.',
        );
      }
      return;
    }

    final normalizedPhone = validation.normalizedPhone!;

    // 2. Verify and save the physical PDF document
    final fileResult = await saveAndVerifyPdfFile(pdfBytes, fileName);
    if (!fileResult.isValid) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          'PDF Verification Failed: ${fileResult.errorMessage}',
        );
      }
      return;
    }

    final savedFile = fileResult.file!;
    final safeName = savedFile.uri.pathSegments.last;
    final fileSizeText = formatFileSize(fileResult.sizeBytes);

    // 3. Format message and copy text to system clipboard
    final message = formatWhatsAppMessage(invoiceData);
    try {
      await Clipboard.setData(ClipboardData(text: message));
    } catch (_) {}

    // 4. Copy PDF file to clipboard (CF_HDROP) on Windows
    await copyPdfFileToClipboard(savedFile.path);

    // 5. Open WhatsApp chat directed to the customer
    final launched = await launchWhatsAppChat(
      phone: normalizedPhone,
      message: message,
    );

    if (!context.mounted) return;

    if (!launched) {
      await showErrorDialog(
        context,
        'Could not open WhatsApp. Please ensure WhatsApp Desktop or a supported web browser is installed.',
      );
      return;
    }

    // 6. Wait a moment for WhatsApp to launch, then bring File Explorer to front with the PDF selected
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      await openInExplorer(savedFile.path);
    } catch (e) {
      debugPrint('Non-fatal openInExplorer error: $e');
    }

    if (!context.mounted) return;

    final displayName = customerName.isNotEmpty ? customerName : 'the customer';

    // 7. Display clear guidance dialog
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE7FCE8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'WhatsApp Chat Opened',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$displayName (+$normalizedPhone)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$safeName ($fileSizeText • Verified PDF)',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Attachment instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Text(
                            'How to attach the PDF in WhatsApp:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. File Explorer was opened with "$safeName" highlighted.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2. Drag the highlighted PDF file directly into your WhatsApp chat window.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '3. Or press Ctrl + V in the WhatsApp message input (the file was copied to your clipboard).',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: WhatsApp Desktop protocols do not permit automatic third-party file injection.',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Open PDF Folder'),
              onPressed: () => openInExplorer(savedFile.path),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Windows Share'),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                sharePdfViaWindowsShare(
                  context: context,
                  invoiceData: invoiceData,
                  pdfBytes: pdfBytes,
                  fileName: fileName,
                );
              },
            ),
            FilledButton(
              child: const Text('Done'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
          ],
        );
      },
    );
  }

  /// Displays the interactive "Share Sales Invoice" options modal dialog.
  /// Allows the user to choose between:
  /// 1. Direct WhatsApp Chat with customer (with verified PDF prepared in Explorer & Clipboard).
  /// 2. Windows Native Share (`share_plus` with `XFile` physical PDF attachment).
  Future<void> showShareOptionsDialog({
    required BuildContext context,
    required InvoicePdfData invoiceData,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    // 1. Verify in-memory PDF data
    final byteCheck = verifyPdfBytes(pdfBytes);
    if (!byteCheck.isValid) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          'PDF Verification Failed: ${byteCheck.errorMessage}',
        );
      }
      return;
    }

    final rawPhone = invoiceData.customer.phone;
    final customerName = invoiceData.customer.name;
    final validation = validatePhoneNumber(rawPhone, customerName: customerName);
    final invoiceNo = invoiceData.invoice.invoiceNo.trim();
    final totalFormatted = invoiceData.netAmount > 0
        ? '₹${NumberFormat('#,##,##0.00', 'en_IN').format(invoiceData.netAmount)}'
        : '';
    final fileSizeText = formatFileSize(byteCheck.byteLength);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Share Sales Invoice',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice & File Details Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            customerName.isNotEmpty ? customerName : 'Customer',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (totalFormatted.isNotEmpty)
                            Text(
                              totalFormatted,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (invoiceNo.isNotEmpty) ...[
                            Text(
                              'Invoice: $invoiceNo',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                            ),
                            const Text(' • '),
                          ],
                          Icon(
                            validation.isValid ? Icons.phone_rounded : Icons.phone_disabled_rounded,
                            size: 14,
                            color: validation.isValid ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              validation.isValid
                                  ? '+${validation.normalizedPhone}'
                                  : 'No mobile number',
                              style: TextStyle(
                                color: validation.isValid ? Colors.green.shade800 : Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$fileName ($fileSizeText • Verified PDF)',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose sharing method:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),

                // Option 1: Direct WhatsApp Chat
                InkWell(
                  onTap: validation.isValid
                      ? () {
                          Navigator.of(dialogCtx).pop();
                          shareViaDirectWhatsAppChat(
                            context: context,
                            invoiceData: invoiceData,
                            pdfBytes: pdfBytes,
                            fileName: fileName,
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: validation.isValid ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF25D366).withOpacity(validation.isValid ? 0.6 : 0.2),
                          width: 1.5,
                        ),
                        color: const Color(0xFF25D366).withOpacity(0.08),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.chat_rounded, color: Color(0xFF1EBE5D)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'WhatsApp to Customer',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (validation.isValid) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(+${validation.normalizedPhone})',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF1EBE5D)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  validation.isValid
                                      ? 'Opens chat with customer, copies message, and selects PDF in Explorer to attach.'
                                      : 'Disabled: Customer mobile number is missing or invalid.',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Option 2: Windows Share (Actual PDF Attachment via share_plus)
                InkWell(
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    sharePdfViaWindowsShare(
                      context: context,
                      invoiceData: invoiceData,
                      pdfBytes: pdfBytes,
                      fileName: fileName,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.5),
                      color: colorScheme.primaryContainer.withOpacity(0.15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.attach_file_rounded, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Windows Share (Attach PDF Document)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Passes the verified PDF document to Windows Share panel (WhatsApp, Mail, Outlook, etc.).',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
          ],
        );
      },
    );
  }

  /// Backward-compatible alias for sharing flow.
  Future<void> shareInvoicePdfViaWhatsApp({
    required BuildContext context,
    required InvoicePdfData invoiceData,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await showShareOptionsDialog(
      context: context,
      invoiceData: invoiceData,
      pdfBytes: pdfBytes,
      fileName: fileName,
    );
  }
}

final whatsAppShareService = WhatsAppShareService();
