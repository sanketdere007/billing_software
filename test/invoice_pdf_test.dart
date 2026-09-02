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
  });
}
