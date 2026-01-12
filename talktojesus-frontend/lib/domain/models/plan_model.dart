class Plan {
  final String id;
  final String name;
  final int price; // Price in paise (Indian currency)
  final String razorpayPlanId;
  final int interval;
  final String period; // "daily", "weekly", "monthly", or "yearly"
  final int cycles;
  final DateTime createdAt;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.razorpayPlanId,
    required this.interval,
    required this.period,
    required this.cycles,
    required this.createdAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      razorpayPlanId: json['razorpay_plan_id'] as String,
      interval: (json['interval'] as num).toInt(),
      period: json['period'] as String,
      cycles: (json['cycles'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'razorpay_plan_id': razorpayPlanId,
      'interval': interval,
      'period': period,
      'cycles': cycles,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Convert price from paise to rupees
  double get priceInRupees => price / 100;

  String get formattedPrice => '₹${priceInRupees.toStringAsFixed(0)}';
}
