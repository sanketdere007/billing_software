import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/utils/platform_helper.dart';
import 'package:billing_software/widgets/save_clear_shortcuts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    PlatformHelper.setOverrideForTesting(null);
  });

  Future<void> pumpHarness(
    WidgetTester tester, {
    required VoidCallback onSave,
    required VoidCallback onClear,
    bool nested = false,
  }) async {
    Widget body = SaveClearShortcuts(
      onSave: onSave,
      onClear: onClear,
      child: Column(
        children: [
          const TextField(key: Key('field')),
          ElevatedButton(onPressed: () {}, child: const Text('Action')),
        ],
      ),
    );

    if (nested) {
      body = SaveClearShortcuts(
        onSave: onSave,
        onClear: onClear,
        child: body,
      );
    }

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  }

  testWidgets('F1 and F2 work on first open', (tester) async {
    PlatformHelper.setOverrideForTesting(true);
    var saveCount = 0;
    var clearCount = 0;

    await pumpHarness(
      tester,
      onSave: () => saveCount++,
      onClear: () => clearCount++,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    expect(saveCount, 1);
    expect(clearCount, 1);
  });

  testWidgets('F1 and F2 keep working after TextField focus and button tap', (
    tester,
  ) async {
    PlatformHelper.setOverrideForTesting(true);
    var saveCount = 0;
    var clearCount = 0;

    await pumpHarness(
      tester,
      onSave: () => saveCount++,
      onClear: () => clearCount++,
    );

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    expect(saveCount, 1);
    expect(clearCount, 1);

    await tester.tap(find.text('Action'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    expect(saveCount, 2);
    expect(clearCount, 2);
  });

  testWidgets('F1 and F2 keep working after a dialog is opened and closed', (
    tester,
  ) async {
    PlatformHelper.setOverrideForTesting(true);
    var saveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaveClearShortcuts(
            onSave: () => saveCount++,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(title: Text('Dialog')),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsOneWidget);

    // Underlying screen must not save while a dialog route is on top.
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    expect(saveCount, 0);

    Navigator.of(tester.element(find.text('Dialog'))).pop();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    expect(saveCount, 1);
  });

  testWidgets('nested SaveClearShortcuts invoke save only once', (tester) async {
    PlatformHelper.setOverrideForTesting(true);
    var saveCount = 0;

    await pumpHarness(
      tester,
      onSave: () => saveCount++,
      onClear: () {},
      nested: true,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    expect(saveCount, 1);
  });

  testWidgets('shortcuts are ignored when not on Windows', (tester) async {
    PlatformHelper.setOverrideForTesting(false);
    var saveCount = 0;

    await pumpHarness(
      tester,
      onSave: () => saveCount++,
      onClear: () {},
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    expect(saveCount, 0);
  });
}
