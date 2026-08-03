import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/platform_helper.dart';
import '../widgets/close_confirmation_dialog.dart';
import '../screens/sales/sales_order/add_sales_order_screen.dart';
import '../screens/sales/sales_entry/add_sales_entry_screen.dart';
import '../screens/sales/sales_return/add_sales_return_screen.dart';
import '../screens/purchases/purchase_order/add_purchase_order_screen.dart';
import '../screens/purchases/purchase_entry/add_purchase_entry_screen.dart';
import '../screens/purchases/purchase_return/add_purchase_return_screen.dart';
import '../screens/customers/add_customer_screen.dart';

/// Route name constants for ERP screens managed by shortcuts.
class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String customerAdd = '/customers/add';
  static const String salesOrderAdd = '/sales/order/add';
  static const String salesEntryAdd = '/sales/entry/add';
  static const String salesReturnAdd = '/sales/return/add';
  static const String purchaseOrderAdd = '/purchases/order/add';
  static const String purchaseEntryAdd = '/purchases/entry/add';
  static const String purchaseReturnAdd = '/purchases/return/add';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String helpSupport = '/help-support';
}

/// Navigator observer that tracks active routes in the navigation stack.
class ShortcutRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> routeStack = [];

  Route<dynamic>? get currentRoute => routeStack.isNotEmpty ? routeStack.last : null;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    routeStack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    routeStack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    routeStack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final index = routeStack.indexOf(oldRoute);
      if (index != -1) {
        if (newRoute != null) {
          routeStack[index] = newRoute;
        } else {
          routeStack.removeAt(index);
        }
        return;
      }
    }
    if (newRoute != null) {
      routeStack.add(newRoute);
    }
  }
}

/// Representation of an ERP shortcut definition for extensibility.
class ErpShortcutItem {
  final String label;
  final String keyDisplay;
  final String category;
  final String? routeName;
  final Widget Function()? screenBuilder;
  final VoidCallback? customAction;

  const ErpShortcutItem({
    required this.label,
    required this.keyDisplay,
    required this.category,
    this.routeName,
    this.screenBuilder,
    this.customAction,
  });
}

/// Central service managing global keyboard shortcuts on Windows Desktop.
/// Strictly disables execution on non-Windows platforms (Web, Android, iOS, macOS, Linux).
class ShortcutService {
  static final ShortcutService _instance = ShortcutService._internal();
  factory ShortcutService() => _instance;
  ShortcutService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ShortcutRouteObserver routeObserver = ShortcutRouteObserver();

  bool _isInitialized = false;
  bool _isConfirmationDialogOpen = false;

  /// Direct-back route names that should pop directly on Esc without confirmation.
  static  Set<String> directBackRoutes = {
    AppRoutes.settings,
    AppRoutes.about,
    AppRoutes.helpSupport,
    '/settings',
    'settings',
    '/about',
    'about',
    '/about-us',
    'about-us',
    '/about_us',
    'about_us',
    '/help-support',
    'help-support',
    '/help_support',
    'help_support',
    '/help',
    'help',
    '/support',
    'support',
  };

  final Set<Route<dynamic>> _directBackRouteInstances = <Route<dynamic>>{};

  void registerDirectBackRoute(Route<dynamic> route) {
    _directBackRouteInstances.add(route);
  }

  void unregisterDirectBackRoute(Route<dynamic> route) {
    _directBackRouteInstances.remove(route);
  }

  /// Checks if the current active top route is a direct-back screen (Settings, About Us, Help & Support).
  bool get isDirectBackActive {
    final currentRoute = routeObserver.currentRoute;
    if (currentRoute == null) return false;

    // 1. Check if route name matches any direct-back route name
    final name = currentRoute.settings.name;
    if (name != null && directBackRoutes.contains(name)) {
      return true;
    }

    // 2. Check if route instance was registered directly
    if (_directBackRouteInstances.contains(currentRoute)) {
      return true;
    }

    return false;
  }

