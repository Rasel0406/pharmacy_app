import 'package:flutter/material.dart';

import '../providers/pharmacy_provider.dart';
import '../services/invoice_service.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key, required this.order});

  final OrderReceipt order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.check_circle, color: Color(0xFF0F5FC2)),
                    SizedBox(width: 8),
                    Text(
                      'Order Confirmed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF173E6C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Order ID: ${order.orderId}'),
                Text('Customer: ${order.customerName}'),
                Text('Phone: ${order.phone}'),
                Text('Address: ${order.deliveryAddress}'),
                Text('Payment: ${order.paymentMethod}'),
                if (order.paymentDetails.isNotEmpty)
                  Text('Payment Details: ${order.paymentDetails}'),
                if (order.couponCode.isNotEmpty)
                  Text('Coupon: ${order.couponCode}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Items',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF173E6C),
            ),
          ),
          const SizedBox(height: 8),
          ...order.items.map((line) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.medicineName),
              subtitle: Text('Qty: ${line.quantity}'),
              trailing: Text(
                '৳ ${line.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }),
          const Divider(height: 24),
          _summaryRow('Subtotal', order.subtotal),
          const SizedBox(height: 4),
          _summaryRow('Delivery', order.deliveryFee),
          if (order.discount > 0) ...<Widget>[
            const SizedBox(height: 4),
            _summaryRow('Discount', -order.discount),
          ],
          const SizedBox(height: 6),
          _summaryRow('Total', order.total, isBold: true),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              await InvoiceService.instance.shareInvoicePdf(order);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export/Share Invoice PDF'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    final TextStyle style = TextStyle(
      color: const Color(0xFF1E4470),
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
      fontSize: isBold ? 19 : 15,
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
