import '../models/collection_report.dart';
import '../models/customer_reports.dart';
import '../models/supplier_reports.dart';
import '../models/current_stock.dart';
import 'excel_export_helper.dart';

class ReportExcelExportService {
  static Future<ExcelExportResult> exportSupplierOutstanding(
    List<SupplierOutstandingReportItem> items,
  ) {
    return ExcelExportHelper.exportSheet(
      filePrefix: 'Supplier_Outstanding_Report',
      sheetName: 'Supplier Outstanding',
      emptyMessage: 'No supplier outstanding records available to export.',
      columns: const [
        ExcelColumn('Sr. No.', align: ExcelCellAlign.center, type: ExcelCellType.number),
        ExcelColumn('Supplier Code', align: ExcelCellAlign.center),
        ExcelColumn('Supplier Name'),
        ExcelColumn('Company Name'),
        ExcelColumn('Mobile', align: ExcelCellAlign.center),
        ExcelColumn('City'),
        ExcelColumn('State'),
        ExcelColumn('Purchase Count', align: ExcelCellAlign.center, type: ExcelCellType.number),
        ExcelColumn('Purchase Amt', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Paid Amt', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Outstanding', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Status', align: ExcelCellAlign.center),
      ],
      rows: [
        for (int i = 0; i < items.length; i++)
          [
            '${i + 1}',
            items[i].suppCode,
            items[i].suppName,
            items[i].suppCompanyName,
            items[i].suppMobileNo,
            items[i].suppCityName,
            items[i].suppStateName,
            items[i].totalPurchaseCount.toString(),
            ExcelExportHelper.formatAmount(items[i].totalPurchaseAmount),
            ExcelExportHelper.formatAmount(items[i].totalPaidAmount),
            ExcelExportHelper.formatAmount(items[i].outstandingAmount),
            items[i].suppIsActive ? 'Active' : 'Inactive',
          ],
      ],
    );
  }

  static Future<ExcelExportResult> exportCustomerOutstanding(
    List<CustomerOutstandingReportItem> items,
  ) {
    return ExcelExportHelper.exportSheet(
      filePrefix: 'Customer_Outstanding_Report',
      sheetName: 'Customer Outstanding',
      emptyMessage: 'No customer outstanding records available to export.',
      columns: const [
        ExcelColumn('Sr. No.', align: ExcelCellAlign.center, type: ExcelCellType.number),
        ExcelColumn('Customer Code', align: ExcelCellAlign.center),
        ExcelColumn('Customer Name'),
        ExcelColumn('Mobile', align: ExcelCellAlign.center),
        ExcelColumn('Invoice Amt', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Paid Amt', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Outstanding', align: ExcelCellAlign.right, type: ExcelCellType.number),
      ],
      rows: [
        for (int i = 0; i < items.length; i++)
          [
            '${i + 1}',
            items[i].custCode,
            items[i].custName,
            items[i].custMobileNo,
            ExcelExportHelper.formatAmount(items[i].totalInvoiceAmount),
            ExcelExportHelper.formatAmount(items[i].totalPaidAmount),
            ExcelExportHelper.formatAmount(items[i].totalOutstanding),
          ],
      ],
    );
  }

  static Future<ExcelExportResult> exportCollectionReport(
    List<CollectionReportData> items,
  ) {
    return ExcelExportHelper.exportSheet(
      filePrefix: 'Collection_Report',
      sheetName: 'Collection Report',
      emptyMessage: 'No collection records available to export.',
      columns: const [
        ExcelColumn('Sr. No.', align: ExcelCellAlign.center, type: ExcelCellType.number),
        ExcelColumn('Date', align: ExcelCellAlign.center),
        ExcelColumn('Receipt No', align: ExcelCellAlign.center),
        ExcelColumn('Customer Code', align: ExcelCellAlign.center),
        ExcelColumn('Customer'),
        ExcelColumn('Mobile', align: ExcelCellAlign.center),
        ExcelColumn('Mode', align: ExcelCellAlign.center),
        ExcelColumn('Amount', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Cash', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('UPI', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Cheque', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Bank', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Card', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Other', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Cheque No'),
        ExcelColumn('Bank Name'),
        ExcelColumn('Bank Reference'),
        ExcelColumn('NEFT Type'),
        ExcelColumn('NEFT Reference'),
        ExcelColumn('Remark'),
        ExcelColumn('Status', align: ExcelCellAlign.center),
      ],
      rows: [
        for (int i = 0; i < items.length; i++)
          [
            '${i + 1}',
            ExcelExportHelper.formatDate(items[i].receiptMasterReceiptDate),
            items[i].receiptMasterReceiptNo,
            items[i].custCode,
            items[i].custName,
            items[i].custMobileNo,
            _collectionPaymentMode(items[i]),
            ExcelExportHelper.formatAmount(items[i].totalCollection),
            ExcelExportHelper.formatAmount(items[i].cashAmount),
            ExcelExportHelper.formatAmount(items[i].upiAmount),
            ExcelExportHelper.formatAmount(items[i].chequeAmount),
            ExcelExportHelper.formatAmount(items[i].bankAmount),
            ExcelExportHelper.formatAmount(items[i].cardAmount),
            ExcelExportHelper.formatAmount(items[i].otherAmount),
            items[i].receiptMasterChequeNo,
            items[i].receiptMasterBankName,
            items[i].receiptMasterBankReferenceNo,
            items[i].receiptMasterNEFTType,
            items[i].receiptMasterNEFTReferenceNo,
            items[i].receiptMasterRemark,
            items[i].receiptMasterStatus,
          ],
      ],
    );
  }

  static String _collectionPaymentMode(CollectionReportData item) {
    if (item.chequeAmount > 0) return 'Cheque';
    if (item.cardAmount > 0) return 'Card';
    if (item.upiAmount > 0) return 'UPI';
    if (item.bankAmount > 0) return 'Bank';
    if (item.otherAmount > 0) return 'Other';
    if (item.cashAmount > 0) return 'Cash';
    return 'Cash';
  }

  static Future<ExcelExportResult> exportCurrentStock(
    List<CurrentStock> items,
  ) {
    return ExcelExportHelper.exportSheet(
      filePrefix: 'Current_Stock_Report',
      sheetName: 'Current Stock',
      emptyMessage: 'No current stock records available to export.',
      columns: const [
        ExcelColumn('Sr. No.', align: ExcelCellAlign.center, type: ExcelCellType.number),
        ExcelColumn('Product Name'),
        ExcelColumn('Brand Name'),
        ExcelColumn('Category Name'),
        ExcelColumn('Unit'),
        ExcelColumn('Unit Value', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Available Stock', align: ExcelCellAlign.right, type: ExcelCellType.number),
        ExcelColumn('Selling Price', align: ExcelCellAlign.right, type: ExcelCellType.number),
      ],
      rows: [
        for (int i = 0; i < items.length; i++)
          [
            '${i + 1}',
            items[i].productName,
            items[i].brandName,
            items[i].categoryName,
            items[i].unitShortName,
            ExcelExportHelper.formatAmount(items[i].unitValue),
            ExcelExportHelper.formatAmount(items[i].availableStock),
            ExcelExportHelper.formatAmount(items[i].sellingPrice),
          ],
      ],
    );
  }
}
