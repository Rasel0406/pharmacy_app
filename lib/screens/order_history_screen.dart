import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_provider.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _paymentFilter = 'All';
  String _sortBy = 'Newest';
  String _dateFilter = 'All Time';
  DateTimeRange? _customDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, _) {
        final Set<String> methods =
            provider.orders.map((o) => o.paymentMethod).toSet();
        final List<String> methodOptions = <String>[
          'All',
          ...methods.toList()..sort()
        ];

        final List<OrderReceipt> orders = provider.filterOrders(
          query: _searchController.text,
          paymentMethod: _paymentFilter,
          sortBy: _sortBy,
          dateFilter: _dateFilter,
          customFrom: _customDateRange?.start,
          customTo: _customDateRange?.end,
        );

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by order ID, customer, or medicine',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE8F9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE8F9)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _paymentFilter,
                      decoration: const InputDecoration(
                        labelText: 'Payment',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: methodOptions
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _paymentFilter = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const <String>['Newest', 'Oldest', 'Highest Total']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _sortBy = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _dateFilter,
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const <String>[
                        'All Time',
                        'Today',
                        'Last 7 Days',
                        'Last 30 Days',
                        'Custom',
                      ]
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) {
                          return;
                        }

                        if (value == 'Custom') {
                          final DateTimeRange? picked =
                              await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: _customDateRange,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          setState(() {
                            _dateFilter = value;
                            _customDateRange = picked;
                          });
                          return;
                        }

                        setState(() {
                          _dateFilter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_dateFilter == 'Custom')
                    Expanded(
                      child: Text(
                        _customDateRange == null
                            ? 'No custom range selected'
                            : '${_customDateRange!.start.day}/${_customDateRange!.start.month}/${_customDateRange!.start.year} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}/${_customDateRange!.end.year}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B6D99),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders found for current filters.',
                        style: TextStyle(
                          color: Color(0xFF49678E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final OrderReceipt order = orders[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    OrderDetailsScreen(order: order),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFDDE8F9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        order.orderId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF163D6B),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '৳ ${order.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F5FC2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.items.length} items • ${order.paymentMethod}',
                                  style:
                                      const TextStyle(color: Color(0xFF4B6D99)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${provider.getOrderStatusLabel(order)}',
                                  style: TextStyle(
                                    color: order.isCanceled
                                        ? const Color(0xFFC73B3B)
                                        : const Color(0xFF0F5FC2),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        order.customerName,
                                        style: const TextStyle(
                                          color: Color(0xFF31527C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        provider.reorder(order);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Order items cart-এ যোগ হয়েছে'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.replay_rounded,
                                          size: 16),
                                      label: const Text('Reorder'),
                                    ),
                                    TextButton.icon(
                                      onPressed: order.isCanceled ||
                                              order.statusIndex >=
                                                  PharmacyProvider
                                                          .orderStatusFlow
                                                          .length -
                                                      1
                                          ? null
                                          : () => provider
                                              .cancelOrder(order.orderId),
                                      icon: const Icon(Icons.cancel_outlined,
                                          size: 16),
                                      label: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
