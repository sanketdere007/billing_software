import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/utils/platform_helper.dart';
import 'package:billing_software/screens/sales/sales_entry/payment_mode_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    PlatformHelper.setOverrideForTesting(null);
  });

  Future<void> openDialog(
    WidgetTester tester, {
    double payableAmount = 1000,
    Future<bool> Function(SalesPaymentDetails details)? onConfirm,
    ValueChanged<SalesPaymentDetails?>? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                final result = await showPaymentModeDialog(
                  context,
                  payableAmount: payableAmount,
                  onConfirm: onConfirm,
                );
                onResult?.call(result);
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
  }

  Future<void> tapConfirm(WidgetTester tester) async {
    final finder = find.byKey(const Key('payment-mode-confirm'));
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  group('SalesPaymentDetails', () {
    test('maps cash payment onto cash amount and paid/balance', () {
      final details = SalesPaymentDetails(
        mode: SalesPaymentMode.cash,
        amount: 800,
      );
      expect(details.cashAmount, 800);
      expect(details.upiAmount, 0);
      expect(details.paidAmountFor(1000), 800);
      expect(details.balanceAmountFor(1000), 200);
      expect(details.otherPaymentType, isEmpty);
    });

    test('other amount maps to otherAmount', () {
      final details = SalesPaymentDetails(
        mode: SalesPaymentMode.other,
        amount: 1000,
      );
      expect(details.otherAmount, 1000);
      expect(details.paidAmountFor(1000), 1000);
      expect(details.balanceAmountFor(1000), 0);
      expect(details.otherPaymentType, SalesPaymentMode.other);
    });

    test('credit is unpaid balance and is not collected', () {
      final details = SalesPaymentDetails(
        amounts: {SalesPaymentMode.cash: 400, SalesPaymentMode.credit: 600},
      );
      expect(details.cashAmount, 400);
      expect(details.creditAmount, 600);
      expect(details.collectedAmount, 400);
      expect(details.paidAmountFor(1000), 400);
      expect(details.balanceAmountFor(1000), 600);
      expect(details.otherPaymentType, SalesPaymentMode.credit);
    });

    test('split payments map each mode and remaining balance', () {
      final details = SalesPaymentDetails(
        amounts: {
          SalesPaymentMode.cash: 400,
          SalesPaymentMode.upi: 350,
          SalesPaymentMode.other: 250,
        },
      );
      expect(details.isSplit, isTrue);
      expect(details.mode, 'Split');
      expect(details.cashAmount, 400);
      expect(details.upiAmount, 350);
      expect(details.otherAmount, 250);
      expect(details.paidAmountFor(1000), 1000);
      expect(details.balanceAmountFor(1000), 0);
      expect(details.otherPaymentType, SalesPaymentMode.other);
    });
  });

  group('PaymentModeDialog', () {
    testWidgets('renders Payment Breakup grid and bill amount', (tester) async {
      await openDialog(tester, payableAmount: 1250.5);

      expect(find.text('Payment Breakup'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('Cheque'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Credit'), findsOneWidget);
      expect(find.text('₹1250.50'), findsOneWidget);
      expect(find.byKey(const Key('payment-mode-Cash')), findsOneWidget);
      expect(find.byKey(const Key('payment-mode-Credit')), findsOneWidget);
    });

    testWidgets('close button cancels without a result', (tester) async {
      SalesPaymentDetails? result;
      await openDialog(
        tester,
        payableAmount: 100,
        onResult: (value) => result = value,
      );

      await tester.tap(find.byKey(const Key('payment-mode-close')));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentModeDialog), findsNothing);
      expect(result, isNull);
    });

    testWidgets('Windows: Cash is focused with bill amount prefilled', (
      tester,
    ) async {
      PlatformHelper.setOverrideForTesting(true);
      await openDialog(tester);

      final cashField = tester.widget<TextFormField>(
        find.byKey(const Key('payment-mode-Cash')),
      );
      expect(cashField.controller?.text, '1000.00');
      final cashEditable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('payment-mode-Cash')),
          matching: find.byType(EditableText),
        ),
      );
      expect(cashEditable.focusNode.hasFocus, isTrue);
      expect(find.byKey(const Key('payment-mode-confirm')), findsOneWidget);
    });

    testWidgets(
      'Windows: Enter on Cash does not save and moves to UPI',
      (tester) async {
        PlatformHelper.setOverrideForTesting(true);
        var confirmCount = 0;
        await openDialog(
          tester,
          payableAmount: 1000,
          onConfirm: (_) async {
            confirmCount++;
            return true;
          },
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(find.byType(PaymentModeDialog), findsOneWidget);
        expect(confirmCount, 0);
        final upiEditable = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('payment-mode-UPI')),
            matching: find.byType(EditableText),
          ),
        );
        expect(upiEditable.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'Windows: Enter on last field saves once and ignores extra Enter',
      (tester) async {
        PlatformHelper.setOverrideForTesting(true);
        var confirmCount = 0;
        SalesPaymentDetails? result;
        await openDialog(
          tester,
          payableAmount: 500,
          onConfirm: (_) async {
            confirmCount++;
            return true;
          },
          onResult: (value) => result = value,
        );

        const modes = [
          'UPI',
          'Cheque',
          'Bank',
          'Card',
          'Other',
          'Credit',
        ];
        for (final _ in modes) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(find.byType(PaymentModeDialog), findsOneWidget);
          expect(confirmCount, 0);
        }

        final creditEditable = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('payment-mode-Credit')),
            matching: find.byType(EditableText),
          ),
        );
        expect(creditEditable.focusNode.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(PaymentModeDialog), findsNothing);
        expect(confirmCount, 1);
        expect(result?.mode, SalesPaymentMode.cash);
        expect(result?.amount, 500);
      },
    );

    testWidgets(
      'Windows: Enter and arrows move Cash → UPI → Cheque → Bank → Card → Other → Credit',
      (tester) async {
        PlatformHelper.setOverrideForTesting(true);
        await openDialog(tester);

        bool focused(String mode) {
          return tester
              .widget<EditableText>(
                find.descendant(
                  of: find.byKey(Key('payment-mode-$mode')),
                  matching: find.byType(EditableText),
                ),
              )
              .focusNode
              .hasFocus;
        }

        expect(focused('Cash'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(focused('UPI'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(focused('Cheque'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(focused('Bank'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(focused('Card'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(focused('Other'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(focused('Credit'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(focused('Other'), isTrue);
      },
    );

    testWidgets('Windows: Enter on full Cash amount saves', (tester) async {
      PlatformHelper.setOverrideForTesting(true);
      SalesPaymentDetails? result;
      await openDialog(
        tester,
        payableAmount: 500,
        onResult: (value) => result = value,
      );

      await tapConfirm(tester);
      await tester.pumpAndSettle();

      expect(find.byType(PaymentModeDialog), findsNothing);
      expect(result?.mode, SalesPaymentMode.cash);
      expect(result?.amount, 500);
    });

    testWidgets('Windows: Esc cancels before confirm and does not save', (
      tester,
    ) async {
      PlatformHelper.setOverrideForTesting(true);
      var confirmCalled = false;
      SalesPaymentDetails? result;
      await openDialog(
        tester,
        payableAmount: 100,
        onConfirm: (_) async {
          confirmCalled = true;
          return true;
        },
        onResult: (value) => result = value,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(PaymentModeDialog), findsNothing);
      expect(result, isNull);
      expect(confirmCalled, isFalse);
    });

    testWidgets('rejects amount greater than payable and stays open', (
      tester,
    ) async {
      PlatformHelper.setOverrideForTesting(true);
      var confirmCalled = false;
      await openDialog(
        tester,
        payableAmount: 100,
        onConfirm: (_) async {
          confirmCalled = true;
          return true;
        },
      );

      await tester.enterText(find.byKey(const Key('payment-mode-Cash')), '150');
      await tester.pump();
      await tapConfirm(tester);
      await tester.pumpAndSettle();

      expect(find.byType(PaymentModeDialog), findsOneWidget);
      expect(find.textContaining('cannot exceed payable'), findsOneWidget);
      expect(confirmCalled, isFalse);
    });

    testWidgets('onConfirm false keeps the dialog open', (tester) async {
      PlatformHelper.setOverrideForTesting(true);
      var confirmCount = 0;
      await openDialog(
        tester,
        payableAmount: 100,
        onConfirm: (_) async {
          confirmCount++;
          return false;
        },
      );

      await tapConfirm(tester);
      await tester.pumpAndSettle();

      expect(find.byType(PaymentModeDialog), findsOneWidget);
      expect(confirmCount, 1);
    });

    testWidgets('dialog closes only after onConfirm succeeds', (tester) async {
      PlatformHelper.setOverrideForTesting(true);
      final completer = Completer<bool>();
      SalesPaymentDetails? result;
      await openDialog(
        tester,
        payableAmount: 250,
        onConfirm: (_) => completer.future,
        onResult: (value) => result = value,
      );

      await tester.enterText(find.byKey(const Key('payment-mode-Card')), '250');
      await tester.enterText(find.byKey(const Key('payment-mode-Cash')), '');
      await tester.pump();
      await tapConfirm(tester);
      await tester.pump();

      expect(find.byType(PaymentModeDialog), findsOneWidget);
      expect(find.text('Saving...'), findsOneWidget);

      completer.complete(true);
      await tester.pumpAndSettle();

      expect(find.byType(PaymentModeDialog), findsNothing);
      expect(result?.mode, SalesPaymentMode.card);
      expect(result?.amount, 250);
    });

    testWidgets('split amounts across Cash and UPI', (tester) async {
      PlatformHelper.setOverrideForTesting(true);
      SalesPaymentDetails? result;
      await openDialog(
        tester,
        payableAmount: 100,
        onResult: (value) => result = value,
      );

      await tester.enterText(find.byKey(const Key('payment-mode-Cash')), '40');
      await tester.enterText(find.byKey(const Key('payment-mode-UPI')), '60');
      await tester.pump();
      await tapConfirm(tester);
      await tester.pumpAndSettle();

      expect(find.byType(PaymentModeDialog), findsNothing);
      expect(result?.mode, 'Split');
      expect(result?.cashAmount, 40);
      expect(result?.upiAmount, 60);
      expect(result?.paidAmountFor(100), 100);
    });

    testWidgets('shows cheque details only when cheque amount is entered', (
      tester,
    ) async {
      await openDialog(tester, payableAmount: 100);

      expect(find.text('Cheque Details'), findsNothing);
      expect(find.byKey(const Key('payment-detail-cheque-no')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('payment-mode-Cheque')),
        '50',
      );
      await tester.pump();

      expect(find.text('Cheque Details'), findsOneWidget);
      expect(find.byKey(const Key('payment-detail-cheque-no')), findsOneWidget);
      expect(
        find.byKey(const Key('payment-detail-cheque-date')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('payment-detail-cheque-remark')),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('payment-mode-Cheque')), '');
      await tester.pump();

      expect(find.text('Cheque Details'), findsNothing);
      expect(find.byKey(const Key('payment-detail-cheque-no')), findsNothing);
    });

    testWidgets('saves cheque number with payment details', (tester) async {
      SalesPaymentDetails? result;
      await openDialog(
        tester,
        payableAmount: 100,
        onResult: (value) => result = value,
      );

      await tester.enterText(find.byKey(const Key('payment-mode-Cash')), '');
      await tester.enterText(
        find.byKey(const Key('payment-mode-Cheque')),
        '100',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('payment-detail-cheque-no')),
        'CHQ-123',
      );
      await tester.enterText(
        find.byKey(const Key('payment-detail-cheque-remark')),
        'Party cheque',
      );
      await tapConfirm(tester);
      await tester.pumpAndSettle();

      expect(result?.chequeAmount, 100);
      expect(result?.chequeNo, 'CHQ-123');
      expect(result?.chequeRemark, 'Party cheque');
    });

    testWidgets('non-Windows ignores Esc shortcut', (tester) async {
      PlatformHelper.setOverrideForTesting(false);
      var confirmCalled = false;
      await openDialog(
        tester,
        payableAmount: 100,
        onConfirm: (_) async {
          confirmCalled = true;
          return true;
        },
      );

      expect(find.textContaining('Esc to cancel'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentModeDialog), findsOneWidget);
      expect(confirmCalled, isFalse);
    });
  });
}
