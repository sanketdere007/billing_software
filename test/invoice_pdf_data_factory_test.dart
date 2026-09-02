import 'package:billing_software/models/company.dart';
import 'package:billing_software/models/customer.dart';
import 'package:billing_software/models/sales_entry.dart';
import 'package:billing_software/screens/sales/sales_entry/payment_mode_dialog.dart';
import 'package:billing_software/services/invoice_pdf_data_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps saved sales and receipt data without hardcoded invoice values', () {
    final master = SalesEntryMasterData(
      customerId: 11,
      invoiceDate: DateTime(2026, 9, 3).toIso8601String(),
      subTotal: 1000,
      totalDiscount: 50,
      totalCGST: 45,
      totalSGST: 45,
      grandTotal: 1040,
      paidAmount: 1040,
      cashAmount: 500,
      upiAmount: 540,
      billingName: 'Ramesh Patil',
      billingAddress: 'Pune, Maharashtra',
      billingMobileNo: '9876543210',
      billingGSTNo: '27ABCDE1234F1Z5',
    );

    final details = [
      SalesEntryDetailData(
        productId: 1,
        productName: 'Feed Mix 10KG',
        qty: 2,
        sellingPrice: 500,
        rate: 500,
        discountAmount: 50,
        gstPercentage: 18,
        cgstAmount: 45,
        sgstAmount: 45,
        totalTaxAmount: 90,
        totalAmount: 1040,
        hsnCode: '23099039',
      ),
    ];

    final salesResponse = SalesEntryUpsertResponse(
      status: true,
      message: 'Saved',
      data: SalesEntryUpsertResponseData(
        status: true,
        message: 'Saved',
        salesMasterId: 7788,
        salesMasterInvoiceNo: 'INV-7788',
      ),
    );

    final data = InvoicePdfDataFactory.fromSavedSale(
      salesResponse: salesResponse,
      master: master,
      details: details,
      productRows: const [],
      payment: SalesPaymentDetails(
        amounts: {
          SalesPaymentMode.cash: 500,
          SalesPaymentMode.upi: 540,
        },
        upiTransactionNo: 'UPI123',
      ),
      invoiceDate: DateTime(2026, 9, 3),
      customer: CustomerListItem(
        custId: 11,
        custCode: 'C-11',
        custName: 'Ramesh Patil',
        custMobileNo: '9876543210',
        custPANNo: 'ABCDE1234F',
      ),
      company: CompanyListItem(
        compId: 1,
        compName: 'Test Pharma',
        compAddress: 'Shop 1',
        compCity: 'Pune',
        compState: 'Maharashtra',
        compGSTNo: '27AAAAA0000A1Z5',
        compMobileNo: '9000000000',
      ),
      receiptResponse: {
        'status': true,
        'data': {
          'receiptMaster_ReceiptNo': 'RCP-1001',
          'receiptMaster_ReceiptDate': '2026-09-03T10:00:00',
        },
      },
    );

    expect(data.invoice.invoiceNo, 'INV-7788');
    expect(data.customer.name, 'Ramesh Patil');
    expect(data.customer.phone, '9876543210');
    expect(data.items.single.productName, 'Feed Mix 10KG');
    expect(data.items.single.qty, 2);
    expect(data.items.single.rate, 500);
    expect(data.netAmount, 1040);
    expect(data.gross, 1000);
    expect(data.lessAmount, 50);
    expect(data.gstTotal, 90);
    expect(data.company.name, 'Test Pharma');
    expect(data.remark, contains('Receipt No: RCP-1001'));
    expect(data.remark, contains('Sales Ref: 7788'));
    expect(data.remark, contains('Cash: 500.00'));
    expect(data.invoice.invoiceNo, isNot('2627CCB10497'));
    expect(data.company.name, isNot('PASHUSEVA AUSHADHALAYA'));
  });
}
