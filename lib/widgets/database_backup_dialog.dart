import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a confirmation dialog for database backup.
/// Returns:
/// - `true` if user selected 'Yes'
/// - `false` if user selected 'No'
/// - `null` if user dismissed dialog (e.g. clicking outside if enabled or pressing Esc)
Future<bool?> showDatabaseBackupConfirmationDialog({
  required BuildContext context,
  required String message,
  String title = 'Database Backup',
  IconData icon = Icons.storage_rounded,
  Color iconColor = Colors.blue,
  bool defaultToYes = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DatabaseBackupConfirmationDialog(
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      defaultToYes: defaultToYes,
    ),
  );
}

class DatabaseBackupConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final bool defaultToYes;

  const DatabaseBackupConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.defaultToYes = true,
  });

  @override
  State<DatabaseBackupConfirmationDialog> createState() =>
      _DatabaseBackupConfirmationDialogState();
}

class _DatabaseBackupConfirmationDialogState
    extends State<DatabaseBackupConfirmationDialog> {
  late bool _isYesSelected;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _isYesSelected = widget.defaultToYes;
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.tab) {
      setState(() {
        _isYesSelected = !_isYesSelected;
      });
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      Navigator.of(context).pop(_isYesSelected);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(null);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
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
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Confirmation Message
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

              // Buttons (Yes and No)
              Row(
                children: [
                  // Yes Button
                  Expanded(
                    child: _buildDialogButton(
                      label: 'Yes',
                      isSelected: _isYesSelected,
                      isPrimary: true,
                      onTap: () => Navigator.of(context).pop(true),
                      onHover: (hovering) {
                        if (hovering && !_isYesSelected) {
                          setState(() => _isYesSelected = true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),

                  // No Button
                  Expanded(
                    child: _buildDialogButton(
                      label: 'No',
                      isSelected: !_isYesSelected,
                      isPrimary: false,
                      onTap: () => Navigator.of(context).pop(false),
                      onHover: (hovering) {
                        if (hovering && _isYesSelected) {
                          setState(() => _isYesSelected = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Shortcut hint footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Use ← / → to select • Enter to confirm • Esc to cancel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required bool isSelected,
    required bool isPrimary,
    required VoidCallback onTap,
    required ValueChanged<bool> onHover,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    if (isSelected) {
      if (isPrimary) {
        backgroundColor = Colors.blue.shade700;
        foregroundColor = Colors.white;
        borderSide = BorderSide(
          color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
          width: 2,
        );
      } else {
        backgroundColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
        foregroundColor = isDark ? Colors.white : Colors.black87;
        borderSide = BorderSide(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
          width: 2,
        );
      }
    } else {
      backgroundColor =
          isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;
      foregroundColor = isDark ? Colors.white70 : Colors.black87;
      borderSide = BorderSide(
        color: isDark ? Colors.white12 : Colors.black12,
        width: 1,
      );
    }

    return MouseRegion(
      onEnter: (_) => onHover(true),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: isSelected ? 3 : 0,
            shadowColor: isSelected
                ? Colors.blue.withOpacity(0.3)
                : Colors.transparent,
            side: borderSide,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Icon(
                  isPrimary
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 18,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a modal progress dialog while the database backup is taking place.
void showBackupProgressDialog(BuildContext context, {String? statusText}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;

      return PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 1,
            ),
          ),
          elevation: 16,
          backgroundColor: theme.dialogBackgroundColor,
          child: Container(
            width: 380,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Backing Up Database...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusText ??
                      'Please wait while the database backup is being created.\nDo not close the application.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color:
                        theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
