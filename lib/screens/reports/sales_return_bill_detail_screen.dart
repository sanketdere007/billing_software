import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/api_constants.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/direct_back_scope.dart';

class SalesReturnBillDetailScreen extends StatefulWidget {
  final int returnId;
  final String billNo;
  final String customerName;
  final double? billAmount;
  final double? paidAmount;
  final double? balanceAmount;

  const SalesReturnBillDetailScreen({
    super.key,
    required this.returnId,
    required this.billNo,
    required this.customerName,
    this.billAmount,
    this.paidAmount,
    this.balanceAmount,
  });

  @override
  State<SalesReturnBillDetailScreen> createState() =>
      _SalesReturnBillDetailScreenState();
}

class _SalesReturnBillDetailScreenState
    extends State<SalesReturnBillDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _details = [];
  Map<String, dynamic>? _master;
  String? _errorMessage;

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
        'salesReturnDetail_ProductName',
        'product_Title',
      ],
    },
    {
      'label': 'Qty',
      'width': 70.0,
      'keys': [
        'qty',
        'quantity',
        'salesReturnDetail_Qty',
        'returnQty',
      ],
    },
    {
      'label': 'Rate/Price',
      'width': 100.0,
      'keys': [
        'sellingPrice',
        'rate',
        'price',
        'selling_price',
        'salesReturnDetail_SellingPrice',
        'salesReturnDetail_Rate',
        'salesReturnDetail_MRP',
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
        'subTotal',
        'salesReturnDetail_SubTotal',
        'salesReturnDetail_TaxableAmount',
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
        'salesReturnDetail_DiscountPercentage',
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
        'salesReturnDetail_DiscountAmount',
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
        'taxPercentage',
        'salesReturnDetail_TaxPercentage',
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
        'taxAmount',
        'salesReturnDetail_TaxAmount',
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
        'salesReturnDetail_TotalAmount',
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
      final endpoint =
          '${ApiConstants.getSalesReturnDetailListEndpoint}/${widget.returnId}';
      final response = await apiService.get(endpoint, requiresAuth: true);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response is Map<String, dynamic> &&
              response.containsKey('data')) {
            final data = response['data'];
            if (data is Map<String, dynamic>) {
              if (data.containsKey('details') ||
                  data.containsKey('salesReturnDetails') ||
                  data.containsKey('returnDetails')) {
                _details = data['details'] ??
                    data['salesReturnDetails'] ??
                    data['returnDetails'] ??
                    [];
                _master = data['master'] ?? data['salesReturnMaster'] ?? data;
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
    final titleText = '${widget.billNo} - ${widget.customerName}';

    return DirectBackScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            return Scaffold(
              body: Row(
                children: [
                  const SizedBox(
                    width: 250,
                    child: AppDrawer(isPermanent: true),
                  ),
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
              'Failed to load sales return details',
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No itemized details found for this sales return.'),
            if (widget.billAmount != null) ...[
              const SizedBox(height: 8),
              Text(
                'Total Return Amount: ₹${widget.billAmount!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      );
    }

    double totalQty = 0;
    double totalGross = 0;
    double prodDis = 0;
    double totalGst = 0;
    double payableAmount = 0;

    for (var item in _details) {
      final map = item is Map
          ? item
          : (item is Map<String, dynamic> ? item : null);
      if (map != null) {
        totalQty += _getDouble(map, columns[1]['keys'] as List<String>);
        totalGross += _getDouble(map, columns[3]['keys'] as List<String>);
        prodDis += _getDouble(map, columns[5]['keys'] as List<String>);
        totalGst += _getDouble(map, columns[7]['keys'] as List<String>);
        payableAmount += _getDouble(map, columns[8]['keys'] as List<String>);
      }
    }

    final double effectivePayable = widget.billAmount ?? payableAmount;

    return Column(
      children: [
        // Top summary cards
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryPill('Bill No', widget.billNo),
              _buildSummaryPill('Customer', widget.customerName),
              if (widget.billAmount != null)
                _buildSummaryPill(
                  'Bill Amt',
                  '₹${widget.billAmount!.toStringAsFixed(2)}',
                  color: Colors.blue,
                ),
              if (widget.paidAmount != null)
                _buildSummaryPill(
                  'Paid Amt',
                  '₹${widget.paidAmount!.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              if (widget.balanceAmount != null)
                _buildSummaryPill(
                  'Bal Amt',
                  '₹${widget.balanceAmount!.toStringAsFixed(2)}',
                  color: Colors.red,
                ),
            ],
          ),
        ),

        // Product Details Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 950),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.5),
                  ),
                  columns: [
                    const DataColumn(
                      label: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...columns.map(
                      (c) => DataColumn(
                        label: Text(
                          c['label'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: c['label'] != 'Product Name',
                      ),
                    ),
                  ],
                  rows: _details.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dynamic rawItem = entry.value;
                    final Map map = rawItem is Map
                        ? rawItem
                        : (rawItem is Map<String, dynamic> ? rawItem : {});

                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(
                          SizedBox(
                            width: columns[0]['width'] as double,
                            child: Text(
                              _getString(
                                map,
                                columns[0]['keys'] as List<String>,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[1]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[2]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[3]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[4]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[5]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[6]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[7]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _getDouble(
                              map,
                              columns[8]['keys'] as List<String>,
                            ).toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        // Sticky Bottom Summary Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Items: ${_details.length}   |   Total Qty: ${totalQty.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (totalGst > 0) ...[
                    Text(
                      'GST: ₹${totalGst.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 24),
                  ],
                  Text(
                    'Net Return Total: ₹${effectivePayable.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPill(String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
