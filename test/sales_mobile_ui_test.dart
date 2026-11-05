import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/screens/sales/sales_entry/add_sales_entry_screen.dart';
import 'package:billing_software/screens/sales/sales_return/add_sales_return_screen.dart';
import 'package:billing_software/utils/platform_helper.dart';

void main() {
  setUp(() {
    PlatformHelper.setOverrideForTesting(null);
    PlatformHelper.setOverrideIsMobileForTesting(null);
  });

  tearDown(() {
    PlatformHelper.setOverrideForTesting(null);
    PlatformHelper.setOverrideIsMobileForTesting(null);
  });

  group('Sales Entry & Sales Return Platform-Based UI Tests', () {
    testWidgets('Sales Entry renders Desktop UI on Windows Desktop',
        (WidgetTester tester) async {
      PlatformHelper.setOverrideForTesting(true);

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AddSalesEntryScreen(),
        ),
      );
      await tester.pump();

      // In Desktop UI, table headers exist
      expect(find.text('Product Name'), findsOneWidget);
      expect(find.text('Selling Price'), findsOneWidget);
      expect(find.text('Gross'), findsOneWidget);
      expect(find.text('Save (F9)'), findsOneWidget);
      expect(find.text('Clear (F10)'), findsOneWidget);
    });

    testWidgets('Sales Entry renders Mobile UI on Mobile platforms with sticky customer & date card',
        (WidgetTester tester) async {
      PlatformHelper.setOverrideForTesting(false);
      PlatformHelper.setOverrideIsMobileForTesting(true);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AddSalesEntryScreen(),
        ),
      );
      await tester.pump();

      // In Mobile UI, sticky customer & date card and mobile layout elements exist
      expect(find.text('Invoice Date (yyyy/MM/dd)'), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);
      expect(find.text('Bill Breakdown'), findsOneWidget);
      expect(find.text('Total Payable (0 items)'), findsOneWidget);
      expect(find.text('No items in this sale'), findsOneWidget);
      // Desktop table header must NOT be present
      expect(find.text('Selling Price'), findsNothing);
    });

    testWidgets('Sales Return renders Desktop UI on Windows Desktop',
        (WidgetTester tester) async {
      PlatformHelper.setOverrideForTesting(true);

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AddSalesReturnScreen(),
        ),
      );
      await tester.pump();

      // In Desktop UI, desktop table headers exist
      expect(find.text('Product Name'), findsOneWidget);
      expect(find.text('Selling Price'), findsOneWidget);
      expect(find.text('Save (F9)'), findsOneWidget);
      expect(find.text('Clear (F10)'), findsOneWidget);
    });

    testWidgets('Sales Return renders Mobile UI on Mobile platforms with sticky customer & date card',
        (WidgetTester tester) async {
      PlatformHelper.setOverrideForTesting(false);
      PlatformHelper.setOverrideIsMobileForTesting(true);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AddSalesReturnScreen(),
        ),
      );
      await tester.pump();

      // In Mobile UI, sticky customer & date card and mobile layout elements exist
      expect(find.text('Return Date (yyyy/MM/dd)'), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);
      expect(find.text('Return Breakdown'), findsOneWidget);
      expect(find.text('Total Return (0 items)'), findsOneWidget);
      expect(find.text('No items in this return'), findsOneWidget);
      // Desktop table header must NOT be present
      expect(find.text('Selling Price'), findsNothing);
    });
  });
}
