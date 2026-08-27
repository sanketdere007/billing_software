import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/platform_helper.dart';
import '../widgets/close_confirmation_dialog.dart';
import '../widgets/screen_already_open_dialog.dart';
import '../widgets/database_backup_dialog.dart';
import '../widgets/app_message_dialog.dart';
import '../services/database_backup_service.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/sales/sales_order/add_sales_order_screen.dart';
import '../screens/sales/sales_entry/add_sales_entry_screen.dart';
import '../screens/sales/sales_return/add_sales_return_screen.dart';
import '../screens/purchases/purchase_order/add_purchase_order_screen.dart';
import '../screens/purchases/purchase_entry/add_purchase_entry_screen.dart';
import '../screens/purchases/purchase_return/add_purchase_return_screen.dart';
import '../screens/customers/add_customer_screen.dart';

/// Route name constants for ERP screens managed by shortcuts.
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String customerAdd = '/customers/add';
  static const String salesOrderAdd = '/sales/order/add';
  static const String salesEntryAdd = '/sales/entry/add';
  static const String salesReturnAdd = '/sales/return/add';
  static const String purchaseOrderAdd = '/purchases/order/add';
  static const String purchaseEntryAdd = '/purchases/entry/add';
  static const String purchaseReturnAdd = '/purchases/return/add';
  static const String paymentScreen = '/accounts/payment';
  static const String receiptEntryScreen = '/accounts/receipt';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String helpSupport = '/help-support';
}

