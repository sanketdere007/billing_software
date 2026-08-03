import 'package:flutter/material.dart';
import '../services/shortcut_service.dart';

/// Wraps a screen widget so that pressing Esc on Windows Desktop directly navigates back
/// without showing the close confirmation dialog.
class DirectBackScope extends StatefulWidget {
  final Widget child;

  const DirectBackScope({
    super.key,
    required this.child,
  });

  @override
  State<DirectBackScope> createState() => _DirectBackScopeState();
}

class _DirectBackScopeState extends State<DirectBackScope> {
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) {
        shortcutService.unregisterDirectBackRoute(_route!);
      }
      _route = route;
      shortcutService.registerDirectBackRoute(route);
    }
  }

  @override
  void dispose() {
    if (_route != null) {
      shortcutService.unregisterDirectBackRoute(_route!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
