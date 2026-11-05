import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billing_software/screens/server_config_screen.dart';
import 'package:billing_software/services/server_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({bool isInitialSetup = false}) {
    return MaterialApp(
      home: ServerConfigScreen(isInitialSetup: isInitialSetup),
    );
  }

  testWidgets('ServerConfigScreen renders all UI components properly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(isInitialSetup: true));

    // Verify Title and Subtitle
    expect(find.text('Connect to Server'), findsOneWidget);
    expect(
      find.text(
        'Enter your laptop or host server\'s local IP address to connect the mobile application.',
      ),
      findsOneWidget,
    );

    // Verify text field
    expect(find.byType(TextFormField), findsOneWidget);

    // Verify Connect / Save button
    expect(find.text('Connect / Save'), findsOneWidget);

    // Verify Help section
    expect(
      find.text('How to find your Laptop\'s IP Address'),
      findsOneWidget,
    );
  });

  testWidgets('ServerConfigScreen updates preview URL dynamically as user types', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    final textField = find.byType(TextFormField);
    await tester.enterText(textField, '192.168.1.42');
    await tester.pump();

    // Verify the preview URL contains the entered IP
    expect(find.text('http://192.168.1.42:3032'), findsOneWidget);
  });

  testWidgets('ServerConfigScreen shows validation error on empty input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    final saveButton = find.text('Connect / Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify validation error
    expect(find.text('Please enter the server IP address'), findsOneWidget);
  });

  testWidgets('ServerConfigScreen shows validation error on invalid IP format', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    final textField = find.byType(TextFormField);
    await tester.enterText(textField, '999.999.999.999');
    await tester.pump();

    final saveButton = find.text('Connect / Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a valid IPv4 address (e.g. 192.168.1.10)'),
      findsOneWidget,
    );
  });
}
