import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SaveClearShortcuts extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Only apply shortcuts on Windows
    if (!Platform.isWindows) return child;

    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.f1): const _SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.f2): const _ClearIntent(),
      },
      actions: {
        _SaveIntent: CallbackAction<_SaveIntent>(onInvoke: (intent) {
          if (onSave != null) onSave!();
          return null;
        }),
        _ClearIntent: CallbackAction<_ClearIntent>(onInvoke: (intent) {
          if (onClear != null) onClear!();
          return null;
        }),
      },
      child: child,
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _ClearIntent extends Intent {
  const _ClearIntent();
}
