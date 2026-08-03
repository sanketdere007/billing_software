import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the confirmation dialog asking if user is sure they want to close the screen.
/// Fully supports keyboard navigation:
/// - Left Arrow (←) / Right Arrow (→): Switch focus between Yes and No
/// - Enter: Activates the currently selected button
/// - Esc: Closes the dialog (returns false)
/// - Default selected button: No
Future<bool?> showCloseConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CloseConfirmationDialog(),
  );
}

class CloseConfirmationDialog extends StatefulWidget {
  const CloseConfirmationDialog({super.key});

  @override
  State<CloseConfirmationDialog> createState() => _CloseConfirmationDialogState();
}

class _CloseConfirmationDialogState extends State<CloseConfirmationDialog> {
  // Default selected button is 'No' (false)
  bool _isYesSelected = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Auto-request focus for dialog keyboard events
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

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      Navigator.of(context).pop(_isYesSelected);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      // Esc while dialog is open closes the dialog (same as selecting No)
      Navigator.of(context).pop(false);
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
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Close Screen',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Confirmation Message
              Text(
                'Are you sure you want to close this screen?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons (Yes and No)
              Row(
                children: [
                  // Yes Button
                  Expanded(
                    child: _buildButton(
                      label: 'Yes',
                      isSelected: _isYesSelected,
                      isDestructive: true,
                      onTap: () => Navigator.of(context).pop(true),
                      onHover: (hovering) {
                        if (hovering && !_isYesSelected) {
                          setState(() => _isYesSelected = true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // No Button (Default)
                  Expanded(
                    child: _buildButton(
                      label: 'No',
                      isSelected: !_isYesSelected,
                      isDestructive: false,
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
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Use ← / → to switch • Enter to confirm • Esc to cancel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required bool isSelected,
    required bool isDestructive,
    required VoidCallback onTap,
    required ValueChanged<bool> onHover,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    if (isSelected) {
      if (isDestructive) {
        backgroundColor = Colors.red.shade600;
        foregroundColor = Colors.white;
        borderSide = const BorderSide(color: Colors.redAccent, width: 2);
      } else {
        backgroundColor = isDark ? Colors.blue.shade700 : Colors.blue.shade600;
        foregroundColor = Colors.white;
        borderSide = BorderSide(
          color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
          width: 2,
        );
      }
    } else {
      backgroundColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;
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
            elevation: isSelected ? 4 : 0,
            shadowColor: isSelected
                ? (isDestructive ? Colors.red.withOpacity(0.4) : Colors.blue.withOpacity(0.4))
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
                  isDestructive ? Icons.check_circle_outline : Icons.arrow_right_rounded,
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