  /// Registry of ERP shortcuts for easy display and future extensions.
  List<ErpShortcutItem> get availableShortcuts => const [
    ErpShortcutItem(
      label: 'Close Screen Confirmation',
      keyDisplay: 'Esc',
      category: 'General',
    ),
    ErpShortcutItem(
      label: 'New Customer',
      keyDisplay: 'Ctrl + C',
      category: 'Master',
      routeName: AppRoutes.customerAdd,
      screenBuilder: _buildAddCustomer,
    ),
    ErpShortcutItem(
      label: 'Sales Order',
      keyDisplay: 'F4',
      category: 'Sales',
      routeName: AppRoutes.salesOrderAdd,
      screenBuilder: _buildAddSalesOrder,
    ),
    ErpShortcutItem(
      label: 'Sales Entry (Invoice)',
      keyDisplay: 'F5',
      category: 'Sales',
      routeName: AppRoutes.salesEntryAdd,
      screenBuilder: _buildAddSalesEntry,
    ),
    ErpShortcutItem(
      label: 'Sales Return',
      keyDisplay: 'Ctrl + F5',
      category: 'Sales',
      routeName: AppRoutes.salesReturnAdd,
      screenBuilder: _buildAddSalesReturn,
    ),
    ErpShortcutItem(
      label: 'Purchase Order',
      keyDisplay: 'F6',
      category: 'Purchase',
      routeName: AppRoutes.purchaseOrderAdd,
      screenBuilder: _buildAddPurchaseOrder,
    ),
    ErpShortcutItem(
      label: 'Purchase Entry',
      keyDisplay: 'F7',
      category: 'Purchase',
      routeName: AppRoutes.purchaseEntryAdd,
      screenBuilder: _buildAddPurchaseEntry,
    ),
    ErpShortcutItem(
      label: 'Purchase Return',
      keyDisplay: 'Ctrl + F7',
      category: 'Purchase',
      routeName: AppRoutes.purchaseReturnAdd,
      screenBuilder: _buildAddPurchaseReturn,
    ),
  ];

  static Widget _buildAddCustomer() => const AddCustomerScreen();
  static Widget _buildAddSalesOrder() => const AddSalesOrderScreen();
  static Widget _buildAddSalesEntry() => const AddSalesEntryScreen();
  static Widget _buildAddSalesReturn() => const AddSalesReturnScreen();
  static Widget _buildAddPurchaseOrder() => const AddPurchaseOrderScreen();
  static Widget _buildAddPurchaseEntry() => const AddPurchaseEntryScreen();
  static Widget _buildAddPurchaseReturn() => const AddPurchaseReturnScreen();

  /// Initialize global shortcut listener.
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  /// Dispose global shortcut listener.
  void dispose() {
    if (!_isInitialized) return;
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _isInitialized = false;
  }

  /// Global key event handler.
  bool _handleGlobalKeyEvent(KeyEvent event) {
    // Condition 1 & 2: Strictly Windows Desktop only
    if (!PlatformHelper.isWindowsDesktopEffective) {
      return false;
    }

    // Process on KeyDown event only
    if (event is! KeyDownEvent) {
      return false;
    }

    final key = event.logicalKey;
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Handle Esc shortcut
    if (key == LogicalKeyboardKey.escape) {
      return _handleEscapeKey();
    }

    // Condition 3: Check if text input is actively receiving keyboard input
    final bool isTextInputFocused = _isTextInputActive();

    // Ctrl + C: Open New Customer ONLY when not actively inside a text field
    if (isCtrlPressed && key == LogicalKeyboardKey.keyC) {
      if (isTextInputFocused) {
        // Let system copy clipboard text normally
        return false;
      }
      navigateToNamedScreen(AppRoutes.customerAdd, _buildAddCustomer);
      return true;
    }

    // F4: Sales Order
    if (key == LogicalKeyboardKey.f4 && !isCtrlPressed) {
      navigateToNamedScreen(AppRoutes.salesOrderAdd, _buildAddSalesOrder);
      return true;
    }

    // F5 or Ctrl + F5
    if (key == LogicalKeyboardKey.f5) {
      if (isCtrlPressed) {
        // Ctrl + F5: Sales Return
        navigateToNamedScreen(AppRoutes.salesReturnAdd, _buildAddSalesReturn);
        return true;
      } else {
        // F5: Sales Entry
        navigateToNamedScreen(AppRoutes.salesEntryAdd, _buildAddSalesEntry);
        return true;
      }
    }

    // F6: Purchase Order
    if (key == LogicalKeyboardKey.f6 && !isCtrlPressed) {
      navigateToNamedScreen(AppRoutes.purchaseOrderAdd, _buildAddPurchaseOrder);
      return true;
    }

    // F7 or Ctrl + F7
    if (key == LogicalKeyboardKey.f7) {
      if (isCtrlPressed) {
        // Ctrl + F7: Purchase Return
        navigateToNamedScreen(AppRoutes.purchaseReturnAdd, _buildAddPurchaseReturn);
        return true;
      } else {
        // F7: Purchase Entry
        navigateToNamedScreen(AppRoutes.purchaseEntryAdd, _buildAddPurchaseEntry);
        return true;
      }
    }

    return false;
  }

