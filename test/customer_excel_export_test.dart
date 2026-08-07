import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:billing_software/models/customer.dart';
import 'package:billing_software/services/customer_excel_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomerExcelExportService', () {
    final sampleCustomers = [
      CustomerListItem(
        custId: 101,
        custCode: 'C-001',
        custName: 'Acme & Sons <Trading>',
        custCompanyName: 'Acme Corp "Global"',
        custMobileNo: '9876543210',
        custAlternateMobileNo: '9123456780',
        custEmail: 'acme@example.com',
        custGSTNo: '27AAPFU0939F1ZV',
        custPANNo: 'AAPFU0939F',
        custAddress: '123 Market Street & Avenue',
        custArea: 'Central',
        custCity: 'Mumbai',
        custState: 'Maharashtra',
        custPincode: '400001',
        custCountry: 'India',
        custIsActive: true,
        custCreatedDate: '2026-08-01T10:30:00',
        custModifiedDate: '2026-08-05T15:45:00',
      ),
      CustomerListItem(
        custId: 102,
        custCode: 'C-002',
        custName: 'Beta Retailers',
        custCompanyName: 'Beta Ltd',
        custMobileNo: '9822000000',
        custAlternateMobileNo: '',
        custEmail: 'beta@retail.com',
        custGSTNo: '27AABCB1234F1Z5',
        custPANNo: 'AABCB1234F',
        custAddress: 'Shop 4, Station Road',
        custArea: 'Kothrud',
        custCity: 'Pune',
        custState: 'Maharashtra',
        custPincode: '411038',
        custCountry: 'India',
        custIsActive: false,
        custCreatedDate: '2026-07-15T09:00:00',
        custModifiedDate: null,
      ),
    ];

    test('generates valid ZIP/.xlsx archive bytes', () {
      final bytes = CustomerExcelExportService.generateCustomerExcelBytes(sampleCustomers);
      expect(bytes, isNotEmpty);

      // Verify ZIP archive decoding
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(bytes);

      final fileNames = archive.files.map((f) => f.name).toSet();
      expect(fileNames, contains('[Content_Types].xml'));
      expect(fileNames, contains('_rels/.rels'));
      expect(fileNames, contains('xl/_rels/workbook.xml.rels'));
      expect(fileNames, contains('xl/workbook.xml'));
      expect(fileNames, contains('xl/styles.xml'));
      expect(fileNames, contains('xl/worksheets/sheet1.xml'));
    });

    test('sheet1.xml contains freeze pane for the first row', () {
      final bytes = CustomerExcelExportService.generateCustomerExcelBytes(sampleCustomers);
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(bytes);

      final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
      expect(sheetFile, isNotNull);

      final content = utf8.decode(sheetFile!.content as List<int>);
      expect(content, contains('<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'));
    });

    test('sheet1.xml correctly escapes special characters and populates rows', () {
      final bytes = CustomerExcelExportService.generateCustomerExcelBytes(sampleCustomers);
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(bytes);

      final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
      final content = utf8.decode(sheetFile!.content as List<int>);

      // Check XML escaping of Acme & Sons <Trading>
      expect(content, contains('Acme &amp; Sons &lt;Trading&gt;'));
      // Check company name escaping
      expect(content, contains('Acme Corp &quot;Global&quot;'));
      // Check headers
      expect(content, contains('Customer Code'));
      expect(content, contains('Customer Name'));
      expect(content, contains('Company Name'));
      expect(content, contains('GST No.'));
      // Check active / inactive status
      expect(content, contains('Active'));
      expect(content, contains('Inactive'));
      // Check auto-fit <col> definitions
      expect(content, contains('<col min="1" max="1"'));
    });

    test('styles.xml includes bold header font and dark blue fill', () {
      final bytes = CustomerExcelExportService.generateCustomerExcelBytes(sampleCustomers);
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(bytes);

      final stylesFile = archive.findFile('xl/styles.xml');
      expect(stylesFile, isNotNull);

      final content = utf8.decode(stylesFile!.content as List<int>);
      expect(content, contains('<b val="1"/>'));
      expect(content, contains('FF1E3A8A'));
    });

    test('handles empty customer list gracefully', () async {
      final result = await CustomerExcelExportService.exportCustomers(customers: []);
      expect(result.success, isFalse);
      expect(result.recordCount, 0);
      expect(result.message, contains('No customer records'));
    });
  });
}
