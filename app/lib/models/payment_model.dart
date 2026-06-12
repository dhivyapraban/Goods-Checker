/// Payment model for Razorpay integration
class PaymentModel {
  final String id;
  final String orderId;
  final String? paymentId;
  final String? signature;
  final double amount;
  final String currency;
  final String status; // PENDING, SUCCESS, FAILED
  final String type; // INITIAL, FINAL
  final String? shipmentId;
  final String? deliveryId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  PaymentModel({
    required this.id,
    required this.orderId,
    this.paymentId,
    this.signature,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    required this.type,
    this.shipmentId,
    this.deliveryId,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      paymentId: json['paymentId'],
      signature: json['signature'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? 'PENDING',
      type: json['type'] ?? 'INITIAL',
      shipmentId: json['shipmentId'],
      deliveryId: json['deliveryId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'paymentId': paymentId,
      'signature': signature,
      'amount': amount,
      'currency': currency,
      'status': status,
      'type': type,
      'shipmentId': shipmentId,
      'deliveryId': deliveryId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  // Status helpers
  bool get isPending => status == 'PENDING';
  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';

  // Amount in paise (for Razorpay)
  int get amountInPaise => (amount * 100).round();

  // Formatted amount
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
}

/// Razorpay order response
class RazorpayOrderModel {
  final String orderId;
  final double amount;
  final String currency;
  final String? receipt;
  final String status;

  RazorpayOrderModel({
    required this.orderId,
    required this.amount,
    this.currency = 'INR',
    this.receipt,
    required this.status,
  });

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderModel(
      orderId: json['id'] ?? json['orderId'] ?? '',
      amount: ((json['amount'] ?? 0) / 100)
          .toDouble(), // Convert paise to rupees
      currency: json['currency'] ?? 'INR',
      receipt: json['receipt'],
      status: json['status'] ?? 'created',
    );
  }
}
