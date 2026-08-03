import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Helper utility for detecting platform capabilities with safe fallbacks.
class PlatformHelper {
  /// Returns `true` only when the app is running as a desktop app on Windows.
  /// Strictly returns `false` on Web (Chrome/Firefox/Edge on web), Android, iOS, macOS, and Linux.
  static bool get isWindowsDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows;
    } catch (_) {
      // In case Platform check throws on any unsupported environment
      return defaultTargetPlatform == TargetPlatform.windows;
    }
  }

  /// For testing purposes or manual overrides if needed.
  static bool? _overrideIsWindowsDesktop;
  
  static bool get isWindowsDesktopEffective {
    if (_overrideIsWindowsDesktop != null) {
      return _overrideIsWindowsDesktop!;
    }
    return isWindowsDesktop;
  }

  static void setOverrideForTesting(bool? value) {
    _overrideIsWindowsDesktop = value;
  }
}
