class PaymentOrder {
  final String id;
  final String userId;
  final String planId;
  final String razorpayOrderId;
  final String? razorpayPaymentId;
  final int amount; // Amount in paise
  final String status;
  final String razorpayKeyId; // Razorpay key ID from backend
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentOrder({
    required this.id,
    required this.userId,
    required this.planId,
    required this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.amount,
    required this.status,
    required this.razorpayKeyId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String,
      razorpayKeyId: json['razorpay_key_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'amount': amount,
      'status': status,
      'razorpay_key_id': razorpayKeyId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert amount from paise to rupees
  double get amountInRupees => amount / 100;

  String get formattedAmount => '₹${amountInRupees.toStringAsFixed(0)}';
}
