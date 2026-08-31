import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/platform_helper.dart';

/// Windows-only F1 (Save) / F2 (Clear) shortcuts that stay active for the
/// lifetime of the screen, regardless of which control has focus.
class SaveClearShortcuts extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onClear;

  const SaveClearShortcuts({
    super.key,
    required this.child,
    this.onSave,
    this.onClear,
  });

  @override
  State<SaveClearShortcuts> createState() => _SaveClearShortcutsState();
}

class _SaveClearShortcutsState extends State<SaveClearShortcuts> {
  /// The same [KeyEvent] instance, if already handled by a nested
  /// [SaveClearShortcuts] on this screen.
  static KeyEvent? _handledEvent;

  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _registerHandler();
  }

  @override
  void dispose() {
    _unregisterHandler();
    super.dispose();
  }

  void _registerHandler() {
    if (_listening) return;
    if (!PlatformHelper.isWindowsDesktopEffective) return;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _listening = true;
  }

  void _unregisterHandler() {
    if (!_listening) return;
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _listening = false;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;

    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.f1 && key != LogicalKeyboardKey.f2) {
      return false;
    }

    // Match SingleActivator defaults: F1/F2 only, no Ctrl/Shift/Alt/Meta.
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return false;
    }

    // Only the current (top) route should handle the shortcut. Covered
    // screens and screens sitting under a dialog must not fire.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    if (identical(_handledEvent, event)) {
      return true;
    }

    final VoidCallback? action =
        key == LogicalKeyboardKey.f1 ? widget.onSave : widget.onClear;
    if (action == null) return false;

    _handledEvent = event;
    action();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
