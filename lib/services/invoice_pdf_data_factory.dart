import 'package:intl/intl.dart';

import '../models/batch.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/invoice_pdf_data.dart';
import '../models/login_response.dart';
import '../models/sales_entry.dart';
import '../screens/sales/sales_entry/payment_mode_dialog.dart';
import 'product_service.dart';

/// Maps saved Sales Entry + Receipt Entry data into [InvoicePdfData].
/// Contains no API calls and no hardcoded business records.
class InvoicePdfDataFactory {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm:ss a');

  static InvoicePdfData fromSavedSale({
    required SalesEntryUpsertResponse salesResponse,
    required SalesEntryMasterData master,
    required List<SalesEntryDetailData> details,
    required List<Map<String, dynamic>> productRows,
    required SalesPaymentDetails payment,
    required DateTime invoiceDate,
    CustomerListItem? customer,
    CompanyListItem? company,
    UserData? user,
    Map<String, dynamic>? receiptResponse,
    String? companyNameFallback,
  }) {
    final invoiceNo = salesResponse.data?.salesMasterInvoiceNo.trim() ?? '';
    final salesMasterId = salesResponse.data?.salesMasterId ?? master.salesMasterId;
    final receiptNo = _receiptNoFrom(receiptResponse);
    final receiptDate = _receiptDateFrom(receiptResponse) ?? invoiceDate;
    final now = DateTime.now();

    return InvoicePdfData(
      company: _company(company, companyNameFallback),
      invoice: InvoiceMeta(
        invoiceNo: invoiceNo.isNotEmpty
            ? invoiceNo
            : (receiptNo.isNotEmpty ? receiptNo : ''),
        date: _dateFormat.format(invoiceDate),
        time: _timeFormat.format(now),
        salesman: '',
        pageNo: 1,
        pageCount: 1,
        title: 'TAX INVOICE',
      ),
      customer: _customer(customer, master),
      items: _items(details, productRows),
      previousBalance: 0,
      bank: InvoiceBankDetails(
        name: payment.bankName.isNotEmpty
            ? payment.bankName
            : master.bankName,
        branch: '',
        ifsc: '',
        accountNo: '',
      ),
      amountInWords: '',
      remark: _remark(
        master: master,
        payment: payment,
        salesMasterId: salesMasterId,
        receiptNo: receiptNo,
        receiptDate: receiptDate,
      ),
      gstSlabs: _gstSlabs(details),
      gross: master.subTotal,
      addAmount: 0,
      lessAmount: master.totalDiscount,
      gstTotal: master.totalCGST + master.totalSGST + master.totalIGST,
      netAmount: master.grandTotal,
      jurisdiction: company?.compCity.trim() ?? '',
      stateName: (company?.compState ?? '').trim().toUpperCase(),
      stateCode: _stateCode(company?.compGSTNo),
      softwareCredit: '',
      printedBy: (user?.firstAndLastName ?? user?.empUserName ?? '').trim(),
      errorsAndOmissionsExcepted: true,
    );
  }

