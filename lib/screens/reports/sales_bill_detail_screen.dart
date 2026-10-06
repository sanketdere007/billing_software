import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';

class SalesBillDetailScreen extends StatefulWidget {
  final int salesMasterId;
  final String invoiceNo;
  final String customerName;
  final double? billWiseDiscountPercentage;
  final double? billWiseDiscountAmount;
  final double? billAmount;

  const SalesBillDetailScreen({
    super.key,
    required this.salesMasterId,
    required this.invoiceNo,
    required this.customerName,
    this.billWiseDiscountPercentage,
    this.billWiseDiscountAmount,
    this.billAmount,
  });

  @override
  State<SalesBillDetailScreen> createState() => _SalesBillDetailScreenState();
}

class _SalesBillDetailScreenState extends State<SalesBillDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _details = [];
  Map<String, dynamic>? _master;
  String? _errorMessage;
  int _highlightedIndex = 0;

  final columns = [
    {
      'label': 'Product Name',
      'width': 200.0,
      'keys': [
        'productName',
        'itemName',
        'product_name',
        'item_name',
        'name',
        'salesEntryDetail_ProductName',
        'salesDetail_ProductName',
      ],
    },
    {
      'label': 'Qty',
      'width': 70.0,
      'keys': ['qty', 'quantity', 'salesEntryDetail_Qty', 'salesDetail_Qty'],
    },
    {
      'label': 'Selling Price',
      'width': 100.0,
      'keys': [
        'sellingPrice',
        'rate',
        'price',
        'selling_price',
        'salesEntryDetail_SellingPrice',
        'salesDetail_SellingPrice',
        'salesEntryDetail_Rate',
        'salesDetail_Rate',
      ],
    },
    {
      'label': 'Gross Amt',
      'width': 100.0,
      'keys': [
        'grossAmt',
        'grossAmount',
        'gross_amount',
        'amount',
        'salesEntryDetail_TaxableAmount',
        'salesDetail_TaxableAmount',
      ],
    },
    {
      'label': 'Dis%',
      'width': 70.0,
      'keys': [
        'disPer',
        'discountPercentage',
        'discount_percentage',
        'dis_per',
        'disc_per',
        'salesEntryDetail_DiscountPercentage',
        'salesDetail_DiscountPercentage',
      ],
    },
    {
      'label': 'Dis Amt',
      'width': 90.0,
      'keys': [
        'disAmt',
        'discountAmount',
        'discount_amount',
        'dis_amt',
        'disc_amt',
        'salesEntryDetail_DiscountAmount',
        'salesDetail_DiscountAmount',
      ],
    },
    {
      'label': 'GST%',
      'width': 70.0,
      'keys': [
        'gstPer',
        'gstPercentage',
        'gst_percentage',
        'tax_per',
        'taxPer',
        'salesEntryDetail_GSTPercentage',
        'salesDetail_GSTPercentage',
      ],
    },
    {
      'label': 'GST Amt',
      'width': 90.0,
      'keys': [
        'gstAmt',
        'gstAmount',
        'gst_amount',
        'tax_amount',
        'taxAmt',
        'salesEntryDetail_TotalTaxAmount',
        'salesDetail_TotalTaxAmount',
      ],
    },
    {
      'label': 'Net Amt',
      'width': 100.0,
      'keys': [
        'netAmt',
        'netAmount',
        'net_amount',
        'totalAmount',
        'total_amount',
        'salesEntryDetail_TotalAmount',
        'salesDetail_TotalAmount',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await apiService.get(
        '/api/SalesEntry/GetAllSalesDetail/${widget.salesMasterId}',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response is Map<String, dynamic> &&
              response.containsKey('data')) {
            final data = response['data'];
            if (data is Map<String, dynamic>) {
              if (data.containsKey('details') ||
                  data.containsKey('salesDetails') ||
                  data.containsKey('invoiceDetails')) {
                _details =
                    data['details'] ??
                    data['salesDetails'] ??
                    data['invoiceDetails'] ??
                    [];
                _master = data['master'] ?? data['salesMaster'] ?? data;
              } else {
                _details = [data];
              }
            } else if (data is List) {
              _details = data;
            }
          } else if (response is List) {
            _details = response;
          } else {
            _details = [response];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  double _getDouble(Map item, List<String> possibleKeys) {
    for (var key in possibleKeys) {
      for (var k in item.keys) {
        if (k.toString().toLowerCase() == key.toLowerCase()) {
          if (item[k] != null) {
            return double.tryParse(item[k].toString()) ?? 0.0;
          }
        }
      }
    }
    return 0.0;
  }

  String _getString(Map item, List<String> possibleKeys) {
    for (var key in possibleKeys) {
      for (var k in item.keys) {
        if (k.toString().toLowerCase() == key.toLowerCase()) {
          if (item[k] != null && item[k].toString().isNotEmpty) {
            return item[k].toString();
          }
        }
      }
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final titleText = '${widget.invoiceNo} - ${widget.customerName}';

    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 250, child: AppDrawer(isPermanent: true)),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(titleText),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Refresh',
                          onPressed: _isLoading ? null : _fetchDetails,
                        ),
                      ],
                    ),
                    body: _buildBody(),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(titleText),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: _isLoading ? null : _fetchDetails,
              ),
            ],
          ),
          drawer: const AppDrawer(isPermanent: false),
          body: _buildBody(),
        );
      },
    ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_details.isEmpty || (_details.length == 1 && _details[0] == null)) {
      return const Center(child: Text('No details found for this bill.'));
    }

    double totalQty = 0;
    double totalGross = 0;
    double prodDis = 0;
    double totalGst = 0;
    double payableAmount = 0;

    for (var item in _details) {
      if (item is Map) {
        totalQty += _getDouble(item, columns[1]['keys'] as List<String>);
        totalGross += _getDouble(item, columns[3]['keys'] as List<String>);
        prodDis += _getDouble(item, columns[5]['keys'] as List<String>);
        totalGst += _getDouble(item, columns[7]['keys'] as List<String>);
        payableAmount += _getDouble(item, columns[8]['keys'] as List<String>);
      }
    }

    double billDisPer = widget.billWiseDiscountPercentage ?? 0;
    double billDisAmt = widget.billWiseDiscountAmount ?? 0;
    if (_master != null) {
      final mPer = _getDouble(_master!, [
        'billDisPer',
        'billDiscountPercentage',
        'bill_dis_per',
      ]);
      final mAmt = _getDouble(_master!, [
        'billDisAmt',
        'billDiscountAmount',
        'bill_dis_amt',
      ]);
      if (mPer > 0) billDisPer = mPer;
      if (mAmt > 0) billDisAmt = mAmt;

      final mPayable = _getDouble(_master!, [
        'payableAmount',
        'netAmount',
        'grandTotal',
      ]);
      if (mPayable > 0) payableAmount = mPayable;
    }

    if (widget.billAmount != null && widget.billAmount! > 0) {
      payableAmount = widget.billAmount!;
    }

    Widget buildRow(int index, Map? item, bool isHeader) {
      return Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              isHeader ? '#' : '${index + 1}',
              style: isHeader
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
          ...columns.map((col) {
            final text = isHeader
                ? col['label'] as String
                : _getString(item!, col['keys'] as List<String>);

            final style = isHeader
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                : const TextStyle(fontSize: 14);

            if (col['label'] == 'Product Name') {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    text,
                    style: style,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }

            return Container(
              width: col['width'] as double,
              padding: const EdgeInsets.only(right: 8),
              child: Text(text, style: style, overflow: TextOverflow.ellipsis),
            );
          }),
        ],
      );
    }

    final totalWidth =
        columns.fold<double>(0, (sum, col) => sum + (col['width'] as double)) +
        100;

    final firstItem =
        _details.firstWhere((e) => e is Map, orElse: () => null) as Map?;
    final rawKeys = firstItem?.keys.join(', ') ?? 'none';

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.35),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: buildRow(0, null, true),
        ),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: _details.length,
            itemBuilder: (context, index) {
              final item = _details[index];
              if (item is! Map) return ListTile(title: Text(item.toString()));

              final isSelected = index == _highlightedIndex;

              return InkWell(
                onTap: () {
                  setState(() {
                    _highlightedIndex = index;
                  });
                },
                child: Container(
                  height: 53,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(
                            0.3,
                          )
                        : null,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: buildRow(index, item, false),
                ),
              );
            },
          ),
        ),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth > totalWidth
                      ? constraints.maxWidth
                      : totalWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: tableWidth, child: content),
                  );
                },
              ),
            ),
          ),
        ),
        _buildSummaryFooter(
          totalQty,
          totalGross,
          prodDis,
          totalGst,
          billDisPer,
          billDisAmt,
          payableAmount,
        ),
      ],
    );
  }

  Widget _buildSummaryFooter(
    double totalQty,
    double totalGross,
    double prodDis,
    double totalGst,
    double billDisPer,
    double billDisAmt,
    double payableAmount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            _summaryItem('Total Qty', totalQty.toStringAsFixed(2)),
            _summaryItem('Total Gross', totalGross.toStringAsFixed(2)),
            _summaryItem('Prod Dis', prodDis.toStringAsFixed(2)),
            _summaryItem('Total GST', totalGst.toStringAsFixed(2)),
            _summaryItem('Bill Dis%', billDisPer.toStringAsFixed(2)),
            _summaryItem('Bill Dis Amt', billDisAmt.toStringAsFixed(2)),
            _summaryItem(
              'Payable Amount',
              payableAmount.toStringAsFixed(2),
              isGrand: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, {bool isGrand = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isGrand ? 19 : 15,
            fontWeight: FontWeight.bold,
            color: isGrand ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
