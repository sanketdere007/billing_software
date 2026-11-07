import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Central service for downloading and saving PDF documents across all platforms.
///
/// Features:
/// - Windows Desktop: Retains the native Save File Dialog via `file_selector`.
/// - Android: Saves directly to the public Downloads folder using MediaStore (API 29+)
///   and legacy external storage with permission handling (API <= 28). Files are
///   indexed so they immediately appear in the device's Files/Downloads app.
/// - Web: Initiates direct browser download via `Printing.sharePdf`.
/// - iOS/Other: Saves to application documents directory.
class PdfDownloadService {
  static const MethodChannel _downloadChannel =
      MethodChannel('billing_software/downloads');

  static bool get _isDesktop {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  /// Saves the given [bytes] as a PDF named [fileName].
  ///
  /// Returns the saved absolute file path on disk (or filename on Web),
  /// or null if the user cancelled the desktop save dialog.
  static Future<String?> downloadPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
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

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final String? savedPath = await _downloadChannel.invokeMethod<String>(
          'saveToDownloads',
          {
            'bytes': bytes,
            'fileName': fileName,
          },
        );
        if (savedPath != null && savedPath.isNotEmpty) {
          return savedPath;
        }
      } on PlatformException catch (e) {
        if (e.code == 'PERMISSION_DENIED') {
          throw Exception(
            'Storage permission was denied. Please grant storage permission to download receipts.',
          );
        }
        throw Exception(
          e.message ?? 'Failed to save receipt to Downloads on Android.',
        );
      } catch (e) {
        // Fallback: Attempt writing directly to device Downloads or external storage
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            final filePath = '${downloadDir.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(bytes, flush: true);
            return filePath;
          }

          final extDirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (extDirs != null && extDirs.isNotEmpty) {
            final filePath = '${extDirs.first.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(bytes, flush: true);
            return filePath;
          }
        } catch (_) {}
        rethrow;
      }
    }

    // Default for iOS / other platforms
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
}
