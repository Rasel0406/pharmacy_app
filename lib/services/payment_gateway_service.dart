import 'dart:math';

import '../models/payment_gateway.dart';

class PaymentGatewayService {
  PaymentGatewayService._();

  static final PaymentGatewayService instance = PaymentGatewayService._();

  final Map<String, int> _pollCount = <String, int>{};
  final Random _random = Random();

  Future<PaymentSession> createPaymentSession(PaymentGatewayRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final String sessionId = 'PG-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(9999)}';
    _pollCount[sessionId] = 0;

    return PaymentSession(
      sessionId: sessionId,
      status: PaymentGatewayStatus.initiated,
      raw: <String, dynamic>{
        'request': request.toJson(),
        'environment': 'sandbox',
      },
    );
  }

  Future<PaymentSession> pollStatus({
    required String sessionId,
    required PaymentGatewayRequest request,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final int count = (_pollCount[sessionId] ?? 0) + 1;
    _pollCount[sessionId] = count;

    PaymentGatewayStatus status;
    if (count == 1) {
      status = PaymentGatewayStatus.pending;
    } else if (count <= 3) {
      status = PaymentGatewayStatus.processing;
    } else {
      status = PaymentGatewayStatus.success;
    }

    return PaymentSession(
      sessionId: sessionId,
      status: status,
      raw: <String, dynamic>{
        'environment': 'sandbox',
        'poll_count': count,
        'request': request.toJson(),
      },
    );
  }
}
