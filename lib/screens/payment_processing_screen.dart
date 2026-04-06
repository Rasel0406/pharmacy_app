import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment_gateway.dart';
import '../providers/pharmacy_provider.dart';
import '../services/payment_gateway_service.dart';
import 'order_summary_screen.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({
    super.key,
    required this.customerName,
    required this.phone,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.couponCode,
    required this.discount,
    required this.note,
    required this.amount,
  });

  final String customerName;
  final String phone;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentDetails;
  final String couponCode;
  final double discount;
  final String note;
  final double amount;

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  PaymentGatewayStatus _status = PaymentGatewayStatus.initiated;
  String _statusText = 'Initializing payment gateway...';
  int _attempt = 0;
  bool _busy = true;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    final PaymentGatewayRequest request = PaymentGatewayRequest(
      orderId: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
      paymentMethod: widget.paymentMethod,
      amount: widget.amount,
      currency: 'BDT',
      customerName: widget.customerName,
      phone: widget.phone,
      reference: widget.paymentDetails,
      metadata: <String, dynamic>{
        'coupon_code': widget.couponCode,
      },
    );

    final PaymentSession created =
        await PaymentGatewayService.instance.createPaymentSession(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _sessionId = created.sessionId;
      _status = created.status;
      _statusText = 'Session created. Waiting for confirmation...';
    });

    for (int i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) {
        return;
      }

      final PaymentSession polled =
          await PaymentGatewayService.instance.pollStatus(
        sessionId: created.sessionId,
        request: request,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _attempt = i + 1;
        _status = polled.status;
        _statusText = _statusMessage(polled.status);
      });

      if (polled.status == PaymentGatewayStatus.success) {
        final PharmacyProvider provider = context.read<PharmacyProvider>();
        final OrderReceipt order = await provider.placeOrder(
          customerName: widget.customerName,
          phone: widget.phone,
          deliveryAddress: widget.deliveryAddress,
          paymentMethod: widget.paymentMethod,
          paymentDetails: widget.paymentDetails,
          couponCode: widget.couponCode,
          discount: widget.discount,
          note: widget.note,
        );

        if (!mounted) {
          return;
        }

        if (provider.lastOrderSyncError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFC73B3B),
              content: Text(provider.lastOrderSyncError!),
            ),
          );
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OrderSummaryScreen(order: order),
          ),
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _busy = false;
      _status = PaymentGatewayStatus.failed;
      _statusText = 'Payment confirmation timeout. Please retry.';
    });
  }

  String _statusMessage(PaymentGatewayStatus status) {
    switch (status) {
      case PaymentGatewayStatus.initiated:
        return 'Initializing session...';
      case PaymentGatewayStatus.pending:
        return 'Payment pending...';
      case PaymentGatewayStatus.processing:
        return 'Gateway is processing your payment...';
      case PaymentGatewayStatus.success:
        return 'Payment successful. Finalizing order...';
      case PaymentGatewayStatus.failed:
        return 'Payment failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_attempt / 4).clamp(0.05, 1.0);
    final Color statusColor = switch (_status) {
      PaymentGatewayStatus.success => const Color(0xFF1B8E4A),
      PaymentGatewayStatus.failed => const Color(0xFFC73B3B),
      PaymentGatewayStatus.pending => const Color(0xFFE09B11),
      PaymentGatewayStatus.processing => const Color(0xFF0F5FC2),
      PaymentGatewayStatus.initiated => const Color(0xFF6C89AB),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 76,
                width: 76,
                child: CircularProgressIndicator(
                  value: _busy ? null : 0,
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A426F),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              if (_sessionId != null)
                Text(
                  'Session: $_sessionId',
                  style:
                      const TextStyle(color: Color(0xFF55749E), fontSize: 12),
                ),
              if (!_busy) ...<Widget>[
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _attempt = 0;
                      _busy = true;
                      _status = PaymentGatewayStatus.initiated;
                      _statusText = 'Retrying payment...';
                    });
                    _processPayment();
                  },
                  child: const Text('Retry Payment'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