  static InvoiceCompany _company(CompanyListItem? company, String? fallbackName) {
    if (company == null) {
      return InvoiceCompany(name: (fallbackName ?? '').trim());
    }

    final phones = [
      company.compMobileNo,
      company.compAlternateMobileNo,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final address = [
      company.compAddress,
      company.compArea,
      company.compCity,
      company.compState,
      company.compPincode,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    return InvoiceCompany(
      name: company.compName,
      address: address,
      phones: phones,
      gstNo: company.compGSTNo,
    );
  }

  static InvoiceCustomer _customer(
    CustomerListItem? customer,
    SalesEntryMasterData master,
  ) {
    return InvoiceCustomer(
      name: master.billingName.isNotEmpty
          ? master.billingName
          : (customer?.custName ?? ''),
      address: master.billingAddress.isNotEmpty
          ? master.billingAddress
          : (customer?.fullAddress ?? ''),
      phone: master.billingMobileNo.isNotEmpty
          ? master.billingMobileNo
          : (customer?.custMobileNo ?? ''),
      gstNo: master.billingGSTNo.isNotEmpty
          ? master.billingGSTNo
          : (customer?.custGSTNo ?? ''),
      panNo: customer?.custPANNo ?? '',
    );
  }

  static List<InvoiceLineItem> _items(
    List<SalesEntryDetailData> details,
    List<Map<String, dynamic>> productRows,
  ) {
    return details.map((detail) {
      final batch = _batchFor(detail, productRows);
      final product = productService.getProductByIdFromCache(detail.productId);
      final hsn = detail.hsnCode.isNotEmpty
          ? detail.hsnCode
          : (product?.prodHSNCode ?? '');
      final unitName = (batch?.unitName.isNotEmpty == true)
          ? batch!.unitName
          : (product?.prodUnitName ?? '');
      final unitValueText =
          product?.formattedUnitValue ?? batch?.formattedUnitValue ?? '0';
      final pack = [if (unitName.isNotEmpty) unitName, unitValueText].join(' ');
      final companyCode = batch?.prodCode ?? product?.prodCode ?? '';
      final mrp = (batch != null && batch.batchMRP > 0) ? batch.batchMRP : detail.mrp;

      return InvoiceLineItem(
        companyCode: companyCode,
        productName: detail.productName,
        pack: pack,
        hsn: hsn,
        qty: detail.qty,
        scheme: detail.freeQty > 0 ? _qtyText(detail.freeQty) : '',
        discount: detail.discountAmount,
        batch: '',
        expiry: '',
        mrp: mrp,
        rate: detail.rate,
        gstPercent: detail.gstPercentage,
        gstAmount: detail.totalTaxAmount,
        amount: detail.totalAmount,
      );
    }).toList();
  }

  static BatchListItem? _batchFor(
    SalesEntryDetailData detail,
    List<Map<String, dynamic>> productRows,
  ) {
    for (final row in productRows) {
      final product = row['product'];
      if (product is BatchListItem && product.batchId == detail.batchId) {
        return product;
      }
    }
    return null;
  }

  static List<InvoiceGstSlab> _gstSlabs(List<SalesEntryDetailData> details) {
    final sgst = <String, double>{
      '2.5%': 0,
      '6.0%': 0,
      '9.0%': 0,
      '14%': 0,
    };
    final cgst = Map<String, double>.from(sgst);

    for (final detail in details) {
      final label = _slabLabel(detail.gstPercentage / 2);
      sgst[label] = (sgst[label] ?? 0) + detail.sgstAmount;
      cgst[label] = (cgst[label] ?? 0) + detail.cgstAmount;
    }

    return sgst.keys
        .map(
          (label) => InvoiceGstSlab(
            label: label,
            sgst: sgst[label] ?? 0,
            cgst: cgst[label] ?? 0,
          ),
        )
        .toList();
  }

  static String _slabLabel(double halfRate) {
    if ((halfRate - 2.5).abs() < 0.2) return '2.5%';
    if ((halfRate - 6.0).abs() < 0.2) return '6.0%';
    if ((halfRate - 9.0).abs() < 0.2) return '9.0%';
    if ((halfRate - 14.0).abs() < 0.6) return '14%';
    if (halfRate <= 0) return '2.5%';
    return '${halfRate.toStringAsFixed(1)}%';
  }

  static String _remark({
    required SalesEntryMasterData master,
    required SalesPaymentDetails payment,
    required int salesMasterId,
    required String receiptNo,
    required DateTime receiptDate,
  }) {
    final parts = <String>[];
    if (receiptNo.isNotEmpty) parts.add('Receipt No: $receiptNo');
    parts.add('Receipt Date: ${_dateFormat.format(receiptDate)}');
    if (salesMasterId > 0) parts.add('Sales Ref: $salesMasterId');

    final mode = payment.mode.isNotEmpty ? payment.mode : _paymentModeFrom(master);
    if (mode.isNotEmpty) parts.add('Mode: $mode');

    void addAmount(String label, double value) {
      if (value > 0) parts.add('$label: ${value.toStringAsFixed(2)}');
    }

    addAmount('Cash', payment.cashAmount > 0 ? payment.cashAmount : master.cashAmount);
    addAmount('UPI', payment.upiAmount > 0 ? payment.upiAmount : master.upiAmount);
    addAmount('Cheque', payment.chequeAmount > 0 ? payment.chequeAmount : master.chequeAmount);
    addAmount('Bank', payment.bankAmount > 0 ? payment.bankAmount : master.bankAmount);
    addAmount('Card', payment.cardAmount > 0 ? payment.cardAmount : master.cardAmount);
    addAmount('Credit', payment.creditAmount > 0 ? payment.creditAmount : master.creditAmount);

    final chequeNo = payment.chequeNo.isNotEmpty ? payment.chequeNo : master.chequeNo;
    if (chequeNo.isNotEmpty) parts.add('Cheque No: $chequeNo');

    final bankRef = payment.bankReferenceNo.isNotEmpty
        ? payment.bankReferenceNo
        : master.bankReferenceNo;
    if (bankRef.isNotEmpty) parts.add('Bank Ref: $bankRef');

    final neftRef = payment.neftReferenceNo.isNotEmpty
        ? payment.neftReferenceNo
        : master.neftReferenceNo;
    if (neftRef.isNotEmpty) parts.add('NEFT Ref: $neftRef');

    if (payment.upiTransactionNo.trim().isNotEmpty) {
      parts.add('UPI Txn: ${payment.upiTransactionNo.trim()}');
    }
    if (payment.upiReferenceNo.trim().isNotEmpty) {
      parts.add('UPI Ref: ${payment.upiReferenceNo.trim()}');
    }

    final remark = payment.remark.isNotEmpty ? payment.remark : master.remark;
    if (remark.trim().isNotEmpty) parts.add(remark.trim());

    return parts.join(' | ');
  }

  static String _paymentModeFrom(SalesEntryMasterData master) {
    final active = <String>[];
    if (master.cashAmount > 0) active.add('Cash');
    if (master.upiAmount > 0) active.add('UPI');
    if (master.chequeAmount > 0) active.add('Cheque');
    if (master.bankAmount > 0) active.add('Bank');
    if (master.cardAmount > 0) active.add('Card');
    if (master.creditAmount > 0) active.add('Credit');
    if (active.isEmpty) return '';
    if (active.length == 1) return active.first;
    return 'Split';
  }

  static String _receiptNoFrom(Map<String, dynamic>? response) {
    if (response == null) return '';
    final data = response['data'];
    if (data is Map) {
      final value = data['receiptMaster_ReceiptNo'] ??
          data['receiptMasterReceiptNo'] ??
          data['receiptNo'];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    final fallback = response['receiptMaster_ReceiptNo'] ?? response['receiptNo'];
    return fallback?.toString().trim() ?? '';
  }

  static DateTime? _receiptDateFrom(Map<String, dynamic>? response) {
    if (response == null) return null;
    final data = response['data'];
    final raw = data is Map
        ? (data['receiptMaster_ReceiptDate'] ?? data['receiptMasterReceiptDate'])
        : response['receiptMaster_ReceiptDate'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _stateCode(String? gstNo) {
    final gst = (gstNo ?? '').trim();
    if (gst.length >= 2 && RegExp(r'^\d{2}').hasMatch(gst)) {
      return gst.substring(0, 2);
    }
    return '';
  }

  static String _qtyText(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
