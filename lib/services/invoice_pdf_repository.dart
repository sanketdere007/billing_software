import '../models/invoice_pdf_data.dart';

/// Test-only sample invoice payload.
/// Production PDFs are built from saved Sales Entry + Receipt Entry data
/// via [InvoicePdfDataFactory] — this repository is not used at runtime.
class InvoicePdfRepository {
  Future<InvoicePdfData> fetchInvoice() async {
    return InvoicePdfData.fromJson(sampleInvoiceJson);
  }

  /// Sample payload used by unit tests to verify PDF layout generation.
  static const Map<String, dynamic> sampleInvoiceJson = {
    'company': {
      'name': 'PASHUSEVA AUSHADHALAYA',
      'address':
          'SHOP NO 1, 2, 3 GROUND FLOOR & FIRST FLOOR, TEMKAR PROPERTY CHANDOLI RD A/P MANCHAR, TAL AMBEGAON DIST PUNE 410503',
      'phones': '8600012526, 9822521490',
      'dlNumbers': '20B-MH-PZ4-72002, 21B-MH-PZ4-72003, 20D-MH-PZ4-72004',
      'gstNo': '27AOBPT6580M1Z8',
    },
    'invoice': {
      'invoiceNo': '2627CCB10497',
      'date': '28/07/2026',
      'time': '09:49:59 AM',
      'salesman': '',
      'pageNo': 1,
      'pageCount': 1,
      'title': 'TAX INVOICE',
    },
    'customer': {
      'name': 'DR DHERANGE NITTIN PILAGI',
      'address': 'AT POST PETH TAL AMBEGAON DIST PUNE',
      'phone': '9822492517',
      'registrationNo': 'DLN M.V.SC.REG NO- 5719',
      'gstNo': '',
      'panNo': '',
    },
    'items': [
      {
        'companyCode': 'ALE',
        'productName': 'KHURAK POW 15KG',
        'pack': '15 KG',
        'hsn': '23099039',
        'qty': 3,
        'scheme': '',
        'discount': 0,
        'batch': 'CK26576049',
        'expiry': '04/28',
        'mrp': 3813.00,
        'rate': 2801.00,
        'gstPercent': 0,
        'gstAmount': 0,
        'amount': 8403.00,
      },
      {
        'companyCode': 'ALE',
        'productName': 'KHURAK 5KG',
        'pack': '5KG',
        'hsn': '23099039',
        'qty': 6,
        'scheme': '',
        'discount': 0,
        'batch': 'CK6923133',
        'expiry': '04/28',
        'mrp': 1362.00,
        'rate': 1000.00,
        'gstPercent': 0,
        'gstAmount': 0,
        'amount': 6000.00,
      },
    ],
    'previousBalance': 20005.00,
    'bank': {
      'name': 'AXIS BANK',
      'branch': 'MANCHAR',
      'ifsc': 'UTIB0002653',
      'accountNo': '925020024563723',
    },
    'amountInWords': 'FOURTEEN THOUSAND FOUR HUNDRED THREE ONLY',
    'remark': 'GPAY 9822521490 PHONE PAY 9822521490',
    'gstSlabs': [
      {'label': '2.5%', 'sgst': 0, 'cgst': 0},
      {'label': '6.0%', 'sgst': 0, 'cgst': 0},
      {'label': '9.0%', 'sgst': 0, 'cgst': 0},
      {'label': '14%', 'sgst': 0, 'cgst': 0},
    ],
    'gross': 14403.00,
    'addAmount': 0.00,
    'lessAmount': 0.00,
    'gstTotal': 0.00,
    'netAmount': 14403.00,
    'jurisdiction': 'AMBEGAON',
    'stateName': 'MAHARASHTRA',
    'stateCode': '27',
    'softwareCredit': 'Care Software 9822633375',
    'printedBy': 'ANKUSH',
    'errorsAndOmissionsExcepted': true,
  };
}
