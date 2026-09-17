import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/platform_helper.dart';

Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.warning_amber_rounded,
  Color iconColor = Colors.red,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AppConfirmDialog(
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
    ),
  );
}

class AppConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.iconColor = Colors.red,
  });

  @override
  State<AppConfirmDialog> createState() => _AppConfirmDialogState();
}

class _AppConfirmDialogState extends State<AppConfirmDialog> {
  late final FocusNode _focusNode;
  bool _isYesSelected = false;

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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!PlatformHelper.isWindowsDesktopEffective) {
      return KeyEventResult.ignored;
    }
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
      Navigator.of(context).pop(false);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                    color: widget.iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
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
                Row(
                  children: [
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
                if (showKeyboardHints) ...[
                  const SizedBox(height: 16),
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
                      'Use ← / → to switch • Enter to confirm • Esc to cancel',
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
