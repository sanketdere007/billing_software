import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/utils/platform_helper.dart';
import 'package:billing_software/services/shortcut_service.dart';
import 'package:billing_software/widgets/close_confirmation_dialog.dart';
import 'package:billing_software/widgets/screen_already_open_dialog.dart';
import 'package:billing_software/services/purchase_order_service.dart';
import 'package:billing_software/services/purchase_entry_service.dart';
import 'package:billing_software/services/purchase_return_service.dart';
import 'package:billing_software/models/purchase_order.dart';
import 'package:billing_software/models/purchase_entry.dart';
import 'package:billing_software/models/purchase_return.dart';
import 'package:billing_software/screens/sales/sales_order/add_sales_order_screen.dart';
import 'package:billing_software/screens/sales/sales_entry/add_sales_entry_screen.dart';
import 'package:billing_software/screens/sales/sales_return/add_sales_return_screen.dart';
import 'package:billing_software/screens/purchases/purchase_order/add_purchase_order_screen.dart';
import 'package:billing_software/screens/purchases/purchase_entry/add_purchase_entry_screen.dart';
import 'package:billing_software/screens/purchases/purchase_return/add_purchase_return_screen.dart';
import 'package:billing_software/screens/customers/add_customer_screen.dart';
import 'package:billing_software/screens/dashboard_screen.dart';
import 'package:billing_software/screens/settings_screen.dart';
import 'package:billing_software/screens/about_screen.dart';
import 'package:billing_software/screens/help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformHelper Tests', () {
    tearDown(() {
      PlatformHelper.setOverrideForTesting(null);
    });

    test('Platform override correctly reflects Windows desktop state', () {
      PlatformHelper.setOverrideForTesting(true);
      expect(PlatformHelper.isWindowsDesktopEffective, isTrue);

      PlatformHelper.setOverrideForTesting(false);
      expect(PlatformHelper.isWindowsDesktopEffective, isFalse);
    });
  });

  group('CloseConfirmationDialog Tests', () {
    testWidgets('Dialog renders with title and default "No" focus', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showCloseConfirmationDialog(context);
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      // Tap button to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check dialog elements
      expect(find.text('Close Screen'), findsOneWidget);
      expect(
        find.text('Are you sure you want to close this screen?'),
        findsOneWidget,
      );
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      // Press Enter key while default (No) is selected
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets(
      'Arrow keys switch selection to "Yes" and Enter confirms (returns true)',
      (tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showCloseConfirmationDialog(context);
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Switch to 'Yes' using Left Arrow key
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        // Press Enter to confirm Yes
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(result, isTrue);
      },
    );

    testWidgets('Escape key closes dialog (returns false)', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showCloseConfirmationDialog(context);
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Send Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('ScreenAlreadyOpenDialog Tests', () {
    testWidgets('Dialog renders title, message, and OK button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await showScreenAlreadyOpenDialog(context);
                },
                child: const Text('Trigger Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ScreenAlreadyOpenDialog), findsOneWidget);
      expect(find.text('Screen Already Open'), findsOneWidget);
      expect(
        find.text('Please close the currently open transaction screen before opening a new one.'),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);

      // Tap OK button to dismiss
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
    });

    testWidgets('Enter key closes ScreenAlreadyOpenDialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await showScreenAlreadyOpenDialog(context);
                },
                child: const Text('Trigger Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ScreenAlreadyOpenDialog), findsOneWidget);

      // Send Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
    });

    testWidgets('Escape key closes ScreenAlreadyOpenDialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await showScreenAlreadyOpenDialog(context);
                },
                child: const Text('Trigger Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ScreenAlreadyOpenDialog), findsOneWidget);

      // Send Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
    });
  });

  group('Purchase Services Data Tests', () {
    test('PurchaseOrderService initialization and add order', () async {
      final service = PurchaseOrderService();
      service.initializeDummyData();
      expect(service.orders.isNotEmpty, isTrue);

      final initialCount = service.orders.length;
      final newOrder = PurchaseOrder(
        id: 'TEST-PO-01',
        orderNo: 'PO-TEST-001',
        orderDate: DateTime.now(),
        supplierId: 'SUP-001',
        supplierName: 'Test Supplier',
        products: [],
        subtotal: 1000,
        grandTotal: 1000,
      );

      await service.addOrder(newOrder);
      expect(service.orders.length, initialCount + 1);
    });

    test('PurchaseEntryService initialization and add entry', () async {
      final service = PurchaseEntryService();
      service.initializeDummyData();
      expect(service.entries.isNotEmpty, isTrue);

      final initialCount = service.entries.length;
      final newEntry = PurchaseEntry(
        id: 'TEST-PE-01',
        invoiceNo: 'PINV-TEST-001',
        invoiceDate: DateTime.now(),
        supplierId: 'SUP-001',
        supplierName: 'Test Supplier',
        products: [],
        totalQuantity: 1,
        grossAmount: 500,
        grandTotal: 500,
      );

      await service.addEntry(newEntry);
      expect(service.entries.length, initialCount + 1);
    });

    test('PurchaseReturnService initialization and add return', () async {
      final service = PurchaseReturnService();
      service.initializeDummyData();
      expect(service.returns.isNotEmpty, isTrue);

      final initialCount = service.returns.length;
      final newReturn = PurchaseReturn(
        id: 'TEST-PR-01',
        returnNo: 'PRET-TEST-001',
        returnDate: DateTime.now(),
        invoiceNo: 'PINV-001',
        supplierId: 'SUP-001',
        supplierName: 'Test Supplier',
        products: [],
        totalReturnQuantity: 1,
        returnAmount: 200,
        grandRefund: 200,
        refundMode: 'Cash',
      );

      await service.addReturn(newReturn);
      expect(service.returns.length, initialCount + 1);
    });
  });

  group('Single Transaction Screen Validation & Navigation Tests', () {
    setUp(() {
      PlatformHelper.setOverrideForTesting(true);
      shortcutService.init();
    });

    tearDown(() {
      PlatformHelper.setOverrideForTesting(null);
      shortcutService.dispose();
    });

    testWidgets('Non-Windows platform ignores all shortcut keys', (
      tester,
    ) async {
      PlatformHelper.setOverrideForTesting(false); // Simulate Web/Android/iOS

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: shortcutService.navigatorKey,
          navigatorObservers: [shortcutService.routeObserver],
          home: const Scaffold(body: Text('Home Screen')),
        ),
      );

      // Send F4 key
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();

      // Should still be on Home Screen, AddSalesOrderScreen not pushed
      expect(find.byType(AddSalesOrderScreen), findsNothing);
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets(
      'F4 opens AddSalesOrderScreen when not open, repeated F4 does nothing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: const Scaffold(body: Text('Home Screen')),
          ),
        );

        // 1. Initial press F4 -> Opens screen
        await tester.sendKeyEvent(LogicalKeyboardKey.f4);
        await tester.pumpAndSettle();
        expect(find.byType(AddSalesOrderScreen), findsOneWidget);
        expect(shortcutService.isTransactionScreenOpen, isTrue);

        final initialStackCount =
            shortcutService.routeObserver.routeStack.length;

        // 2. Press F4 again while already on the screen -> Should do nothing (no duplicate, no dialog)
        await tester.sendKeyEvent(LogicalKeyboardKey.f4);
        await tester.pumpAndSettle();

        expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
        expect(find.byType(AddSalesOrderScreen), findsOneWidget);
        expect(
          shortcutService.routeObserver.routeStack.length,
          initialStackCount,
        );
      },
    );

    testWidgets(
      'Prevent multiple transaction screens: When Sales Entry is open, opening Purchase Entry shows Screen Already Open dialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: const Scaffold(body: Text('Dashboard Overview')),
          ),
        );

        // 1. Open Sales Entry via F5
        await tester.sendKeyEvent(LogicalKeyboardKey.f5);
        await tester.pumpAndSettle();
        expect(find.byType(AddSalesEntryScreen), findsOneWidget);
        expect(shortcutService.isTransactionScreenOpen, isTrue);

        // 2. Try to open Purchase Entry via F7 while Sales Entry is open
        await tester.sendKeyEvent(LogicalKeyboardKey.f7);
        await tester.pumpAndSettle();

        // 3. Purchase Entry must NOT open; ScreenAlreadyOpenDialog must be shown
        expect(find.byType(AddPurchaseEntryScreen), findsNothing);
        expect(find.byType(ScreenAlreadyOpenDialog), findsOneWidget);
        expect(find.text('Screen Already Open'), findsOneWidget);
        expect(
          find.text('Please close the currently open transaction screen before opening a new one.'),
          findsOneWidget,
        );

        // 4. Dismiss dialog using OK button
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
        expect(find.byType(AddSalesEntryScreen), findsOneWidget);

        // 5. Try opening another transaction screen: Purchase Return (Ctrl+F7)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.f7);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(find.byType(AddPurchaseReturnScreen), findsNothing);
        expect(find.byType(ScreenAlreadyOpenDialog), findsOneWidget);

        // Dismiss with Enter
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
        expect(find.byType(AddSalesEntryScreen), findsOneWidget);

        // 6. Close Sales Entry using Esc -> Yes
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(CloseConfirmationDialog), findsOneWidget);

        // Switch to Yes and confirm
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(AddSalesEntryScreen), findsNothing);
        expect(shortcutService.isTransactionScreenOpen, isFalse);

        // 7. Now Purchase Entry can open normally!
        await tester.sendKeyEvent(LogicalKeyboardKey.f7);
        await tester.pumpAndSettle();

        expect(find.byType(AddPurchaseEntryScreen), findsOneWidget);
        expect(shortcutService.isTransactionScreenOpen, isTrue);
      },
    );

    testWidgets(
      'Mutual exclusion works between Sales Return and Purchase Order',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: const Scaffold(body: Text('Dashboard Overview')),
          ),
        );

        // 1. Open Sales Return via Ctrl+F5
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.f5);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(find.byType(AddSalesReturnScreen), findsOneWidget);

        // 2. Try to open Purchase Order via F6
        await tester.sendKeyEvent(LogicalKeyboardKey.f6);
        await tester.pumpAndSettle();

        expect(find.byType(AddPurchaseOrderScreen), findsNothing);
        expect(find.byType(ScreenAlreadyOpenDialog), findsOneWidget);

        // Close dialog via Esc
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
        expect(find.byType(AddSalesReturnScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Non-transaction screen (Customer Master) can open when transaction screen is open, but another transaction screen cannot',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: const Scaffold(body: Text('Dashboard Overview')),
          ),
        );

        // 1. Open Purchase Entry via F7
        await tester.sendKeyEvent(LogicalKeyboardKey.f7);
        await tester.pumpAndSettle();
        expect(find.byType(AddPurchaseEntryScreen), findsOneWidget);

        // 2. Open Add Customer via Ctrl+C (non-transaction screen)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(find.byType(AddCustomerScreen), findsOneWidget);

        // 3. From Customer Screen, try to open Sales Entry (F5)
        await tester.sendKeyEvent(LogicalKeyboardKey.f5);
        await tester.pumpAndSettle();

        // Should show ScreenAlreadyOpenDialog because Purchase Entry is still open in stack
        expect(find.byType(AddSalesEntryScreen), findsNothing);
        expect(find.byType(ScreenAlreadyOpenDialog), findsOneWidget);

        // Dismiss dialog
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(ScreenAlreadyOpenDialog), findsNothing);
        expect(find.byType(AddCustomerScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Dashboard + Esc does nothing (no confirmation dialog, stays on Dashboard)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: const Scaffold(body: Text('Dashboard Overview')),
          ),
        );

        expect(shortcutService.isDashboardActive, isTrue);

        // Press Esc on Dashboard
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Ensure no confirmation dialog appeared
        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.text('Dashboard Overview'), findsOneWidget);
      },
    );

    testWidgets(
      'Sales Entry (or other child screen) + Esc shows close confirmation dialog and closes on Yes',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: const Scaffold(body: Text('Dashboard Overview')),
          ),
        );

        // Navigate to Sales Entry using shortcut F5
        await tester.sendKeyEvent(LogicalKeyboardKey.f5);
        await tester.pumpAndSettle();

        expect(shortcutService.isDashboardActive, isFalse);
        expect(find.byType(AddSalesEntryScreen), findsOneWidget);

        // Press Esc on Sales Entry -> Shows Confirmation Dialog
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(CloseConfirmationDialog), findsOneWidget);
        expect(
          find.text('Are you sure you want to close this screen?'),
          findsOneWidget,
        );

        // Dialog default is No -> Press Enter -> Dialog closes, screen remains open
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.byType(AddSalesEntryScreen), findsOneWidget);

        // Press Esc again -> Dialog re-opens
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(CloseConfirmationDialog), findsOneWidget);

        // Switch to 'Yes' using Left Arrow key
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        // Press Enter to confirm Yes -> Pops Sales Entry screen back to Dashboard
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.byType(AddSalesEntryScreen), findsNothing);
        expect(find.text('Dashboard Overview'), findsOneWidget);
        expect(shortcutService.isDashboardActive, isTrue);

        // Pressing Esc on Dashboard now does nothing
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.text('Dashboard Overview'), findsOneWidget);
      },
    );

    testWidgets('Non-Windows platform ignores Esc on child screens as well', (
      tester,
    ) async {
      PlatformHelper.setOverrideForTesting(false); // Simulate Web/Android/iOS

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: shortcutService.navigatorKey,
          navigatorObservers: [shortcutService.routeObserver],
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: AppRoutes.customerAdd),
                    builder: (_) => const AddCustomerScreen(),
                  ),
                );
              },
              child: const Text('Open Customer'),
            ),
          ),
        ),
      );

      // Open Customer Screen manually via tap
      await tester.tap(find.text('Open Customer'));
      await tester.pumpAndSettle();

      expect(find.byType(AddCustomerScreen), findsOneWidget);

      // Send Esc key on non-Windows
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Confirmation dialog should NOT appear
      expect(find.byType(CloseConfirmationDialog), findsNothing);
      expect(find.byType(AddCustomerScreen), findsOneWidget);
    });

    testWidgets(
      'SettingsScreen + Esc navigates back directly without confirmation dialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: AppRoutes.settings),
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Text('Open Settings'),
              ),
            ),
          ),
        );

        // Open Settings screen
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(shortcutService.isDashboardActive, isFalse);
        expect(shortcutService.isDirectBackActive, isTrue);

        // Press Esc on Settings Screen
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Should be directly back to home without any confirmation dialog
        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.text('Open Settings'), findsOneWidget);
      },
    );

    testWidgets(
      'AboutScreen + Esc navigates back directly without confirmation dialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: AppRoutes.about),
                      builder: (_) => const AboutScreen(),
                    ),
                  );
                },
                child: const Text('Open About'),
              ),
            ),
          ),
        );

        // Open About screen
        await tester.tap(find.text('Open About'));
        await tester.pumpAndSettle();

        expect(find.byType(AboutScreen), findsOneWidget);
        expect(shortcutService.isDashboardActive, isFalse);
        expect(shortcutService.isDirectBackActive, isTrue);

        // Press Esc on About Screen
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Should be directly back to home without any confirmation dialog
        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.byType(AboutScreen), findsNothing);
        expect(find.text('Open About'), findsOneWidget);
      },
    );

    testWidgets(
      'HelpSupportScreen + Esc navigates back directly without confirmation dialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: AppRoutes.helpSupport),
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                },
                child: const Text('Open HelpSupport'),
              ),
            ),
          ),
        );

        // Open Help & Support screen
        await tester.tap(find.text('Open HelpSupport'));
        await tester.pumpAndSettle();

        expect(find.byType(HelpSupportScreen), findsOneWidget);
        expect(shortcutService.isDashboardActive, isFalse);
        expect(shortcutService.isDirectBackActive, isTrue);

        // Press Esc on Help & Support Screen
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Should be directly back to home without any confirmation dialog
        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.byType(HelpSupportScreen), findsNothing);
        expect(find.text('Open HelpSupport'), findsOneWidget);
      },
    );

    testWidgets(
      'SettingsScreen without RouteSettings (using DirectBackScope) + Esc navigates back directly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: shortcutService.navigatorKey,
            navigatorObservers: [shortcutService.routeObserver],
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Text('Open Unnamed Settings'),
              ),
            ),
          ),
        );

        // Open unnamed Settings screen
        await tester.tap(find.text('Open Unnamed Settings'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(shortcutService.isDirectBackActive, isTrue);

        // Press Esc
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Should be directly back to home without confirmation dialog
        expect(find.byType(CloseConfirmationDialog), findsNothing);
        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.text('Open Unnamed Settings'), findsOneWidget);
      },
    );
  });
}
