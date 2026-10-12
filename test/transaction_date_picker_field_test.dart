import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:billing_software/widgets/transaction_date_picker_field.dart';
import 'package:billing_software/widgets/app_message_dialog.dart';

void main() {
  group('TransactionDatePickerField.validateDateString', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fmt = DateFormat('yyyy/MM/dd');

    test('validates today successfully', () {
      final todayStr = fmt.format(today);
      final error = TransactionDatePickerField.validateDateString(todayStr);
      expect(error, isNull);
    });

    test('validates past date successfully', () {
      final pastDate = today.subtract(const Duration(days: 10));
      final pastStr = fmt.format(pastDate);
      final error = TransactionDatePickerField.validateDateString(pastStr);
      expect(error, isNull);
    });

    test('rejects future date', () {
      final futureDate = today.add(const Duration(days: 1));
      final futureStr = fmt.format(futureDate);
      final error = TransactionDatePickerField.validateDateString(
        futureStr,
        restrictFutureDates: true,
      );
      expect(error, isNotNull);
      expect(error, contains('Future dates are not allowed'));
    });

    test('rejects invalid month (e.g. 2026/13/10)', () {
      final error = TransactionDatePickerField.validateDateString('2026/13/10');
      expect(error, isNotNull);
      expect(error, contains('Invalid month'));
    });

    test('rejects month 00', () {
      final error = TransactionDatePickerField.validateDateString('2026/00/10');
      expect(error, isNotNull);
      expect(error, contains('Invalid month'));
    });

    test('rejects invalid day (e.g. 2026/10/32)', () {
      final error = TransactionDatePickerField.validateDateString('2026/10/32');
      expect(error, isNotNull);
      expect(error, contains('Invalid day'));
    });

    test('rejects day 00', () {
      final error = TransactionDatePickerField.validateDateString('2026/10/00');
      expect(error, isNotNull);
      expect(error, contains('Day must be at least 01'));
    });

    test('rejects February 30 (e.g. 2026/02/30)', () {
      final error = TransactionDatePickerField.validateDateString('2026/02/30');
      expect(error, isNotNull);
      expect(error, contains('February 2026 has only 28 days'));
    });

    test('rejects February 29 in non-leap year (e.g. 2025/02/29)', () {
      final error = TransactionDatePickerField.validateDateString('2025/02/29');
      expect(error, isNotNull);
      expect(error, contains('February 2025 has only 28 days'));
    });

    test('accepts February 29 in past leap year (e.g. 2024/02/29)', () {
      final error = TransactionDatePickerField.validateDateString(
        '2024/02/29',
        restrictFutureDates: false,
      );
      expect(error, isNull);
    });

    test('rejects April 31 (month with 30 days)', () {
      final error = TransactionDatePickerField.validateDateString('2024/04/31');
      expect(error, isNotNull);
      expect(error, contains('The selected month has only 30 days'));
    });

    test('rejects incomplete format', () {
      expect(
        TransactionDatePickerField.validateDateString('2026'),
        contains('Please enter a valid date'),
      );
      expect(
        TransactionDatePickerField.validateDateString('2026/10'),
        contains('Please enter a valid date'),
      );
    });

    test('rejects year before firstDate (default 2000)', () {
      final error = TransactionDatePickerField.validateDateString('1999/10/12');
      expect(error, isNotNull);
      expect(error, contains('Year cannot be earlier than 2000'));
    });
  });

  group('DateTextInputFormatter', () {
    const formatter = DateTextInputFormatter();

    test('formats digits smoothly', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '20261012',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '2026/10/12');
      expect(result.selection.end, 10);
    });

    test('formats partial input', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '20261',
        selection: TextSelection.collapsed(offset: 5),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '2026/1');
    });

    test('handles backspace over trailing slash', () {
      const oldValue = TextEditingValue(
        text: '2026/10/',
        selection: TextSelection.collapsed(offset: 8),
      );
      // User hit backspace on the trailing slash
      const newValue = TextEditingValue(
        text: '2026/10',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      // It should delete the 0 as well to not get stuck on slash
      expect(result.text, '2026/1');
    });
  });

  group('TransactionDatePickerField Widget', () {
    testWidgets('renders initial date with yyyy/MM/dd format', (tester) async {
      final testDate = DateTime(2025, 5, 20);
      DateTime? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDatePickerField(
              selectedDate: testDate,
              onDateSelected: (d) => selected = d,
              labelText: 'Invoice Date',
            ),
          ),
        ),
      );

      expect(find.text('2025/05/20'), findsOneWidget);
      expect(find.text('Invoice Date'), findsOneWidget);
    });

    testWidgets('manual valid date entry + Enter validates and advances focus without popup',
        (tester) async {
      final initialDate = DateTime(2025, 1, 1);
      DateTime? selectedDate;
      bool nextFocused = false;

      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TransactionDatePickerField(
                  selectedDate: initialDate,
                  focusNode: focusNode,
                  onDateSelected: (d) => selectedDate = d,
                  onNextFocus: () => nextFocused = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Focus the field
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Enter a valid past date
      await tester.enterText(find.byType(TextFormField), '2025/08/15');
      await tester.pumpAndSettle();

      // Press Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Date should be updated
      expect(selectedDate, DateTime(2025, 8, 15));
      // Focus advanced
      expect(nextFocused, isTrue);
      // DatePicker popup is NOT present
      expect(find.byType(CalendarDatePicker), findsNothing);
    });

    testWidgets('manual invalid date entry + Enter shows warning dialog and stays on field',
        (tester) async {
      final initialDate = DateTime(2025, 1, 1);
      DateTime? selectedDate;
      bool nextFocused = false;

      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDatePickerField(
              selectedDate: initialDate,
              focusNode: focusNode,
              onDateSelected: (d) => selectedDate = d,
              onNextFocus: () => nextFocused = true,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Enter an invalid date (invalid month 13)
      await tester.enterText(find.byType(TextFormField), '2025/13/10');
      await tester.pumpAndSettle();

      // Press Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Dialog should appear with Warning
      expect(find.byType(AppMessageDialog), findsOneWidget);
      expect(find.textContaining('Invalid month'), findsOneWidget);

      // Date was NOT accepted
      expect(selectedDate, isNull);
      // Next focus was NOT triggered
      expect(nextFocused, isFalse);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Focus should remain on the date field
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('Enter without editing does NOT open popup and advances focus',
        (tester) async {
      final testDate = DateTime(2025, 5, 20);
      final focusNode = FocusNode();
      bool nextFocused = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDatePickerField(
              selectedDate: testDate,
              focusNode: focusNode,
              onDateSelected: (_) {},
              onNextFocus: () => nextFocused = true,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Press Enter without modifying text
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // CalendarDatePicker should NOT be open
      expect(find.byType(CalendarDatePicker), findsNothing);
      // Next focus was triggered
      expect(nextFocused, isTrue);
    });

    testWidgets('empty date field + Enter advances focus without opening popup',
        (tester) async {
      final testDate = DateTime(2025, 5, 20);
      final focusNode = FocusNode();
      bool nextFocused = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDatePickerField(
              selectedDate: testDate,
              focusNode: focusNode,
              onDateSelected: (_) {},
              onNextFocus: () => nextFocused = true,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Clear text field
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pumpAndSettle();

      // Press Enter on empty field
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // CalendarDatePicker should NOT be open
      expect(find.byType(CalendarDatePicker), findsNothing);
      // Next focus was triggered
      expect(nextFocused, isTrue);
    });

    testWidgets('clicking calendar icon opens CalendarDatePicker dialog',
        (tester) async {
      final testDate = DateTime(2025, 5, 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDatePickerField(
              selectedDate: testDate,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );

      // Tap calendar icon button
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // CalendarDatePicker should be opened
      expect(find.byType(CalendarDatePicker), findsOneWidget);
    });

    testWidgets('clicking or focusing on the date text field does NOT open calendar popup',
        (tester) async {
      final testDate = DateTime(2025, 5, 20);
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDatePickerField(
              selectedDate: testDate,
              focusNode: focusNode,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );

      // Tap on text field
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
      // Popup should NOT be open
      expect(find.byType(CalendarDatePicker), findsNothing);
    });

    testWidgets('pressing Enter only once moves focus immediately without second Enter press',
        (tester) async {
      final initialDate = DateTime(2025, 1, 1);
      final dateFocusNode = FocusNode();
      final nextFocusNode = FocusNode();
      int nextFocusCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TransactionDatePickerField(
                  selectedDate: initialDate,
                  focusNode: dateFocusNode,
                  onDateSelected: (_) {},
                  onNextFocus: () {
                    nextFocusCallCount++;
                    nextFocusNode.requestFocus();
                  },
                ),
                Focus(
                  focusNode: nextFocusNode,
                  child: const SizedBox(height: 10, width: 10),
                ),
              ],
            ),
          ),
        ),
      );

      dateFocusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(dateFocusNode.hasFocus, isTrue);

      // Press Enter exactly ONCE
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify next focus was requested immediately on first Enter
      expect(nextFocusCallCount, 1);
      expect(nextFocusNode.hasFocus, isTrue);
      expect(find.byType(CalendarDatePicker), findsNothing);
    });
  });
}
