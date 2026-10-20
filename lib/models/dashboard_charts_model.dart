/// Models for `/api/Dashboard/GetCharts`
/// Response contains daily sales trend, payment collections,
/// monthly sales vs purchase, and top selling products.

class DailySalesTrendItem {
  final DateTime? salesDate;
  final String dayName;
  final int totalBills;
  final double salesAmount;

  DailySalesTrendItem({
    this.salesDate,
    required this.dayName,
    required this.totalBills,
    required this.salesAmount,
  });

  factory DailySalesTrendItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['salesDate'] ?? json['SalesDate'];
    if (rawDate != null) {
      try {
        parsedDate = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    final rawDay = json['dayName'] ?? json['DayName'] ?? '';
    final rawBills = json['totalBills'] ?? json['TotalBills'];
    final rawSales = json['salesAmount'] ?? json['SalesAmount'];

    return DailySalesTrendItem(
      salesDate: parsedDate,
      dayName: rawDay.toString(),
      totalBills: rawBills != null ? int.tryParse(rawBills.toString()) ?? 0 : 0,
      salesAmount:
          rawSales != null ? double.tryParse(rawSales.toString()) ?? 0.0 : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salesDate': salesDate?.toIso8601String(),
      'dayName': dayName,
      'totalBills': totalBills,
      'salesAmount': salesAmount,
    };
  }
}

class PaymentCollectionItem {
  final String collectionType;
  final double amount;
  final double percentage;

  PaymentCollectionItem({
    required this.collectionType,
    required this.amount,
    required this.percentage,
  });

  factory PaymentCollectionItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['collectionType'] ?? json['CollectionType'] ?? '';
    final rawAmount = json['amount'] ?? json['Amount'];
    final rawPercentage = json['percentage'] ?? json['Percentage'];

    return PaymentCollectionItem(
      collectionType: rawType.toString(),
      amount:
          rawAmount != null ? double.tryParse(rawAmount.toString()) ?? 0.0 : 0.0,
      percentage: rawPercentage != null
          ? double.tryParse(rawPercentage.toString()) ?? 0.0
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collectionType': collectionType,
      'amount': amount,
      'percentage': percentage,
    };
  }
}

class MonthlySalesVsPurchaseItem {
  final DateTime? monthStart;
  final String monthName;
  final int year;
  final double salesAmount;
  final double purchaseAmount;

  MonthlySalesVsPurchaseItem({
    this.monthStart,
    required this.monthName,
    required this.year,
    required this.salesAmount,
    required this.purchaseAmount,
  });

  factory MonthlySalesVsPurchaseItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedMonthStart;
    final rawStart = json['monthStart'] ?? json['MonthStart'];
    if (rawStart != null) {
      try {
        parsedMonthStart = DateTime.parse(rawStart.toString());
      } catch (_) {}
    }

    final rawMonth = json['monthName'] ?? json['MonthName'] ?? '';
    final rawYear = json['year'] ?? json['Year'];
    final rawSales = json['salesAmount'] ?? json['SalesAmount'];
    final rawPurchase = json['purchaseAmount'] ?? json['PurchaseAmount'];

    return MonthlySalesVsPurchaseItem(
      monthStart: parsedMonthStart,
      monthName: rawMonth.toString(),
      year: rawYear != null ? int.tryParse(rawYear.toString()) ?? 0 : 0,
      salesAmount:
          rawSales != null ? double.tryParse(rawSales.toString()) ?? 0.0 : 0.0,
      purchaseAmount: rawPurchase != null
          ? double.tryParse(rawPurchase.toString()) ?? 0.0
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthStart': monthStart?.toIso8601String(),
      'monthName': monthName,
      'year': year,
      'salesAmount': salesAmount,
      'purchaseAmount': purchaseAmount,
    };
  }
}

class TopSellingProductItem {
  final int productId;
  final String productName;
  final double totalQty;
  final double totalAmount;
  final int totalBills;

  TopSellingProductItem({
    required this.productId,
    required this.productName,
    required this.totalQty,
    required this.totalAmount,
    required this.totalBills,
  });

  factory TopSellingProductItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['productId'] ?? json['ProductId'] ?? json['id'];
    final rawName = json['productName'] ?? json['ProductName'] ?? '';
    final rawQty = json['totalQty'] ?? json['TotalQty'];
    final rawAmount = json['totalAmount'] ?? json['TotalAmount'];
    final rawBills = json['totalBills'] ?? json['TotalBills'];

    return TopSellingProductItem(
      productId: rawId != null ? int.tryParse(rawId.toString()) ?? 0 : 0,
      productName: rawName.toString(),
      totalQty:
          rawQty != null ? double.tryParse(rawQty.toString()) ?? 0.0 : 0.0,
      totalAmount: rawAmount != null
          ? double.tryParse(rawAmount.toString()) ?? 0.0
          : 0.0,
      totalBills: rawBills != null ? int.tryParse(rawBills.toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'totalQty': totalQty,
      'totalAmount': totalAmount,
      'totalBills': totalBills,
    };
  }
}

class DashboardChartsData {
  final List<DailySalesTrendItem> dailySalesTrend;
  final List<PaymentCollectionItem> paymentCollection;
  final List<MonthlySalesVsPurchaseItem> monthlySalesVsPurchase;
  final List<TopSellingProductItem> topSellingProducts;

  DashboardChartsData({
    this.dailySalesTrend = const [],
    this.paymentCollection = const [],
    this.monthlySalesVsPurchase = const [],
    this.topSellingProducts = const [],
  });

  factory DashboardChartsData.fromJson(Map<String, dynamic> json) {
    List<DailySalesTrendItem> parseDailySalesTrend(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => DailySalesTrendItem.fromJson(e))
            .toList();
      }
      return [];
    }

    List<PaymentCollectionItem> parsePaymentCollection(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => PaymentCollectionItem.fromJson(e))
            .toList();
      }
      return [];
    }

    List<MonthlySalesVsPurchaseItem> parseMonthlySalesVsPurchase(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => MonthlySalesVsPurchaseItem.fromJson(e))
            .toList();
      }
      return [];
    }

    List<TopSellingProductItem> parseTopSellingProducts(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => TopSellingProductItem.fromJson(e))
            .toList();
      }
      return [];
    }

    return DashboardChartsData(
      dailySalesTrend: parseDailySalesTrend(
        json['dailySalesTrend'] ?? json['DailySalesTrend'],
      ),
      paymentCollection: parsePaymentCollection(
        json['paymentCollection'] ?? json['PaymentCollection'],
      ),
      monthlySalesVsPurchase: parseMonthlySalesVsPurchase(
        json['monthlySalesVsPurchase'] ?? json['MonthlySalesVsPurchase'],
      ),
      topSellingProducts: parseTopSellingProducts(
        json['topSellingProducts'] ?? json['TopSellingProducts'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailySalesTrend': dailySalesTrend.map((e) => e.toJson()).toList(),
      'paymentCollection': paymentCollection.map((e) => e.toJson()).toList(),
      'monthlySalesVsPurchase':
          monthlySalesVsPurchase.map((e) => e.toJson()).toList(),
      'topSellingProducts': topSellingProducts.map((e) => e.toJson()).toList(),
    };
  }
}

class DashboardChartsResponse {
  final bool status;
  final String message;
  final DashboardChartsData? data;
  final String? error;

  DashboardChartsResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory DashboardChartsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardChartsResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? DashboardChartsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
      'error': error,
    };
  }
}
