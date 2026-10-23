/// Model for Stock Ledger Report (`/api/Report/StockLedgerReport`)
class StockLedgerItem {
  final int stockLedgerId;
  final int stockLedgerCompId;
  final int stockLedgerBranchId;
  final int stockLedgerProductId;
  final int stockLedgerBatchId;
  final DateTime? stockLedgerDate;
  final String stockLedgerType;
  final String stockLedgerTransactionType;
  final int stockLedgerReferenceId;
  final String stockLedgerReferenceNo;
  final double quantity;
  final double beforeStock;
  final double afterStock;
  final double physicalStock;
  final double adjustmentQty;
  final String stockLedgerRemark;
  final int stockLedgerCreatedBy;
  final DateTime? stockLedgerCreatedDate;
  final int totalRecords;
  final String prodName;
  final String batchNumber;

  StockLedgerItem({
    required this.stockLedgerId,
    required this.stockLedgerCompId,
    required this.stockLedgerBranchId,
    required this.stockLedgerProductId,
    required this.stockLedgerBatchId,
    this.stockLedgerDate,
    required this.stockLedgerType,
    required this.stockLedgerTransactionType,
    required this.stockLedgerReferenceId,
    required this.stockLedgerReferenceNo,
    required this.quantity,
    required this.beforeStock,
    required this.afterStock,
    required this.physicalStock,
    required this.adjustmentQty,
    required this.stockLedgerRemark,
    required this.stockLedgerCreatedBy,
    this.stockLedgerCreatedDate,
    required this.totalRecords,
    required this.prodName,
    required this.batchNumber,
  });

  factory StockLedgerItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return StockLedgerItem(
      stockLedgerId: (json['stockLedger_Id'] as num?)?.toInt() ?? 0,
      stockLedgerCompId: (json['stockLedger_CompId'] as num?)?.toInt() ?? 0,
      stockLedgerBranchId: (json['stockLedger_BranchId'] as num?)?.toInt() ?? 0,
      stockLedgerProductId: (json['stockLedger_ProductId'] as num?)?.toInt() ?? 0,
      stockLedgerBatchId: (json['stockLedger_BatchId'] as num?)?.toInt() ?? 0,
      stockLedgerDate: parseDate(json['stockLedger_Date']),
      stockLedgerType: json['stockLedger_Type']?.toString() ?? '',
      stockLedgerTransactionType:
          json['stockLedger_TransactionType']?.toString() ?? '',
      stockLedgerReferenceId:
          (json['stockLedger_ReferenceId'] as num?)?.toInt() ?? 0,
      stockLedgerReferenceNo: json['stockLedger_ReferenceNo']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      beforeStock: (json['beforeStock'] as num?)?.toDouble() ?? 0.0,
      afterStock: (json['afterStock'] as num?)?.toDouble() ?? 0.0,
      physicalStock: (json['physicalStock'] as num?)?.toDouble() ?? 0.0,
      adjustmentQty: (json['adjustmentQty'] as num?)?.toDouble() ?? 0.0,
      stockLedgerRemark: json['stockLedger_Remark']?.toString() ?? '',
      stockLedgerCreatedBy:
          (json['stockLedger_CreatedBy'] as num?)?.toInt() ?? 0,
      stockLedgerCreatedDate: parseDate(json['stockLedger_CreatedDate']),
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      prodName: json['prod_Name']?.toString() ?? '',
      batchNumber: json['batch_Number']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockLedger_Id': stockLedgerId,
      'stockLedger_CompId': stockLedgerCompId,
      'stockLedger_BranchId': stockLedgerBranchId,
      'stockLedger_ProductId': stockLedgerProductId,
      'stockLedger_BatchId': stockLedgerBatchId,
      'stockLedger_Date': stockLedgerDate?.toIso8601String(),
      'stockLedger_Type': stockLedgerType,
      'stockLedger_TransactionType': stockLedgerTransactionType,
      'stockLedger_ReferenceId': stockLedgerReferenceId,
      'stockLedger_ReferenceNo': stockLedgerReferenceNo,
      'quantity': quantity,
      'beforeStock': beforeStock,
      'afterStock': afterStock,
      'physicalStock': physicalStock,
      'adjustmentQty': adjustmentQty,
      'stockLedger_Remark': stockLedgerRemark,
      'stockLedger_CreatedBy': stockLedgerCreatedBy,
      'stockLedger_CreatedDate': stockLedgerCreatedDate?.toIso8601String(),
      'totalRecords': totalRecords,
      'prod_Name': prodName,
      'batch_Number': batchNumber,
    };
  }
}

class StockLedgerReportData {
  final List<StockLedgerItem> items;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  StockLedgerReportData({
    required this.items,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory StockLedgerReportData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return StockLedgerReportData(
      items: rawItems
          .map((e) => StockLedgerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    );
  }
}

class StockLedgerReportResponse {
  final bool status;
  final String message;
  final StockLedgerReportData? data;
  final String? error;

  StockLedgerReportResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory StockLedgerReportResponse.fromJson(Map<String, dynamic> json) {
    return StockLedgerReportResponse(
      status: json['status'] == true ||
          json['status'] == 1 ||
          json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? StockLedgerReportData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}

class StockLedgerReportRequest {
  final int compId;
  final int branchId;
  final DateTime fromDate;
  final DateTime toDate;
  final int? productId;
  final int? batchId;
  final String? transactionType;
  final String? type;
  final String? search;
  final int pageNumber;
  final int pageSize;

  StockLedgerReportRequest({
    required this.compId,
    required this.branchId,
    required this.fromDate,
    required this.toDate,
    this.productId,
    this.batchId,
    this.transactionType,
    this.type,
    this.search,
    this.pageNumber = 1,
    this.pageSize = 30,
  });

  Map<String, String> toQueryParameters() {
    final fromDateApi = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
      0,
      0,
      0,
    );
    final toDateApi = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
      23,
      59,
      59,
      999,
    );

    final params = <String, String>{
      'CompId': compId.toString(),
      'BranchId': branchId.toString(),
      'FromDate': fromDateApi.toIso8601String(),
      'ToDate': toDateApi.toIso8601String(),
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    if (productId != null && productId! > 0) {
      params['ProductId'] = productId.toString();
    }
    if (batchId != null && batchId! > 0) {
      params['BatchId'] = batchId.toString();
    }
    if (transactionType != null &&
        transactionType!.trim().isNotEmpty &&
        transactionType != 'All') {
      params['TransactionType'] = transactionType!.trim();
    }
    if (type != null && type!.trim().isNotEmpty && type != 'All') {
      params['Type'] = type!.trim();
    }
    if (search != null && search!.trim().isNotEmpty) {
      params['Search'] = search!.trim();
    }

    return params;
  }
}