  /// Check if the currently focused widget is an editable text input.
  bool _isTextInputActive() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final context = focus.context;
    if (context == null) return false;

    if (context.widget is EditableText) {
      return true;
    }
    return context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Checks if the user is currently on the Dashboard screen or at root.
  bool get isDashboardActive {
    final navState = navigatorKey.currentState;
    if (navState == null) return false;

    // 1. If navigator cannot pop, we are at the root level (Dashboard screen)
    if (!navState.canPop()) {
      return true;
    }

    // 2. Check current top route in routeStack
    final currentRoute = routeObserver.currentRoute;
    if (currentRoute != null) {
      if (currentRoute.isFirst) {
        return true;
      }
      final name = currentRoute.settings.name;
      if (name == AppRoutes.dashboard || name == '/' || name == 'dashboard') {
        return true;
      }
    }

    return false;
  }

  /// Handle Escape key logic
  bool _handleEscapeKey() {
    // Condition: If user is on Dashboard screen, pressing Esc does nothing.
    if (isDashboardActive) {
      return false;
    }

    // If confirmation dialog is already displayed, allow dialog's own handler to close itself
    if (_isConfirmationDialogOpen) {
      return false;
    }

    final navState = navigatorKey.currentState;
    if (navState == null) return false;

    // Direct back for Settings, About Us, Help & Support (no confirmation dialog)
    if (isDirectBackActive) {
      if (navState.canPop()) {
        navState.pop();
        return true;
      }
      return false;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return false;

    _showCloseConfirmation(context);
    return true;
  }

  /// Open confirmation dialog and pop current screen if confirmed
  Future<void> _showCloseConfirmation(BuildContext context) async {
    _isConfirmationDialogOpen = true;

    try {
      final confirmed = await showCloseConfirmationDialog(context);
      if (confirmed == true) {
        final navState = navigatorKey.currentState;
        if (navState != null && navState.canPop()) {
          navState.pop();
        }
      }
    } finally {
      _isConfirmationDialogOpen = false;
    }
  }

  /// Navigates to a target screen ensuring single-instance behavior:
  /// 1. If already on the screen (active top route) -> does nothing (no duplicate, no reload, no animation).
  /// 2. If the screen is already open in the stack below -> brings it to front and focuses it.
  /// 3. If the screen is not open -> navigates to it normally.
  void navigateToNamedScreen(String routeName, Widget Function() screenBuilder) {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    final stack = routeObserver.routeStack;

    // 1. If current top route is already the target screen, do nothing!
    if (stack.isNotEmpty && stack.last.settings.name == routeName) {
      return;
    }

    // 2. If screen already exists lower in the route stack, bring it to front
    final bool isAlreadyInStack = stack.any((r) => r.settings.name == routeName);
    if (isAlreadyInStack) {
      navState.popUntil((r) => r.settings.name == routeName);
      return;
    }

    // 3. Screen is not open: push normally with RouteSettings
    navState.push(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (_) => screenBuilder(),
      ),
    );
  }
}

final shortcutService = ShortcutService();
