import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Loads and manages Unicode-compatible TrueType (TTF) fonts for invoice PDF generation.
///
/// Fixes the default Helvetica limitations:
/// - Helvetica / Helvetica-Bold only supports standard 14 WinAnsi encoding.
/// - Any Unicode characters (Indian Rupee symbol ₹, Marathi / Hindi Devanagari text)
///   previously produced "Helvetica has no Unicode support" warnings or missing glyphs.
///
/// Resolution strategy:
/// 1. Tries to load from bundled assets:
///    - `assets/fonts/NotoSans-Regular.ttf`
///    - `assets/fonts/NotoSans-Bold.ttf`
///    - `assets/fonts/NotoSansDevanagari-Regular.ttf`
///    - `assets/fonts/NotoSansDevanagari-Bold.ttf`
/// 2. Tries to load from local file path if present on disk.
/// 3. Falls back to `PdfGoogleFonts` (which fetches over HTTP and caches on disk/in-memory).
/// 4. If all sources fail, provides clear diagnostic warnings and falls back safely
///    without crashing the invoice generation workflow.
class InvoicePdfFontLoader {
  InvoicePdfFontLoader._();

  static pw.ThemeData? _cachedTheme;
  static pw.Font? _cachedBase;
  static pw.Font? _cachedBold;
  static pw.Font? _cachedDevanagariRegular;
  static pw.Font? _cachedDevanagariBold;

  /// Returns a cached or newly constructed [pw.ThemeData] containing Unicode fonts.
  static Future<pw.ThemeData> getTheme({bool forceReload = false}) async {
    if (!forceReload && _cachedTheme != null) {
      return _cachedTheme!;
    }

    final baseFont = await _loadFont(
      assetPath: 'assets/fonts/NotoSans-Regular.ttf',
      fallbackLoader: () => PdfGoogleFonts.notoSansRegular(),
      fontName: 'NotoSans-Regular',
      cachedFont: _cachedBase,
      onCached: (f) => _cachedBase = f,
    );

    final boldFont = await _loadFont(
      assetPath: 'assets/fonts/NotoSans-Bold.ttf',
      fallbackLoader: () => PdfGoogleFonts.notoSansBold(),
      fontName: 'NotoSans-Bold',
      cachedFont: _cachedBold,
      onCached: (f) => _cachedBold = f,
    );

    final devanagariRegular = await _loadFont(
      assetPath: 'assets/fonts/NotoSansDevanagari-Regular.ttf',
      fallbackLoader: () => PdfGoogleFonts.notoSansDevanagariRegular(),
      fontName: 'NotoSansDevanagari-Regular',
      cachedFont: _cachedDevanagariRegular,
      onCached: (f) => _cachedDevanagariRegular = f,
    );

    final devanagariBold = await _loadFont(
      assetPath: 'assets/fonts/NotoSansDevanagari-Bold.ttf',
      fallbackLoader: () => PdfGoogleFonts.notoSansDevanagariBold(),
      fontName: 'NotoSansDevanagari-Bold',
      cachedFont: _cachedDevanagariBold,
      onCached: (f) => _cachedDevanagariBold = f,
    );

    final fontFallbackList = <pw.Font>[
      if (devanagariRegular != null) devanagariRegular,
      if (devanagariBold != null) devanagariBold,
    ];

    if (baseFont == null || boldFont == null) {
      final missing = [
        if (baseFont == null) 'NotoSans-Regular.ttf',
        if (boldFont == null) 'NotoSans-Bold.ttf',
      ].join(', ');
      debugPrint(
        'InvoicePdfFontLoader: Warning: Could not resolve primary Unicode font ($missing). '
        'Verify that font assets exist in assets/fonts/ or internet access is available on first launch.',
      );
    }

    final effectiveBase = baseFont ?? pw.Font.helvetica();
    final effectiveBold = boldFont ?? pw.Font.helveticaBold();
    final effectiveItalic = baseFont ?? pw.Font.helveticaOblique();
    final effectiveBoldItalic = boldFont ?? pw.Font.helveticaBoldOblique();

    _cachedTheme = pw.ThemeData.withFont(
      base: effectiveBase,
      bold: effectiveBold,
      italic: effectiveItalic,
      boldItalic: effectiveBoldItalic,
      fontFallback: fontFallbackList.isNotEmpty ? fontFallbackList : null,
    );

    return _cachedTheme!;
  }

  /// Attempts to load a TTF font from AssetBundle, local file, or PdfGoogleFonts.
  static Future<pw.Font?> _loadFont({
    required String assetPath,
    required Future<pw.Font> Function() fallbackLoader,
    required String fontName,
    pw.Font? cachedFont,
    required void Function(pw.Font) onCached,
  }) async {
    if (cachedFont != null) return cachedFont;

    // 1. Attempt loading from Flutter AssetBundle
    try {
      final byteData = await rootBundle.load(assetPath);
      if (byteData.lengthInBytes > 0) {
        final font = pw.Font.ttf(byteData);
        onCached(font);
        return font;
      }
    } catch (_) {
      // Asset not found in bundle, proceed to next strategy
    }

    // 2. Attempt loading from local filesystem (desktop working directory)
    try {
      final file = File(assetPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final byteData = bytes.buffer.asByteData(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          );
          final font = pw.Font.ttf(byteData);
          onCached(font);
          return font;
        }
      }
    } catch (_) {
      // Local file read error or non-desktop environment
    }

    // 3. Fallback to Google Fonts via printing package
    try {
      final font = await fallbackLoader();
      onCached(font);
      return font;
    } catch (e) {
      debugPrint('InvoicePdfFontLoader: Failed to load $fontName via Google Fonts: $e');
    }

    return null;
  }

  /// Clears in-memory theme and font caches.
  static void clearCache() {
    _cachedTheme = null;
    _cachedBase = null;
    _cachedBold = null;
    _cachedDevanagariRegular = null;
    _cachedDevanagariBold = null;
  }
}
