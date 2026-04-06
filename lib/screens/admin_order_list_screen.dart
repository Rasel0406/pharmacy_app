import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';

  static const List<String> _statusFlow = <String>[
    'Confirmed',
    'Packed',
    'Picked Up',
    'On The Way',
    'Delivered',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        title: const Text('Admin Orders'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search order ID, customer, phone',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE8F9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE8F9)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE8F9)),
                  ),
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    underline: const SizedBox.shrink(),
                    items: const <String>[
                      'All',
                      'Confirmed',
                      'Packed',
                      'Picked Up',
                      'On The Way',
                      'Delivered',
                      'Canceled',
                    ]
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _statusFilter = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('created_at_server', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _errorView(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<_AdminOrder> orders =
                    snapshot.data?.docs.map(_AdminOrder.fromDoc).toList() ??
                        <_AdminOrder>[];

                final String query =
                    _searchController.text.trim().toLowerCase();
                final List<_AdminOrder> filtered = orders.where((order) {
                  final bool matchesQuery = query.isEmpty ||
                      order.orderId.toLowerCase().contains(query) ||
                      order.customerName.toLowerCase().contains(query) ||
                      order.phone.toLowerCase().contains(query);

                  final bool matchesStatus = _statusFilter == 'All' ||
                      order.statusLabel == _statusFilter;

                  return matchesQuery && matchesStatus;
                }).toList();

                return Column(
                  children: <Widget>[
                    _summaryCards(filtered),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No orders found for this filter.',
                                style: TextStyle(
                                  color: Color(0xFF4C688A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemBuilder: (context, index) {
                                final _AdminOrder order = filtered[index];
                                return _orderCard(order);
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemCount: filtered.length,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCards(List<_AdminOrder> orders) {
    final int total = orders.length;
    final int delivered =
        orders.where((o) => o.statusLabel == 'Delivered').length;
    final int pending = orders
        .where(
            (o) => o.statusLabel != 'Delivered' && o.statusLabel != 'Canceled')
        .length;
    final int canceled =
        orders.where((o) => o.statusLabel == 'Canceled').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(
              child: _metricCard(
                  'Total', total.toString(), const Color(0xFF0F5FC2))),
          const SizedBox(width: 8),
          Expanded(
              child: _metricCard(
                  'Pending', pending.toString(), const Color(0xFFE09B11))),
          const SizedBox(width: 8),
          Expanded(
              child: _metricCard(
                  'Done', delivered.toString(), const Color(0xFF1B8E4A))),
          const SizedBox(width: 8),
          Expanded(
              child: _metricCard(
                  'Cancel', canceled.toString(), const Color(0xFFC73B3B))),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE8F9)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4C688A),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(_AdminOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8F9)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          order.orderId,
          style: const TextStyle(
            color: Color(0xFF163D6A),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 2),
            Text(
              '${order.customerName} • ${order.phone}',
              style: const TextStyle(color: Color(0xFF4C688A)),
            ),
            const SizedBox(height: 2),
            Text(
              '৳ ${order.total.toStringAsFixed(2)} • ${order.paymentMethod}',
              style: const TextStyle(
                color: Color(0xFF0F5FC2),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        trailing: _statusChip(order.statusLabel),
        children: <Widget>[
          _detailRow('Created', order.createdAtLabel),
          _detailRow('Address', order.deliveryAddress),
          if (order.note.isNotEmpty) _detailRow('Note', order.note),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Items',
              style: TextStyle(
                color: Color(0xFF173E6C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: const TextStyle(color: Color(0xFF31527C)),
                    ),
                  ),
                  Text(
                    '৳ ${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF31527C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      order.isCanceled || order.statusLabel == 'Delivered'
                          ? null
                          : () => _advanceStatus(order),
                  icon: const Icon(Icons.forward_rounded, size: 17),
                  label: const Text('Next Status'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC73B3B),
                  ),
                  onPressed:
                      order.isCanceled || order.statusLabel == 'Delivered'
                          ? null
                          : () => _cancelOrder(order),
                  icon: const Icon(Icons.cancel_outlined, size: 17),
                  label: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Delivered':
        bg = const Color(0x1A1B8E4A);
        fg = const Color(0xFF1B8E4A);
        break;
      case 'Canceled':
        bg = const Color(0x1AC73B3B);
        fg = const Color(0xFFC73B3B);
        break;
      case 'Packed':
      case 'Picked Up':
      case 'On The Way':
        bg = const Color(0x1AE09B11);
        fg = const Color(0xFFE09B11);
        break;
      default:
        bg = const Color(0x1A0F5FC2);
        fg = const Color(0xFF0F5FC2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF5A7698),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF31527C)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _advanceStatus(_AdminOrder order) async {
    final int nextIndex =
        (order.statusIndex + 1).clamp(0, _statusFlow.length - 1);
    final String nextLabel = _statusFlow[nextIndex];

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(order.docId)
        .update(
      <String, dynamic>{
        'status_index': nextIndex,
        'status_label': nextLabel,
        'is_canceled': false,
        'updated_at_server': FieldValue.serverTimestamp(),
      },
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order status updated to $nextLabel')),
    );
  }

  Future<void> _cancelOrder(_AdminOrder order) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(order.docId)
        .update(
      <String, dynamic>{
        'is_canceled': true,
        'status_label': 'Canceled',
        'updated_at_server': FieldValue.serverTimestamp(),
      },
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order canceled')),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Order stream error:\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC73B3B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AdminOrder {
  const _AdminOrder({
    required this.docId,
    required this.orderId,
    required this.customerName,
    required this.phone,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.total,
    required this.note,
    required this.items,
    required this.statusIndex,
    required this.statusLabel,
    required this.isCanceled,
    required this.createdAtLabel,
  });

  final String docId;
  final String orderId;
  final String customerName;
  final String phone;
  final String deliveryAddress;
  final String paymentMethod;
  final double total;
  final String note;
  final List<_AdminOrderItem> items;
  final int statusIndex;
  final String statusLabel;
  final bool isCanceled;
  final String createdAtLabel;

  factory _AdminOrder.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    final List<dynamic> rawItems =
        data['items'] as List<dynamic>? ?? <dynamic>[];

    final Timestamp? createdServer = data['created_at_server'] as Timestamp?;
    final String? createdRaw = data['created_at'] as String?;
    DateTime? created = createdServer?.toDate();
    if (created == null && createdRaw != null && createdRaw.isNotEmpty) {
      created = DateTime.tryParse(createdRaw);
    }

    final int statusIndex = (data['status_index'] as num?)?.toInt() ?? 0;
    final bool isCanceled = (data['is_canceled'] as bool?) ?? false;

    String label = (data['status_label'] as String?)?.trim() ?? '';
    if (label.isEmpty) {
      if (isCanceled) {
        label = 'Canceled';
      } else {
        const List<String> flow = <String>[
          'Confirmed',
          'Packed',
          'Picked Up',
          'On The Way',
          'Delivered',
        ];
        label = flow[statusIndex.clamp(0, flow.length - 1)];
      }
    }

    return _AdminOrder(
      docId: doc.id,
      orderId: (data['order_id'] as String?) ?? doc.id,
      customerName: (data['customer_name'] as String?) ?? 'Unknown',
      phone: (data['phone'] as String?) ?? '-',
      deliveryAddress: (data['delivery_address'] as String?) ?? '-',
      paymentMethod: (data['payment_method'] as String?) ?? '-',
      total: (data['total'] as num?)?.toDouble() ?? 0,
      note: (data['note'] as String?) ?? '',
      items: rawItems
          .map(
            (item) => _AdminOrderItem.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      statusIndex: statusIndex,
      statusLabel: label,
      isCanceled: isCanceled,
      createdAtLabel: _formatDateTime(created),
    );
  }

  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }

    final String d = dateTime.day.toString().padLeft(2, '0');
    final String m = dateTime.month.toString().padLeft(2, '0');
    final String y = dateTime.year.toString();
    final String h = dateTime.hour.toString().padLeft(2, '0');
    final String min = dateTime.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}

class _AdminOrderItem {
  const _AdminOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  factory _AdminOrderItem.fromMap(Map<String, dynamic> map) {
    return _AdminOrderItem(
      name: (map['medicine_name'] as String?) ?? 'Medicine',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
    );
  }
}
