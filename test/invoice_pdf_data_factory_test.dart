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
    expect(data.remark, contains('Sales Ref: 7788'));
    expect(data.remark, contains('Cash: 500.00'));
    expect(data.balanceDue, 0.0);
    expect(data.formattedBalanceDue, 'NIL');
    expect(data.invoice.invoiceNo, isNot('2627CCB10497'));
    expect(data.company.name, isNot('PASHUSEVA AUSHADHALAYA'));
  });

  test('maps sales master and details from GET APIs into InvoicePdfData matching saved sale format', () {
    final master = SalesMasterData({
      'salesMaster_Id': 7788,
      'salesMaster_InvoiceNo': 'INV-7788',
      'salesMaster_InvoiceDate': '2026-09-03T10:30:00',
      'salesMaster_CustomerId': 11,
      'salesMaster_SubTotal': 1000.0,
      'salesMaster_TotalDiscount': 50.0,
      'salesMaster_TotalCGST': 45.0,
      'salesMaster_TotalSGST': 45.0,
      'salesMaster_TotalIGST': 0.0,
      'salesMaster_GrandTotal': 1040.0,
      'salesMaster_PaidAmount': 1040.0,
      'salesMaster_BalanceAmount': 0.0,
      'salesMaster_CashAmount': 500.0,
      'salesMaster_UPIAmount': 540.0,
      'salesMaster_BillingName': 'Ramesh Patil',
      'salesMaster_BillingAddress': 'Pune, Maharashtra',
      'salesMaster_BillingMobileNo': '9876543210',
      'salesMaster_BillingGSTNo': '27ABCDE1234F1Z5',
    });

    final details = [
      SalesDetailData({
        'salesEntryDetail_ProductId': 1,
        'salesEntryDetail_ProductName': 'Feed Mix 10KG',
        'salesEntryDetail_Qty': 2.0,
        'salesEntryDetail_SellingPrice': 500.0,
        'salesEntryDetail_Rate': 500.0,
        'salesEntryDetail_DiscountAmount': 50.0,
        'salesEntryDetail_GSTPercentage': 18.0,
        'salesEntryDetail_CGSTAmount': 45.0,
        'salesEntryDetail_SGSTAmount': 45.0,
        'salesEntryDetail_TotalTaxAmount': 90.0,
        'salesEntryDetail_TotalAmount': 1040.0,
        'salesEntryDetail_HSNCode': '23099039',
        'batch_Number': 'B-101',
      }),
    ];

    final company = CompanyListItem(
      compId: 1,
      compName: 'Test Pharma',
      compAddress: 'Shop 1',
      compCity: 'Pune',
      compState: 'Maharashtra',
      compGSTNo: '27AAAAA0000A1Z5',
      compMobileNo: '9000000000',
    );

    final customer = CustomerListItem(
      custId: 11,
      custCode: 'C-11',
      custName: 'Ramesh Patil',
      custMobileNo: '9876543210',
      custPANNo: 'ABCDE1234F',
    );

    final data = InvoicePdfDataFactory.fromMasterAndDetails(
      master: master,
      details: details,
      customer: customer,
      company: company,
    );

    expect(data.invoice.invoiceNo, 'INV-7788');
    expect(data.customer.name, 'Ramesh Patil');
    expect(data.customer.phone, '9876543210');
    expect(data.items.single.productName, 'Feed Mix 10KG');
    expect(data.items.single.qty, 2);
    expect(data.items.single.rate, 500);
    expect(data.items.single.batch, 'B-101');
    expect(data.netAmount, 1040);
    expect(data.gross, 1000);
    expect(data.lessAmount, 50);
    expect(data.gstTotal, 90);
    expect(data.company.name, 'Test Pharma');
    expect(data.remark, contains('Sales Ref: 7788'));
    expect(data.remark, contains('Cash: 500.00'));
    expect(data.balanceDue, 0.0);
    expect(data.formattedBalanceDue, 'NIL');
  });

  test('formats zero balance as NIL and non-zero balances as formatted currency', () {
    final zeroInvoice = InvoicePdfData.fromJson({
      'company': {'name': 'Test Co'},
      'invoice': {'invoiceNo': 'INV-1'},
      'customer': {'name': 'Customer 1'},
      'items': [],
      'bank': {},
      'salesMaster_CreditAmt': 0.00,
    });
    expect(zeroInvoice.balanceDue, 0.0);
    expect(zeroInvoice.isBalanceZero, isTrue);
    expect(zeroInvoice.formattedBalanceDue, 'NIL');

    final creditInvoice500 = InvoicePdfData.fromJson({
      'company': {'name': 'Test Co'},
      'invoice': {'invoiceNo': 'INV-2'},
      'customer': {'name': 'Customer 2'},
      'items': [],
      'bank': {},
      'salesMaster_CreditAmt': 500.00,
    });
    expect(creditInvoice500.balanceDue, 500.0);
    expect(creditInvoice500.isBalanceZero, isFalse);
    expect(creditInvoice500.formattedBalanceDue, '₹500.00');

    final creditInvoice1250 = InvoicePdfData.fromJson({
      'company': {'name': 'Test Co'},
      'invoice': {'invoiceNo': 'INV-3'},
      'customer': {'name': 'Customer 3'},
      'items': [],
      'bank': {},
      'salesMaster_CreditAmt': 1250.50,
    });
    expect(creditInvoice1250.balanceDue, 1250.50);
    expect(creditInvoice1250.isBalanceZero, isFalse);
    expect(creditInvoice1250.formattedBalanceDue, '₹1,250.50');
  });

  test('maps credit amount correctly in fromSavedSale with credit balance', () {
    final master = SalesEntryMasterData(
      customerId: 11,
      invoiceDate: DateTime(2026, 9, 3).toIso8601String(),
      subTotal: 1000,
      totalDiscount: 0,
      totalCGST: 0,
      totalSGST: 0,
      grandTotal: 1000,
      paidAmount: 500,
      balanceAmount: 500,
      cashAmount: 500,
      creditAmount: 500,
      billingName: 'Ramesh Patil',
    );

    final data = InvoicePdfDataFactory.fromSavedSale(
      salesResponse: SalesEntryUpsertResponse(
        status: true,
        message: 'Saved',
        data: SalesEntryUpsertResponseData(
          status: true,
          message: 'Saved',
          salesMasterId: 9900,
          salesMasterInvoiceNo: 'INV-9900',
        ),
      ),
      master: master,
      details: const [],
      productRows: const [],
      payment: SalesPaymentDetails(
        amounts: {
          SalesPaymentMode.cash: 500,
          SalesPaymentMode.credit: 500,
        },
      ),
      invoiceDate: DateTime(2026, 9, 3),
    );

    expect(data.balanceDue, 500.0);
    expect(data.isBalanceZero, isFalse);
    expect(data.formattedBalanceDue, '₹500.00');
  });

  test('maps credit amount in fromMasterAndDetails with credit balance', () {
    final master = SalesMasterData({
      'salesMaster_Id': 8899,
      'salesMaster_InvoiceNo': 'INV-8899',
      'salesMaster_InvoiceDate': '2026-09-03T10:30:00',
      'salesMaster_CustomerId': 11,
      'salesMaster_GrandTotal': 2000.0,
      'salesMaster_PaidAmount': 749.50,
      'salesMaster_CreditAmt': 1250.50,
      'salesMaster_BalanceAmount': 1250.50,
      'salesMaster_BillingName': 'Ramesh Patil',
    });

    final data = InvoicePdfDataFactory.fromMasterAndDetails(
      master: master,
      details: const [],
    );

    expect(data.balanceDue, 1250.50);
    expect(data.isBalanceZero, isFalse);
    expect(data.formattedBalanceDue, '₹1,250.50');
  });
}
