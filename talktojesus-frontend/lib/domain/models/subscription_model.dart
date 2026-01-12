import 'plan_model.dart';

class Subscription {
  final String id;
  final String userId;
  final String planId;
  final String razorpaySubscriptionId;
  final String status;
  final int? currentStart;
  final int? currentEnd;
  final int? lastChargedAt;
  final int? chargeAt;
  final int? startAt;
  final int? endAt;
  final int quantity;
  final int totalCount;
  final int paidCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Plan? plan;

  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.razorpaySubscriptionId,
    required this.status,
    this.currentStart,
    this.currentEnd,
    this.lastChargedAt,
    this.chargeAt,
    this.startAt,
    this.endAt,
    required this.quantity,
    required this.totalCount,
    required this.paidCount,
    required this.createdAt,
    required this.updatedAt,
    this.plan,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      razorpaySubscriptionId: json['razorpay_subscription_id'] as String,
      status: json['status'] as String,
      currentStart: json['current_start'] as int?,
      currentEnd: json['current_end'] as int?,
      lastChargedAt: json['last_charged_at'] as int?,
      chargeAt: json['charge_at'] as int?,
      startAt: json['start_at'] as int?,
      endAt: json['end_at'] as int?,
      quantity: (json['quantity'] as num).toInt(),
      totalCount: (json['total_count'] as num).toInt(),
      paidCount: (json['paid_count'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      plan: json['plans'] != null
          ? Plan.fromJson(json['plans'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'razorpay_subscription_id': razorpaySubscriptionId,
      'status': status,
      'current_start': currentStart,
      'current_end': currentEnd,
      'last_charged_at': lastChargedAt,
      'charge_at': chargeAt,
      'start_at': startAt,
      'end_at': endAt,
      'quantity': quantity,
      'total_count': totalCount,
      'paid_count': paidCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (plan != null) 'plans': plan!.toJson(),
    };
  }

  bool get isActive => status == 'active' || status == 'authenticated';
  bool get isPastDue => status == 'past_due';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';
}

class CreateSubscriptionResponse {
  final Subscription subscription;
  final String razorpayKeyId;
  final Map<String, dynamic>? razorpaySubscription;

  CreateSubscriptionResponse({
    required this.subscription,
    required this.razorpayKeyId,
    this.razorpaySubscription,
  });

  factory CreateSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return CreateSubscriptionResponse(
      subscription: Subscription.fromJson(json),
      razorpayKeyId: json['razorpay_key_id'] as String,
      razorpaySubscription: json['razorpay_subscription'] != null
          ? json['razorpay_subscription'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...subscription.toJson(),
      'razorpay_key_id': razorpayKeyId,
      if (razorpaySubscription != null)
        'razorpay_subscription': razorpaySubscription,
    };
  }

  String? get shortUrl => razorpaySubscription?['short_url'] as String?;
}

class CurrentSubscriptionResponse {
  final Subscription? subscription;

  CurrentSubscriptionResponse({this.subscription});

  factory CurrentSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return CurrentSubscriptionResponse(
      subscription: json['subscription'] != null
          ? Subscription.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription': subscription?.toJson(),
    };
  }
}

