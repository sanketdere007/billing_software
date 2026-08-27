import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/platform_helper.dart';

/// Message types supported by the reusable Master/Purchase/Sales dialog.
enum AppMessageType { success, error, warning }

/// Shows a success dialog with title, icon, message, and OK button.
Future<void> showSuccessDialog(BuildContext context, String message) {
  return showAppMessageDialog(
    context,
    message: message,
    type: AppMessageType.success,
  );
}

/// Shows an error dialog with title, icon, message, and OK button.
Future<void> showErrorDialog(BuildContext context, String message) {
  return showAppMessageDialog(
    context,
    message: message,
    type: AppMessageType.error,
  );
}

/// Shows a warning dialog with title, icon, message, and OK button.
Future<void> showWarningDialog(BuildContext context, String message) {
  return showAppMessageDialog(
    context,
    message: message,
    type: AppMessageType.warning,
  );
}

/// Displays a reusable message dialog used by Master, Purchase, and Sales modules.
///
/// Duplicate prevention: if a message dialog is already visible, subsequent calls
/// are ignored until the current dialog is dismissed.
///
/// Keyboard shortcuts (Windows Desktop only):
/// - Enter / NumpadEnter: closes the dialog
/// - Esc: closes the dialog
///
/// On Android, iOS, Web, and other platforms, only the OK button dismisses it.
Future<void> showAppMessageDialog(
  BuildContext context, {
  required String message,
  required AppMessageType type,
  String? title,
}) async {
  if (!context.mounted) return;
  if (AppMessageDialog.isShowing) return;

  AppMessageDialog.markShowing(true);
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          AppMessageDialog(message: message, type: type, title: title),
    );
  } finally {
    AppMessageDialog.markShowing(false);
  }
}

class AppMessageDialog extends StatefulWidget {
  final String message;
  final AppMessageType type;
  final String? title;

  const AppMessageDialog({
    super.key,
    required this.message,
    required this.type,
    this.title,
  });

  static bool _isShowing = false;

  /// Whether a message dialog is currently displayed.
  static bool get isShowing => _isShowing;

  /// Internal flag used by [showAppMessageDialog] to prevent stacked dialogs.
  static void markShowing(bool value) {
    _isShowing = value;
  }

  @override
  State<AppMessageDialog> createState() => _AppMessageDialogState();
}

class _AppMessageDialogState extends State<AppMessageDialog> {
  late final FocusNode _focusNode;
  bool _isHovered = false;
  bool _hasClosed = false;

  String get _title {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    switch (widget.type) {
      case AppMessageType.success:
        return 'Success';
      case AppMessageType.error:
        return 'Error';
      case AppMessageType.warning:
        return 'Warning';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AppMessageType.success:
        return Icons.check_circle_rounded;
      case AppMessageType.error:
        return Icons.error_outline_rounded;
      case AppMessageType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  MaterialColor get _accentColor {
    switch (widget.type) {
      case AppMessageType.success:
        return Colors.green;
      case AppMessageType.error:
        return Colors.red;
      case AppMessageType.warning:
        return Colors.amber;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _close() {
    if (_hasClosed) return;
    if (!mounted) return;
    _hasClosed = true;
    Navigator.of(context).pop();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Keyboard shortcuts are Windows Desktop only.
    if (!PlatformHelper.isWindowsDesktopEffective) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor;
    final showKeyboardHints = PlatformHelper.isWindowsDesktopEffective;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: showKeyboardHints ? _handleKeyEvent : null,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
        elevation: 12,
        backgroundColor: theme.dialogBackgroundColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: accent.shade700, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  _title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.4,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton(
                      onPressed: _close,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.blue.shade700
                            : Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: _isHovered ? 4 : 2,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade800,
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showKeyboardHints) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Press Enter or Esc to close',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
