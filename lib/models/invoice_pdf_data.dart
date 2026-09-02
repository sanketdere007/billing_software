/// Invoice data used exclusively by the PDF generator.
///
/// This is the contract for future API integration. Populate it from an API
/// response via [InvoicePdfData.fromJson] without changing PDF layout code.
class InvoicePdfData {
  final InvoiceCompany company;
  final InvoiceMeta invoice;
  final InvoiceCustomer customer;
  final List<InvoiceLineItem> items;
  final double previousBalance;
  final InvoiceBankDetails bank;
  final String amountInWords;
  final String remark;
  final List<InvoiceGstSlab> gstSlabs;
  final double gross;
  final double addAmount;
  final double lessAmount;
  final double gstTotal;
  final double netAmount;
  final String jurisdiction;
  final String stateName;
  final String stateCode;
  final String softwareCredit;
  final String printedBy;
  final bool errorsAndOmissionsExcepted;

  const InvoicePdfData({
    required this.company,
    required this.invoice,
    required this.customer,
    required this.items,
    this.previousBalance = 0,
    required this.bank,
    this.amountInWords = '',
    this.remark = '',
    this.gstSlabs = const [],
    this.gross = 0,
    this.addAmount = 0,
    this.lessAmount = 0,
    this.gstTotal = 0,
    this.netAmount = 0,
    this.jurisdiction = '',
    this.stateName = '',
    this.stateCode = '',
    this.softwareCredit = '',
    this.printedBy = '',
    this.errorsAndOmissionsExcepted = true,
  });

