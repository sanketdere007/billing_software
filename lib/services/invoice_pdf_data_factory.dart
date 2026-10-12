import 'package:intl/intl.dart';

import '../models/batch.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/invoice_pdf_data.dart';
import '../models/login_response.dart';
import '../models/sales_entry.dart';
import '../screens/sales/sales_entry/payment_mode_dialog.dart';
import 'batch_service.dart';
import 'company_service.dart';
import 'customer_service.dart';
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
    String? companyNameFallback,
  }) {
    final invoiceNo = salesResponse.data?.salesMasterInvoiceNo.trim() ?? '';
    final salesMasterId = salesResponse.data?.salesMasterId ?? master.salesMasterId;
    final now = DateTime.now();
    final effectiveBalance = payment.creditAmount > 0
        ? payment.creditAmount
        : (master.creditAmount > 0
            ? master.creditAmount
            : master.balanceAmount);

    return InvoicePdfData(
      company: _company(company, companyNameFallback),
      invoice: InvoiceMeta(
        invoiceNo: invoiceNo,
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
      balanceDue: effectiveBalance,
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

  /// Maps fetched sales master and detail records (from GET APIs) into [InvoicePdfData].
  /// Uses the exact same PDF mapping, formatting, and calculation logic as [fromSavedSale].
  static InvoicePdfData fromMasterAndDetails({
    required SalesMasterData master,
    required List<SalesDetailData> details,
    CustomerListItem? customer,
    CompanyListItem? company,
    UserData? user,
    String? companyNameFallback,
  }) {
    final detailData = details.map((d) => SalesEntryDetailData.fromRaw(d.raw)).toList();
    final masterData = SalesEntryMasterData.fromRaw(master.raw, details: detailData);

    CustomerListItem? effectiveCustomer = customer;
    if (effectiveCustomer == null && masterData.customerId > 0) {
      try {
        effectiveCustomer = customerService.customers.firstWhere(
          (c) => c.custId == masterData.customerId,
        );
      } catch (_) {}
    }

    final effectiveCompany = company ??
        (masterData.compId > 0
            ? companyService.getCompanyById(masterData.compId)
            : null);

    final invoiceNo = master.raw['salesMaster_InvoiceNo']?.toString().trim() ??
        master.raw['invoiceNo']?.toString().trim() ??
        '';
    final salesMasterId = masterData.salesMasterId;
    final invoiceDate = DateTime.tryParse(masterData.invoiceDate) ?? DateTime.now();
    final now = DateTime.now();

    final amountsMap = <String, double>{
      if (masterData.cashAmount > 0) SalesPaymentMode.cash: masterData.cashAmount,
      if (masterData.upiAmount > 0) SalesPaymentMode.upi: masterData.upiAmount,
      if (masterData.cardAmount > 0) SalesPaymentMode.card: masterData.cardAmount,
      if (masterData.chequeAmount > 0) SalesPaymentMode.cheque: masterData.chequeAmount,
      if (masterData.bankAmount > 0) SalesPaymentMode.bank: masterData.bankAmount,
      if (masterData.otherAmount > 0) SalesPaymentMode.other: masterData.otherAmount,
      if (masterData.creditAmount > 0) SalesPaymentMode.credit: masterData.creditAmount,
    };
    if (amountsMap.isEmpty) {
      if (masterData.paidAmount > 0) {
        amountsMap[SalesPaymentMode.cash] = masterData.paidAmount;
      } else if (masterData.balanceAmount > 0) {
        amountsMap[SalesPaymentMode.credit] = masterData.balanceAmount;
      }
    }

    final payment = SalesPaymentDetails(
      amounts: amountsMap,
      chequeNo: masterData.chequeNo,
      chequeDate: masterData.chequeDate != null ? DateTime.tryParse(masterData.chequeDate!) : null,
      bankName: masterData.bankName,
      bankReferenceNo: masterData.bankReferenceNo,
      neftType: masterData.neftType,
      neftReferenceNo: masterData.neftReferenceNo,
      otherType: masterData.otherPaymentType,
      otherReferenceNo: masterData.otherReferenceNo,
      otherDate: masterData.otherDate != null ? DateTime.tryParse(masterData.otherDate!) : null,
      otherRemark: masterData.otherRemark,
    );

    final previousBalance = double.tryParse(
      (master.raw['salesMaster_PreviousBalance'] ?? master.raw['previousBalance'] ?? 0).toString(),
    ) ?? 0.0;
    final effectiveBalance = masterData.creditAmount > 0
        ? masterData.creditAmount
        : (masterData.balanceAmount > 0
            ? masterData.balanceAmount
            : double.tryParse(
                    (master.raw['salesMaster_CreditAmt'] ??
                            master.raw['creditAmount'] ??
                            master.raw['salesMaster_BalanceAmount'] ??
                            master.raw['balanceAmount'] ??
                            0)
                        .toString(),
                  ) ??
                  0.0);

    return InvoicePdfData(
      company: _company(effectiveCompany, companyNameFallback ?? master.raw['comp_Name']?.toString()),
      invoice: InvoiceMeta(
        invoiceNo: invoiceNo,
        date: _dateFormat.format(invoiceDate),
        time: _timeFormat.format(now),
        salesman: master.raw['salesman']?.toString() ?? master.raw['emp_Name']?.toString() ?? '',
        pageNo: 1,
        pageCount: 1,
        title: 'TAX INVOICE',
      ),
      customer: _customer(effectiveCustomer, masterData),
      items: _items(detailData, const []),
      previousBalance: previousBalance,
      balanceDue: effectiveBalance,
      bank: InvoiceBankDetails(
        name: payment.bankName.isNotEmpty ? payment.bankName : masterData.bankName,
        branch: '',
        ifsc: '',
        accountNo: '',
      ),
      amountInWords: '',
      remark: _remark(
        master: masterData,
        payment: payment,
        salesMasterId: salesMasterId,
      ),
      gstSlabs: _gstSlabs(detailData),
      gross: masterData.subTotal,
      addAmount: 0,
      lessAmount: masterData.totalDiscount,
      gstTotal: masterData.totalCGST + masterData.totalSGST + masterData.totalIGST,
      netAmount: masterData.grandTotal,
      jurisdiction: effectiveCompany?.compCity.trim() ?? '',
      stateName: (effectiveCompany?.compState ?? '').trim().toUpperCase(),
      stateCode: _stateCode(effectiveCompany?.compGSTNo),
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
      final unitShortName = detail.unitName.isNotEmpty
          ? detail.unitName
          : (product?.prodUnitShortName ?? '');
      final unitValueText =
          product?.formattedUnitValue ?? batch?.formattedUnitValue ?? '0';
      final pack = [
        unitValueText,
        if (unitShortName.isNotEmpty) unitShortName
      ].where((s) => s.isNotEmpty).join(' ').trim();
      final companyCode = detail.prodCode.isNotEmpty
          ? detail.prodCode
          : (batch?.prodCode ?? product?.prodCode ?? '');
      final mrp = (batch != null && batch.batchMRP > 0)
          ? batch.batchMRP
          : (detail.mrp > 0 ? detail.mrp : detail.rate);
      final batchNumber = detail.batchNumber.isNotEmpty
          ? detail.batchNumber
          : (batch?.batchNumber ?? '');
      final expiry = detail.expiry.isNotEmpty ? detail.expiry : '';

      return InvoiceLineItem(
        companyCode: companyCode,
        productName: detail.productName,
        pack: pack,
        hsn: hsn,
        qty: detail.qty,
        scheme: detail.freeQty > 0 ? _qtyText(detail.freeQty) : '',
        discount: detail.discountAmount,
        batch: batchNumber,
        expiry: expiry,
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
    if (detail.batchId > 0) {
      try {
        return batchService.batches.firstWhere(
          (b) => b.batchId == detail.batchId,
        );
      } catch (_) {}
    }
    return null;
  }

  static List<InvoiceGstSlab> _gstSlabs(List<SalesEntryDetailData> details) {
    final sgst = <String, double>{};
    final cgst = <String, double>{};

    for (final detail in details) {
      if (detail.gstPercentage <= 0) continue;
      final label = _slabLabel(detail.gstPercentage / 2);
      sgst[label] = (sgst[label] ?? 0) + detail.sgstAmount;
      cgst[label] = (cgst[label] ?? 0) + detail.cgstAmount;
    }

    final slabs = sgst.keys
        .where((label) => (sgst[label] ?? 0) > 0 || (cgst[label] ?? 0) > 0)
        .map(
          (label) => InvoiceGstSlab(
            label: label,
            sgst: sgst[label] ?? 0,
            cgst: cgst[label] ?? 0,
          ),
        )
        .toList();

    slabs.sort((a, b) {
      final aVal = double.tryParse(a.label.replaceAll('%', '')) ?? 0;
      final bVal = double.tryParse(b.label.replaceAll('%', '')) ?? 0;
      return aVal.compareTo(bVal);
    });
    return slabs;
  }

  static String _slabLabel(double halfRate) {
    if ((halfRate - 2.5).abs() < 0.2) return '2.5%';
    if ((halfRate - 6.0).abs() < 0.2) return '6.0%';
    if ((halfRate - 9.0).abs() < 0.2) return '9.0%';
    if ((halfRate - 14.0).abs() < 0.6) return '14.0%';
    return '${halfRate.toStringAsFixed(1)}%';
  }

  static String _remark({
    required SalesEntryMasterData master,
    required SalesPaymentDetails payment,
    required int salesMasterId,
  }) {
    final parts = <String>[];
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
