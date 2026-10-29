import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/services/invoice_pdf_font_loader.dart';
import 'package:billing_software/services/invoice_pdf_generator.dart';
import 'package:billing_software/models/invoice_pdf_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InvoicePdfFontLoader Tests', () {
    setUp(() {
      InvoicePdfFontLoader.clearCache();
    });

    tearDown(() {
      InvoicePdfFontLoader.clearCache();
    });

    test('getTheme returns a valid pw.ThemeData with fallback fonts', () async {
      final theme = await InvoicePdfFontLoader.getTheme();
      expect(theme, isNotNull);
      expect(theme.defaultTextStyle, isNotNull);
      expect(theme.defaultTextStyle.font, isNotNull);
    });

    test('getTheme caches theme instance across calls', () async {
      final theme1 = await InvoicePdfFontLoader.getTheme();
      final theme2 = await InvoicePdfFontLoader.getTheme();
      expect(identical(theme1, theme2), isTrue);
    });

    test('clearCache resets cached theme', () async {
      final theme1 = await InvoicePdfFontLoader.getTheme();
      InvoicePdfFontLoader.clearCache();
      final theme2 = await InvoicePdfFontLoader.getTheme();
      expect(identical(theme1, theme2), isFalse);
    });
  });

  group('InvoicePdfGenerator - Unicode Formatting Tests', () {
    test('formatBalanceDue formats Indian Rupee symbol correctly', () {
      expect(InvoicePdfGenerator.formatBalanceDue(0.0), equals('NIL'));
      expect(InvoicePdfGenerator.formatBalanceDue(1500.0), equals('₹1,500.00'));
      expect(InvoicePdfGenerator.formatBalanceDue(250000.5), equals('₹2,50,000.50'));
    });

    test('generate builds valid PDF bytes for invoice with Unicode data', () async {
      final generator = InvoicePdfGenerator();
      const invoiceData = InvoicePdfData(
        company: InvoiceCompany(
          name: 'साई एंटरप्राइजेस (Sai Enterprises)',
          address: 'Pune, Maharashtra',
          phones: '9876543210',
          gstNo: '27AAAAA0000A1Z5',
        ),
        invoice: InvoiceMeta(
          invoiceNo: 'INV-26-27-019',
          date: '29/10/2026',
          time: '01:30:00 PM',
        ),
        customer: InvoiceCustomer(
          name: 'रमेश पाटील (Ramesh Patil)',
          phone: '9876543210',
          address: 'Shivaji Nagar, Pune',
        ),
        items: [
          InvoiceLineItem(
            productName: 'औषध गोळ्या (Paracetamol 500mg)',
            batch: 'BAT-2026',
            pack: '10x10',
            qty: 2,
            rate: 50.0,
            amount: 100.0,
            mrp: 60.0,
          ),
        ],
        gross: 100.0,
        netAmount: 100.0,
        balanceDue: 100.0,
      );

      final bytes = await generator.generate(invoiceData);
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(100));

      // Must start with valid PDF magic header (%PDF-)
      expect(bytes[0], equals(0x25)); // %
      expect(bytes[1], equals(0x50)); // P
      expect(bytes[2], equals(0x44)); // D
      expect(bytes[3], equals(0x46)); // F
      expect(bytes[4], equals(0x2D)); // -
    });
  });
}