  factory InvoicePdfData.fromJson(Map<String, dynamic> json) {
    return InvoicePdfData(
      company: InvoiceCompany.fromJson(
        _asMap(json['company'] ?? json['seller']),
      ),
      invoice: InvoiceMeta.fromJson(
        _asMap(json['invoice'] ?? json['invoiceMeta']),
      ),
      customer: InvoiceCustomer.fromJson(
        _asMap(json['customer'] ?? json['buyer'] ?? json['billTo']),
      ),
      items: _asList(json['items'] ?? json['products'])
          .whereType<Map>()
          .map((e) => InvoiceLineItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      previousBalance: _toDouble(
        json['previousBalance'] ?? json['prevBal'] ?? json['prevBalance'],
      ),
      bank: InvoiceBankDetails.fromJson(_asMap(json['bank'])),
      amountInWords: _str(
        json['amountInWords'] ?? json['inWords'] ?? json['amountInWord'],
      ),
      remark: _str(json['remark'] ?? json['remarks']),
      gstSlabs: _asList(json['gstSlabs'] ?? json['taxSlabs'])
          .whereType<Map>()
          .map((e) => InvoiceGstSlab.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      gross: _toDouble(json['gross'] ?? json['grossAmount']),
      addAmount: _toDouble(json['addAmount'] ?? json['add']),
      lessAmount: _toDouble(json['lessAmount'] ?? json['less']),
      gstTotal: _toDouble(json['gstTotal'] ?? json['gst'] ?? json['gstAmount']),
      netAmount: _toDouble(json['netAmount'] ?? json['grandTotal']),
      jurisdiction: _str(json['jurisdiction']),
      stateName: _str(json['stateName'] ?? json['state']),
      stateCode: _str(json['stateCode']),
      softwareCredit: _str(
        json['softwareCredit'] ?? json['printFooter'] ?? json['software'],
      ),
      printedBy: _str(json['printedBy'] ?? json['userName'] ?? json['user']),
      errorsAndOmissionsExcepted: json['errorsAndOmissionsExcepted'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company.toJson(),
      'invoice': invoice.toJson(),
      'customer': customer.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'previousBalance': previousBalance,
      'bank': bank.toJson(),
      'amountInWords': amountInWords,
      'remark': remark,
      'gstSlabs': gstSlabs.map((e) => e.toJson()).toList(),
      'gross': gross,
      'addAmount': addAmount,
      'lessAmount': lessAmount,
      'gstTotal': gstTotal,
      'netAmount': netAmount,
      'jurisdiction': jurisdiction,
      'stateName': stateName,
      'stateCode': stateCode,
      'softwareCredit': softwareCredit,
      'printedBy': printedBy,
      'errorsAndOmissionsExcepted': errorsAndOmissionsExcepted,
    };
  }

  String get resolvedAmountInWords {
    if (amountInWords.trim().isNotEmpty) return amountInWords.trim();
    return IndianCurrencyWords.convert(netAmount);
  }
}

class InvoiceCompany {
  final String name;
  final String address;
  final String phones;
  final String dlNumbers;
  final String gstNo;

  const InvoiceCompany({
    required this.name,
    this.address = '',
    this.phones = '',
    this.dlNumbers = '',
    this.gstNo = '',
  });

  factory InvoiceCompany.fromJson(Map<String, dynamic> json) {
    return InvoiceCompany(
      name: _str(json['name'] ?? json['companyName'] ?? json['compName']),
      address: _str(json['address'] ?? json['compAddress']),
      phones: _str(
        json['phones'] ?? json['phone'] ?? json['mobile'] ?? json['compMobileNo'],
      ),
      dlNumbers: _str(
        json['dlNumbers'] ?? json['dlNo'] ?? json['drugLicense'],
      ),
      gstNo: _str(json['gstNo'] ?? json['gstin'] ?? json['compGSTNo']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phones': phones,
        'dlNumbers': dlNumbers,
        'gstNo': gstNo,
      };
}

class InvoiceMeta {
  final String invoiceNo;
  final String date;
  final String time;
  final String salesman;
  final int pageNo;
  final int pageCount;
  final String title;

  const InvoiceMeta({
    required this.invoiceNo,
    this.date = '',
    this.time = '',
    this.salesman = '',
    this.pageNo = 1,
    this.pageCount = 1,
    this.title = 'TAX INVOICE',
  });

  factory InvoiceMeta.fromJson(Map<String, dynamic> json) {
    return InvoiceMeta(
      invoiceNo: _str(
        json['invoiceNo'] ?? json['number'] ?? json['salesMasterInvoiceNo'],
      ),
      date: _str(json['date'] ?? json['invoiceDate']),
      time: _str(json['time'] ?? json['invoiceTime']),
      salesman: _str(json['salesman'] ?? json['sMan'] ?? json['salesMan']),
      pageNo: _toInt(json['pageNo'] ?? json['page'], fallback: 1),
      pageCount: _toInt(json['pageCount'] ?? json['totalPages'], fallback: 1),
      title: _str(json['title'], fallback: 'TAX INVOICE'),
    );
  }

  Map<String, dynamic> toJson() => {
        'invoiceNo': invoiceNo,
        'date': date,
        'time': time,
        'salesman': salesman,
        'pageNo': pageNo,
        'pageCount': pageCount,
        'title': title,
      };

  String get pageLabel => '$pageNo/$pageCount';
}

class InvoiceCustomer {
  final String name;
  final String address;
  final String phone;
  final String registrationNo;
  final String gstNo;
  final String panNo;

  const InvoiceCustomer({
    required this.name,
    this.address = '',
    this.phone = '',
    this.registrationNo = '',
    this.gstNo = '',
    this.panNo = '',
  });

  factory InvoiceCustomer.fromJson(Map<String, dynamic> json) {
    return InvoiceCustomer(
      name: _str(json['name'] ?? json['customerName'] ?? json['billingName']),
      address: _str(
        json['address'] ?? json['customerAddress'] ?? json['billingAddress'],
      ),
      phone: _str(
        json['phone'] ?? json['mobile'] ?? json['billingMobileNo'],
      ),
      registrationNo: _str(
        json['registrationNo'] ?? json['regNo'] ?? json['dln'] ?? json['licenseNo'],
      ),
      gstNo: _str(json['gstNo'] ?? json['gstin'] ?? json['billingGSTNo']),
      panNo: _str(json['panNo'] ?? json['pan']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phone': phone,
        'registrationNo': registrationNo,
        'gstNo': gstNo,
        'panNo': panNo,
      };
}

class InvoiceLineItem {
  final String companyCode;
  final String productName;
  final String pack;
  final String hsn;
  final double qty;
  final String scheme;
  final double discount;
  final String batch;
  final String expiry;
  final double mrp;
  final double rate;
  final double gstPercent;
  final double gstAmount;
  final double amount;

  const InvoiceLineItem({
    this.companyCode = '',
    required this.productName,
    this.pack = '',
    this.hsn = '',
    this.qty = 0,
    this.scheme = '',
    this.discount = 0,
    this.batch = '',
    this.expiry = '',
    this.mrp = 0,
    this.rate = 0,
    this.gstPercent = 0,
    this.gstAmount = 0,
    this.amount = 0,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      companyCode: _str(
        json['companyCode'] ?? json['com'] ?? json['brand'] ?? json['company'],
      ),
      productName: _str(
        json['productName'] ?? json['name'] ?? json['salesEntryDetail_ProductName'],
      ),
      pack: _str(json['pack'] ?? json['unit'] ?? json['packing']),
      hsn: _str(json['hsn'] ?? json['hsnCode'] ?? json['salesEntryDetail_HSNCode']),
      qty: _toDouble(json['qty'] ?? json['quantity'] ?? json['salesEntryDetail_Qty']),
      scheme: _str(json['scheme'] ?? json['scm'] ?? json['freeQty']),
      discount: _toDouble(
        json['discount'] ?? json['disc'] ?? json['discountAmount'],
      ),
      batch: _str(json['batch'] ?? json['batchNo'] ?? json['batchNumber']),
      expiry: _str(json['expiry'] ?? json['exp'] ?? json['expiryDate']),
      mrp: _toDouble(json['mrp']),
      rate: _toDouble(json['rate'] ?? json['sellingPrice']),
      gstPercent: _toDouble(json['gstPercent'] ?? json['gstPercentage']),
      gstAmount: _toDouble(json['gstAmount'] ?? json['gstAmt']),
      amount: _toDouble(json['amount'] ?? json['totalAmount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'companyCode': companyCode,
        'productName': productName,
        'pack': pack,
        'hsn': hsn,
        'qty': qty,
        'scheme': scheme,
        'discount': discount,
        'batch': batch,
        'expiry': expiry,
        'mrp': mrp,
        'rate': rate,
        'gstPercent': gstPercent,
        'gstAmount': gstAmount,
        'amount': amount,
      };
}

class InvoiceBankDetails {
  final String name;
  final String branch;
  final String ifsc;
  final String accountNo;

  const InvoiceBankDetails({
    this.name = '',
    this.branch = '',
    this.ifsc = '',
    this.accountNo = '',
  });

  factory InvoiceBankDetails.fromJson(Map<String, dynamic> json) {
    return InvoiceBankDetails(
      name: _str(json['name'] ?? json['bankName']),
      branch: _str(json['branch'] ?? json['bankBranch']),
      ifsc: _str(json['ifsc'] ?? json['ifscCode']),
      accountNo: _str(json['accountNo'] ?? json['acNo'] ?? json['accountNumber']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'branch': branch,
        'ifsc': ifsc,
        'accountNo': accountNo,
      };
}

class InvoiceGstSlab {
  final String label;
  final double sgst;
  final double cgst;

  const InvoiceGstSlab({
    required this.label,
    this.sgst = 0,
    this.cgst = 0,
  });

  factory InvoiceGstSlab.fromJson(Map<String, dynamic> json) {
    return InvoiceGstSlab(
      label: _str(json['label'] ?? json['rate'] ?? json['percent']),
      sgst: _toDouble(json['sgst'] ?? json['sgstAmount']),
      cgst: _toDouble(json['cgst'] ?? json['cgstAmount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'sgst': sgst,
        'cgst': cgst,
      };
}

class IndianCurrencyWords {
  static const _ones = [
    '',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
    'ELEVEN',
    'TWELVE',
    'THIRTEEN',
    'FOURTEEN',
    'FIFTEEN',
    'SIXTEEN',
    'SEVENTEEN',
    'EIGHTEEN',
    'NINETEEN',
  ];

  static const _tens = [
    '',
    '',
    'TWENTY',
    'THIRTY',
    'FORTY',
    'FIFTY',
    'SIXTY',
    'SEVENTY',
    'EIGHTY',
    'NINETY',
  ];

  static String convert(double amount) {
    final rupees = amount.truncate();
    final paise = ((amount - rupees) * 100).round();
    if (rupees == 0 && paise == 0) return 'ZERO ONLY';

    final buffer = StringBuffer();
    if (rupees > 0) {
      buffer.write(_inWords(rupees));
    }
    if (paise > 0) {
      if (buffer.isNotEmpty) buffer.write(' AND PAISE ');
      buffer.write(_inWords(paise));
    }
    buffer.write(' ONLY');
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _inWords(int number) {
    if (number == 0) return 'ZERO';
    if (number < 0) return 'MINUS ${_inWords(-number)}';

    final parts = <String>[];
    final crore = number ~/ 10000000;
    number %= 10000000;
    final lakh = number ~/ 100000;
    number %= 100000;
    final thousand = number ~/ 1000;
    number %= 1000;
    final hundred = number ~/ 100;
    number %= 100;

    if (crore > 0) parts.add('${_twoDigit(crore)} CRORE');
    if (lakh > 0) parts.add('${_twoDigit(lakh)} LAKH');
    if (thousand > 0) parts.add('${_twoDigit(thousand)} THOUSAND');
    if (hundred > 0) parts.add('${_ones[hundred]} HUNDRED');
    if (number > 0) parts.add(_twoDigit(number));
    return parts.join(' ');
  }

  static String _twoDigit(int number) {
    if (number < 20) return _ones[number];
    final ten = number ~/ 10;
    final one = number % 10;
    if (one == 0) return _tens[ten];
    return '${_tens[ten]} ${_ones[one]}';
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String _str(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
