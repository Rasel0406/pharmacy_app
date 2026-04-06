import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_provider.dart';
import '../services/invoice_service.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final OrderReceipt order;

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, _) {
        final OrderReceipt liveOrder =
            provider.getOrderById(order.orderId) ?? order;
        final String statusLabel = provider.getOrderStatusLabel(liveOrder);

        return Scaffold(
          appBar: AppBar(title: const Text('Order Details')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Order ID: ${liveOrder.orderId}'),
                    Text('Customer: ${liveOrder.customerName}'),
                    Text('Phone: ${liveOrder.phone}'),
                    Text('Address: ${liveOrder.deliveryAddress}'),
                    Text('Payment: ${liveOrder.paymentMethod}'),
                    const SizedBox(height: 6),
                    Text(
                      'Status: $statusLabel',
                      style: TextStyle(
                        color: liveOrder.isCanceled
                            ? const Color(0xFFC73B3B)
                            : const Color(0xFF0F5FC2),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (liveOrder.paymentDetails.isNotEmpty)
                      Text('Payment Details: ${liveOrder.paymentDetails}'),
                    if (liveOrder.couponCode.isNotEmpty)
                      Text('Coupon: ${liveOrder.couponCode}'),
                    if (liveOrder.note.isNotEmpty)
                      Text('Note: ${liveOrder.note}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tracking Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183E6B),
                ),
              ),
              const SizedBox(height: 8),
              _trackingStepper(provider, liveOrder),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: liveOrder.isCanceled ||
                              liveOrder.statusIndex >=
                                  PharmacyProvider.orderStatusFlow.length - 1
                          ? null
                          : () async {
                              await provider
                                  .advanceOrderStatus(liveOrder.orderId);
                            },
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Next Status'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: liveOrder.isCanceled ||
                              liveOrder.statusIndex >=
                                  PharmacyProvider.orderStatusFlow.length - 1
                          ? null
                          : () async {
                              await provider.cancelOrder(liveOrder.orderId);
                            },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Order'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Ordered Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183E6B),
                ),
              ),
              const SizedBox(height: 8),
              ...liveOrder.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.medicineName),
                  subtitle: Text(
                    'Qty: ${item.quantity} x ৳ ${item.unitPrice.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '৳ ${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Divider(height: 20),
              _summary('Subtotal', liveOrder.subtotal),
              const SizedBox(height: 4),
              _summary('Delivery', liveOrder.deliveryFee),
              if (liveOrder.discount > 0) ...<Widget>[
                const SizedBox(height: 4),
                _summary('Discount', -liveOrder.discount),
              ],
              const SizedBox(height: 6),
              _summary('Total', liveOrder.total, bold: true),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  await InvoiceService.instance.shareInvoicePdf(liveOrder);
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export/Share Invoice PDF'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  provider.reorder(liveOrder);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Reordered items added to cart')),
                  );
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Reorder Items'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _trackingStepper(PharmacyProvider provider, OrderReceipt order) {
    const List<String> flow = PharmacyProvider.orderStatusFlow;
    return Stepper(
      physics: const NeverScrollableScrollPhysics(),
      currentStep: order.isCanceled
          ? (order.statusIndex.clamp(0, flow.length - 1))
          : order.statusIndex.clamp(0, flow.length - 1),
      controlsBuilder: (_, __) => const SizedBox.shrink(),
      steps: flow
          .asMap()
          .entries
          .map(
            (entry) => Step(
              title: Text(entry.value),
              content: Text(
                entry.key <= order.statusIndex ? 'Completed' : 'Pending',
              ),
              isActive: entry.key <= order.statusIndex,
              state: entry.key < order.statusIndex
                  ? StepState.complete
                  : (entry.key == order.statusIndex
                      ? StepState.indexed
                      : StepState.disabled),
            ),
          )
          .toList(),
    );
  }

  Widget _summary(String label, double value, {bool bold = false}) {
    final TextStyle style = TextStyle(
      color: const Color(0xFF1E4470),
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: bold ? 19 : 15,
    );

    return Row(
      children: <Widget>[
        Text(label, style: style),
        const Spacer(),
        Text(
          '${value < 0 ? '-' : ''}৳ ${value.abs().toStringAsFixed(2)}',
          style: style,
        ),
      ],
    );
  }
}
