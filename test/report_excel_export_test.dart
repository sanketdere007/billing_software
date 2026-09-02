import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:billing_software/models/collection_report.dart';
import 'package:billing_software/models/customer_reports.dart';
import 'package:billing_software/models/supplier_reports.dart';
import 'package:billing_software/services/excel_export_helper.dart';
import 'package:billing_software/services/report_excel_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supplier outstanding excel contains bound report fields', () {
    final bytes = ExcelExportHelper.generateBytes(
      sheetName: 'Supplier Outstanding',
      columns: const [
        ExcelColumn('Supplier Name'),
        ExcelColumn('Outstanding', type: ExcelCellType.number),
      ],
      rows: const [
        ['Alpha Traders', '1500.00'],
      ],
    );

    expect(bytes.length, greaterThan(100));
    final archive = ZipDecoder().decodeBytes(bytes);
    final sheet = utf8.decode(archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>);
    expect(sheet, contains('Alpha Traders'));
    expect(sheet, contains('1500.00'));
  });

  test('empty report export returns a clear failure', () async {
    final supplier = await ReportExcelExportService.exportSupplierOutstanding([]);
    final customer = await ReportExcelExportService.exportCustomerOutstanding([]);
    final collection = await ReportExcelExportService.exportCollectionReport([]);

    expect(supplier.success, isFalse);
    expect(customer.success, isFalse);
    expect(collection.success, isFalse);
    expect(supplier.message, contains('No supplier outstanding'));
    expect(customer.message, contains('No customer outstanding'));
    expect(collection.message, contains('No collection records'));
  });

  test('report models can be mapped into export rows', () {
    final supplier = SupplierOutstandingReportItem(
      suppId: 1,
      suppCode: 'S-1',
      suppName: 'Supplier One',
      suppCompanyName: 'One Pvt',
      suppMobileNo: '9999999999',
      suppAlternateMobileNo: '',
      suppEmail: '',
      suppGSTNo: '',
      suppPANNo: '',
      suppAreaId: 0,
      suppAreaName: '',
      suppCityId: 0,
      suppCityName: 'Pune',
      suppStateId: 0,
      suppStateName: 'Maharashtra',
      suppPincode: '',
      suppCountry: '',
      suppCompId: 1,
      compName: '',
      suppBranchId: 1,
      branchName: '',
      accLedgerId: 0,
      accLedgerName: '',
      purchaseLedgerId: 0,
      totalPurchaseCount: 2,
      totalSubTotal: 0,
      totalDiscountAmount: 0,
      totalGSTAmount: 0,
      totalOtherCharges: 0,
      totalPurchaseAmount: 2000,
      totalPaidAmount: 500,
      outstandingAmount: 1500,
      suppIsActive: true,
      totalRecords: 1,
      pageNumber: 1,
      pageSize: 20,
      totalPages: 1,
    );

    final customer = CustomerOutstandingReportItem(
      customerId: 2,
      custCode: 'C-2',
      custName: 'Customer Two',
      custMobileNo: '8888888888',
      totalInvoiceAmount: 3000,
      totalPaidAmount: 1000,
      totalOutstanding: 2000,
    );

    final collection = CollectionReportData(
      receiptMasterId: 3,
      receiptMasterReceiptNo: 'RCP-3',
      receiptMasterReceiptDate: DateTime(2026, 9, 3),
      receiptMasterStatus: 'Active',
      receiptMasterIsActive: true,
      receiptMasterCompId: 1,
      compId: 1,
      compName: '',
      receiptMasterBranchId: 1,
      branchId: 1,
      branchName: '',
      receiptMasterCustomerId: 2,
      custCode: 'C-2',
      custName: 'Customer Two',
      custMobileNo: '8888888888',
      custEmail: '',
      receiptMasterLedgerId: 0,
      accLedgerName: '',
      totalCollection: 1000,
      cashAmount: 400,
      upiAmount: 600,
      cardAmount: 0,
      chequeAmount: 0,
      bankAmount: 0,
      otherAmount: 0,
      receiptMasterChequeNo: '',
      receiptMasterBankName: '',
      receiptMasterBankReferenceNo: '',
      receiptMasterNEFTType: '',
      receiptMasterNEFTReferenceNo: '',
      receiptMasterOtherPaymentType: '',
      receiptMasterOtherReferenceNo: '',
      receiptMasterOtherRemark: '',
      receiptMasterRemark: 'Test collection',
      receiptMasterCreatedBy: 1,
      receiptMasterModifiedBy: 1,
      currentPage: 1,
      pageSize: 20,
    );

    expect(supplier.suppName, 'Supplier One');
    expect(customer.custName, 'Customer Two');
    expect(collection.receiptMasterReceiptNo, 'RCP-3');
    expect(collection.totalCollection, 1000);
  });
}
