import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/services/whatsapp_share_service.dart';
import 'package:billing_software/models/invoice_pdf_data.dart';

void main() {
  group('WhatsAppShareService - Phone Validation Tests', () {
    final service = WhatsAppShareService();

    test('Valid 10-digit standard Indian mobile number', () {
      final result = service.validatePhoneNumber('9876543210');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('919876543210'));
      expect(result.errorMessage, isNull);
    });

    test('Valid 10-digit number with formatting (spaces, hyphens, brackets)', () {
      final result = service.validatePhoneNumber('(98765) 43-210');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('919876543210'));
    });

    test('Valid 11-digit number with leading trunk 0', () {
      final result = service.validatePhoneNumber('09876543210');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('919876543210'));
    });

    test('Valid 12-digit number already prefixed with 91 and plus', () {
      final result = service.validatePhoneNumber('+91 9876543210');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('919876543210'));
    });

    test('Valid 12-digit number starting with 91 without plus', () {
      final result = service.validatePhoneNumber('919876543210');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('919876543210'));
    });

    test('Valid multi-number string separated by slash extracts primary', () {
      final result = service.validatePhoneNumber('9876543210 / 9123456789');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('919876543210'));
    });

    test('Valid multi-number string separated by comma extracts primary', () {
      final result = service.validatePhoneNumber('9876543210, 9123456789');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('919876543210'));
    });

    test('Valid international phone number', () {
      final result = service.validatePhoneNumber('+1 555 123 4567');
      expect(result.isValid, isTrue);
      expect(result.normalizedPhone, equals('15551234567'));
    });

    test('Missing phone number (null)', () {
      final result = service.validatePhoneNumber(null, customerName: 'John Doe');
      expect(result.isValid, isFalse);
      expect(result.normalizedPhone, isNull);
      expect(result.errorMessage, contains('missing'));
      expect(result.errorMessage, contains('John Doe'));
    });

    test('Missing phone number (empty string)', () {
      final result = service.validatePhoneNumber('   ', customerName: 'Apex Corp');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('missing'));
      expect(result.errorMessage, contains('Apex Corp'));
    });

    test('Phone number with only letters / symbols ("N/A")', () {
      final result = service.validatePhoneNumber('N/A', customerName: 'Client');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('missing'));
    });

    test('Invalid phone number (too short, e.g. 5 digits)', () {
      final result = service.validatePhoneNumber('12345');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('invalid'));
      expect(result.errorMessage, contains('10-digit'));
    });

    test('Invalid phone number (all zeros)', () {
      final result = service.validatePhoneNumber('0000000000');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('invalid'));
    });
  });

  group('WhatsAppShareService - Message Formatting Tests', () {
    final service = WhatsAppShareService();

    test('Formats invoice details correctly into message', () {
      const invoiceData = InvoicePdfData(
        company: InvoiceCompany(name: 'Sanky Soft Solutions'),
        invoice: InvoiceMeta(invoiceNo: 'INV-2026-0042', date: '28/10/2026'),
        customer: InvoiceCustomer(name: 'Ramesh Patel', phone: '9876543210'),
        items: [],
        bank: InvoiceBankDetails(name: 'HDFC Bank'),
        netAmount: 14500.50,
      );

      final message = service.formatWhatsAppMessage(invoiceData);

      expect(message, contains('Dear Ramesh Patel,'));
      expect(message, contains('Invoice No: INV-2026-0042'));
      expect(message, contains('Date: 28/10/2026'));
      expect(message, contains('Total Amount: ₹14,500.50'));
      expect(message, contains('Sanky Soft Solutions'));
      expect(message, contains('Status: Completed'));
    });
  });

  group('WhatsAppShareService - PDF Data & File Verification Tests', () {
    final service = WhatsAppShareService();

    test('Verifies valid PDF magic header (%PDF-)', () {
      final validPdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
      final result = service.verifyPdfBytes(validPdfBytes);
      expect(result.isValid, isTrue);
      expect(result.byteLength, equals(8));
      expect(result.errorMessage, isNull);
    });

    test('Rejects null or empty PDF bytes', () {
      expect(service.verifyPdfBytes(null).isValid, isFalse);
      expect(service.verifyPdfBytes(Uint8List(0)).isValid, isFalse);
    });

    test('Rejects bytes that do not start with %PDF-', () {
      final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04, 0x05]);
      final result = service.verifyPdfBytes(invalidBytes);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('%PDF-'));
    });

    test('Format file size helper correctly formats units', () {
      expect(service.formatFileSize(512), equals('512 B'));
      expect(service.formatFileSize(1024), equals('1.0 KB'));
      expect(service.formatFileSize(250 * 1024), equals('250.0 KB'));
      expect(service.formatFileSize(2 * 1024 * 1024), equals('2.00 MB'));
    });
  });

  group('WhatsAppShareService - Windows Explorer & Process Resilience Tests', () {
    final service = WhatsAppShareService();

    test('openInExplorer handles non-existent file path gracefully without throwing', () async {
      final result = await service.openInExplorer('C:\\non_existent_folder\\fake_invoice.pdf');
      expect(result, isFalse);
    });

    test('openContainingFolder handles non-existent directory gracefully without throwing', () async {
      final result = await service.openContainingFolder('C:\\non_existent_folder\\fake_invoice.pdf');
      expect(result, isFalse);
    });

    test('copyPdfFileToClipboard handles non-existent file gracefully without throwing', () async {
      final result = await service.copyPdfFileToClipboard('C:\\non_existent_folder\\fake_invoice.pdf');
      expect(result, isFalse);
    });
  });
}
