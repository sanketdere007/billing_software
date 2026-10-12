import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/services/invoice_pdf_generator.dart';
import 'package:billing_software/services/invoice_pdf_repository.dart';

void main() {
  test('invoice PDF generates non-empty bytes from sample data', () async {
    final data = await InvoicePdfRepository().fetchInvoice();
    final bytes = await InvoicePdfGenerator().generate(data);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(data.company.name, 'PASHUSEVA AUSHADHALAYA');
    expect(data.invoice.invoiceNo, '2627CCB10497');
    expect(data.items.length, 2);
    expect(data.netAmount, 14403.00);
    expect(data.balanceDue, 0.0);
    expect(data.formattedBalanceDue, 'NIL');
  });

  test('invoice PDF generates correctly for non-zero balance without font errors', () async {
    final baseData = await InvoicePdfRepository().fetchInvoice();
    final json = baseData.toJson();
    json['balanceDue'] = 1250.50;

    final creditData = baseData.copyWith(balanceDue: 1250.50);
    final bytes = await InvoicePdfGenerator().generate(creditData);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(creditData.balanceDue, 1250.50);
    expect(creditData.formattedBalanceDue, '₹1,250.50');
  });

  test('InvoicePdfGenerator.formatBalanceDue formats NIL and Indian currency accurately', () {
    expect(InvoicePdfGenerator.formatBalanceDue(0), 'NIL');
    expect(InvoicePdfGenerator.formatBalanceDue(0.00), 'NIL');
    expect(InvoicePdfGenerator.formatBalanceDue(0.0001), 'NIL');
    expect(InvoicePdfGenerator.formatBalanceDue(500.00), '₹500.00');
    expect(InvoicePdfGenerator.formatBalanceDue(1250.50), '₹1,250.50');
  });
}