/// Navigator observer that tracks active routes in the navigation stack.
class ShortcutRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> routeStack = [];

  Route<dynamic>? get currentRoute =>
      routeStack.isNotEmpty ? routeStack.last : null;

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
  bool _isScreenAlreadyOpenDialogOpen = false;
  bool _isBackupDialogOpen = false;
  bool _isLogoutDialogOpen = false;

  bool get isBackupDialogOpen => _isBackupDialogOpen;
  bool get isLogoutDialogOpen => _isLogoutDialogOpen;

  /// Transaction route names where only one transaction screen can be open at a time.
  static const Set<String> transactionRoutes = {
    AppRoutes.salesOrderAdd,
    AppRoutes.salesEntryAdd,
    AppRoutes.salesReturnAdd,
    AppRoutes.purchaseOrderAdd,
    AppRoutes.purchaseEntryAdd,
    AppRoutes.purchaseReturnAdd,
  };

  /// Checks if any transaction screen is currently open in the route stack.
  bool get isTransactionScreenOpen {
    return routeObserver.routeStack.any(
      (r) => transactionRoutes.contains(r.settings.name),
    );
  }

  /// Gets the route of the currently open transaction screen in the route stack, if any.
  Route<dynamic>? get openTransactionRoute {
    try {
      return routeObserver.routeStack.firstWhere(
        (r) => transactionRoutes.contains(r.settings.name),
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if a route name represents a transaction screen.
  static bool isTransactionRoute(String? routeName) {
    if (routeName == null) return false;
    return transactionRoutes.contains(routeName);
  }

  /// Direct-back route names that should pop directly on Esc without confirmation.
  static Set<String> directBackRoutes = {
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
  List<ErpShortcutItem> get availableShortcuts => [
    const ErpShortcutItem(
      label: 'Close Screen Confirmation',
      keyDisplay: 'Esc',
      category: 'General',
    ),
    ErpShortcutItem(
      label: 'Backup Database',
      keyDisplay: 'Ctrl + Shift + B',
      category: 'General',
      customAction: () => triggerDatabaseBackup(),
    ),
    ErpShortcutItem(
      label: 'Logout',
      keyDisplay: 'Ctrl + Shift + L',
      category: 'General',
      customAction: () => triggerLogout(),
    ),
    const ErpShortcutItem(
      label: 'New Customer',
      keyDisplay: 'Ctrl + C',
      category: 'Master',
      routeName: AppRoutes.customerAdd,
      screenBuilder: _buildAddCustomer,
    ),
    const ErpShortcutItem(
      label: 'Sales Order',
      keyDisplay: 'F4',
      category: 'Sales',
      routeName: AppRoutes.salesOrderAdd,
      screenBuilder: _buildAddSalesOrder,
    ),
    const ErpShortcutItem(
      label: 'Sales Entry (Invoice)',
      keyDisplay: 'F5',
      category: 'Sales',
      routeName: AppRoutes.salesEntryAdd,
      screenBuilder: _buildAddSalesEntry,
    ),
    const ErpShortcutItem(
      label: 'Sales Return',
      keyDisplay: 'Ctrl + F5',
      category: 'Sales',
      routeName: AppRoutes.salesReturnAdd,
      screenBuilder: _buildAddSalesReturn,
    ),
    const ErpShortcutItem(
      label: 'Purchase Order',
      keyDisplay: 'F6',
      category: 'Purchase',
      routeName: AppRoutes.purchaseOrderAdd,
      screenBuilder: _buildAddPurchaseOrder,
    ),
    const ErpShortcutItem(
      label: 'Purchase Entry',
      keyDisplay: 'F7',
      category: 'Purchase',
      routeName: AppRoutes.purchaseEntryAdd,
      screenBuilder: _buildAddPurchaseEntry,
    ),
    const ErpShortcutItem(
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
    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Handle Esc shortcut
    if (key == LogicalKeyboardKey.escape) {
      return _handleEscapeKey();
    }

    // Ctrl + Shift + B: Backup Database
    if (isCtrlPressed && isShiftPressed && key == LogicalKeyboardKey.keyB) {
      if (isLoginOrSplashActive) return false;
      triggerDatabaseBackup();
      return true;
    }

    // Ctrl + Shift + L: Logout
    if (isCtrlPressed && isShiftPressed && key == LogicalKeyboardKey.keyL) {
      if (isLoginOrSplashActive) return false;
      triggerLogout();
      return true;
    }

    // Condition 3: Check if text input is actively receiving keyboard input
    final bool isTextInputFocused = _isTextInputActive();

    // Ctrl + C: Open New Customer ONLY when not actively inside a text field
    if (isCtrlPressed && !isShiftPressed && key == LogicalKeyboardKey.keyC) {
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
        navigateToNamedScreen(
          AppRoutes.purchaseReturnAdd,
          _buildAddPurchaseReturn,
        );
        return true;
      } else {
        // F7: Purchase Entry
        navigateToNamedScreen(
          AppRoutes.purchaseEntryAdd,
          _buildAddPurchaseEntry,
        );
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

  /// Checks if login or splash screen is currently the active top route.
  bool get isLoginOrSplashActive {
    final currentRoute = routeObserver.currentRoute;
    if (currentRoute != null) {
      final name = currentRoute.settings.name;
      if (name == AppRoutes.login ||
          name == '/login' ||
          name == 'login' ||
          name == '/splash' ||
          name == 'splash') {
        return true;
      }
    }
    return false;
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

  /// Triggers the Database Backup flow:
  /// 1. Asks user for confirmation via Dialog.
  /// 2. If confirmed, displays progress dialog and invokes API.
  /// 3. Closes progress dialog and displays success/error SnackBar.
  Future<void> triggerDatabaseBackup([BuildContext? context]) async {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;
    if (_isBackupDialogOpen ||
        _isLogoutDialogOpen ||
        _isConfirmationDialogOpen ||
        _isScreenAlreadyOpenDialogOpen) {
      return;
    }

    _isBackupDialogOpen = true;
    try {
      final confirmed = await showDatabaseBackupConfirmationDialog(
        context: ctx,
        title: 'Database Backup',
        message: 'Do you want to take a database backup?',
        icon: Icons.storage_rounded,
        iconColor: Colors.blue.shade700,
      );

      if (confirmed != true) return;

      final progressContext = ctx.mounted ? ctx : navigatorKey.currentContext;
      if (progressContext == null) return;

      showBackupProgressDialog(progressContext);

      try {
        final response = await databaseBackupService.createBackup();

        if (navigatorKey.currentState != null &&
            navigatorKey.currentState!.canPop()) {
          Navigator.of(progressContext, rootNavigator: true).pop();
        }

        final snackContext = ctx.mounted ? ctx : navigatorKey.currentContext;
        if (snackContext != null) {
          final message = response.message.isNotEmpty
              ? response.message
              : 'Database backup completed successfully.';
          ScaffoldMessenger.of(snackContext).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (navigatorKey.currentState != null &&
            navigatorKey.currentState!.canPop()) {
          Navigator.of(progressContext, rootNavigator: true).pop();
        }

        final snackContext = ctx.mounted ? ctx : navigatorKey.currentContext;
        if (snackContext != null) {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(snackContext).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      _isBackupDialogOpen = false;
    }
  }

  /// Triggers the Logout flow:
  /// 1. Asks user for confirmation via Dialog with options to backup before logout.
  /// 2. If 'Yes' (Backup & Logout): Shows progress, backs up DB, then logs out.
  /// 3. If 'No' (Logout without backup): Logs out immediately.
  /// 4. If dismissed/cancelled: Does nothing.
  Future<void> triggerLogout([BuildContext? context]) async {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;
    if (_isLogoutDialogOpen ||
        _isBackupDialogOpen ||
        _isConfirmationDialogOpen ||
        _isScreenAlreadyOpenDialogOpen) {
      return;
    }

    _isLogoutDialogOpen = true;
    try {
      final confirmed = await showDatabaseBackupConfirmationDialog(
        context: ctx,
        title: 'Logout',
        message: 'Do you want to take a database backup before logging out?',
        icon: Icons.logout_rounded,
        iconColor: Colors.red.shade600,
      );

      // If user dismissed dialog (Escape or outside click), do nothing
      if (confirmed == null) {
        return;
      }

      final activeContext = ctx.mounted ? ctx : navigatorKey.currentContext;
      if (activeContext == null) return;

      if (confirmed == true) {
        // User selected Yes: Call backup API first
        showBackupProgressDialog(activeContext);

        try {
          await databaseBackupService.createBackup();

          if (navigatorKey.currentState != null &&
              navigatorKey.currentState!.canPop()) {
            Navigator.of(activeContext, rootNavigator: true).pop();
          }

          final snackContext = ctx.mounted ? ctx : navigatorKey.currentContext;
          if (snackContext != null) {
            ScaffoldMessenger.of(snackContext).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Database backup completed successfully.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Automatically perform logout and navigate to Login Screen
          await authService.logout();
          final finalNavState = navigatorKey.currentState;
          if (finalNavState != null) {
            finalNavState.pushAndRemoveUntil(
              MaterialPageRoute(
                settings: const RouteSettings(name: AppRoutes.login),
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          if (navigatorKey.currentState != null &&
              navigatorKey.currentState!.canPop()) {
            Navigator.of(activeContext, rootNavigator: true).pop();
          }

          final snackContext = ctx.mounted ? ctx : navigatorKey.currentContext;
          if (snackContext != null) {
            final errorMessage = e.toString().replaceFirst('Exception: ', '');
            ScaffoldMessenger.of(snackContext).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // User selected No: Skip backup process and logout immediately
        await authService.logout();
        final finalNavState = navigatorKey.currentState;
        if (finalNavState != null) {
          finalNavState.pushAndRemoveUntil(
            MaterialPageRoute(
              settings: const RouteSettings(name: AppRoutes.login),
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      }
    } finally {
      _isLogoutDialogOpen = false;
    }
  }

  DateTime _lastEscapeTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Handle Escape key logic
  bool _handleEscapeKey() {
    final now = DateTime.now();
    if (now.difference(_lastEscapeTime).inMilliseconds < 300) {
      return true; // Ignore rapid multiple presses
    }
    _lastEscapeTime = now;

    // Condition: If user is on Dashboard screen, pressing Esc does nothing.
    if (isDashboardActive) {
      return false;
    }

    // If a dialog is already displayed, allow that dialog's own handler to close itself
    if (_isConfirmationDialogOpen ||
        _isScreenAlreadyOpenDialogOpen ||
        AppMessageDialog.isShowing) {
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

  /// Navigates to a target screen ensuring single-instance and single-transaction rules:
  /// 1. If target is a transaction screen and ANOTHER transaction screen is already open:
  ///    - Does NOT open the new screen.
  ///    - Displays the "Screen Already Open" dialog.
  /// 2. If target is already on the screen (active top route) -> does nothing (no duplicate, no reload).
  /// 3. If target screen is already open in the stack below -> brings it to front and focuses it.
  /// 4. If target screen is not open -> navigates to it normally.
  Future<void> navigateToNamedScreen(
    String routeName,
    Widget Function() screenBuilder, {
    BuildContext? context,
  }) async {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    final stack = routeObserver.routeStack;

    // Check transaction screen rule
    if (transactionRoutes.contains(routeName)) {
      Route<dynamic>? activeTransaction;
      for (final r in stack) {
        if (transactionRoutes.contains(r.settings.name)) {
          activeTransaction = r;
          break;
        }
      }

      if (activeTransaction != null) {
        // If the open transaction screen is the SAME as the target screen
        if (activeTransaction.settings.name == routeName) {
          if (stack.isNotEmpty && stack.last.settings.name == routeName) {
            return;
          }
          navState.popUntil((r) => r.settings.name == routeName);
          return;
        }

        // Another transaction screen is already open -> Show dialog and do not open new screen
        final dialogContext = context ?? navigatorKey.currentContext;
        if (dialogContext != null) {
          _isScreenAlreadyOpenDialogOpen = true;
          try {
            await showScreenAlreadyOpenDialog(dialogContext);
          } finally {
            _isScreenAlreadyOpenDialogOpen = false;
          }
        }
        return;
      }
    }

    // 1. If current top route is already the target screen, do nothing!
    if (stack.isNotEmpty && stack.last.settings.name == routeName) {
      return;
    }

    // 2. If screen already exists lower in the route stack, bring it to front
    final bool isAlreadyInStack = stack.any(
      (r) => r.settings.name == routeName,
    );
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
