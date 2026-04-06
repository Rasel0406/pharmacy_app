enum PaymentGatewayStatus {
  initiated,
  pending,
  processing,
  success,
  failed,
}

class PaymentGatewayRequest {
  const PaymentGatewayRequest({
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.customerName,
    required this.phone,
    required this.reference,
    required this.metadata,
  });

  final String orderId;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String customerName;
  final String phone;
  final String reference;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'order_id': orderId,
      'payment_method': paymentMethod,
      'amount': amount,
      'currency': currency,
      'customer_name': customerName,
      'phone': phone,
      'reference': reference,
      'metadata': metadata,
    };
  }
}

class PaymentSession {
  const PaymentSession({
    required this.sessionId,
    required this.status,
    required this.raw,
  });

  final String sessionId;
  final PaymentGatewayStatus status;
  final Map<String, dynamic> raw;
}
