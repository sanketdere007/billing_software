import 'package:intl/intl.dart';

class ReceiptPdfData {
  final String companyName;
  final String branchName;
  final String companyAddress;
  final String receiptDate;
  final String receiptNo;
  final String invoiceNo;
  final String customerName;
  final String customerMobile;
  final String customerAddress;
  
  final double cashAmount;
  final String cashRemark;
  
  final double cardAmount;
  
  final double upiAmount;
  final String upiTransactionNo;
  final String upiReferenceNo;
  
  final double bankAmount;
  final String bankName;
  final String bankAccountNo;
  final String bankTransactionNo;
  final String bankReferenceNo;
  final String bankTransferType;
  
  final double chequeAmount;
  final String chequeNo;
  final String chequeBankName;
  
  final double otherAmount;
  final String otherType;
  final String otherReference;
  final String otherRemark;
  
  final double totalAmount;
  final String remarks;
  final String amountInWords;

  const ReceiptPdfData({
    required this.companyName,
    this.branchName = '',
    this.companyAddress = '',
    required this.receiptDate,
    required this.receiptNo,
    this.invoiceNo = '',
    required this.customerName,
    this.customerMobile = '',
    this.customerAddress = '',
    
    this.cashAmount = 0,
    this.cashRemark = '',
    
    this.cardAmount = 0,
    
    this.upiAmount = 0,
    this.upiTransactionNo = '',
    this.upiReferenceNo = '',
    
    this.bankAmount = 0,
    this.bankName = '',
    this.bankAccountNo = '',
    this.bankTransactionNo = '',
    this.bankReferenceNo = '',
    this.bankTransferType = '',
    
    this.chequeAmount = 0,
    this.chequeNo = '',
    this.chequeBankName = '',
    
    this.otherAmount = 0,
    this.otherType = '',
    this.otherReference = '',
    this.otherRemark = '',
    
    required this.totalAmount,
    this.remarks = '',
    required this.amountInWords,
  });
}
