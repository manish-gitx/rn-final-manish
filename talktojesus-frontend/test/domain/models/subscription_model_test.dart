import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/domain/models/subscription_model.dart';

void main() {
  group('Subscription', () {
    final now = DateTime.now();
    final sampleJson = {
      'id': 'sub-1',
      'user_id': 'user-1',
      'plan_id': 'plan-1',
      'razorpay_subscription_id': 'sub_razorpay_123',
      'status': 'active',
      'current_start': 1700000000,
      'current_end': 1702592000,
      'last_charged_at': 1700000000,
      'charge_at': 1702592000,
      'start_at': null,
      'end_at': null,
      'quantity': 1,
      'total_count': 12,
      'paid_count': 3,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromJson parses all fields correctly', () {
      final sub = Subscription.fromJson(sampleJson);

      expect(sub.id, 'sub-1');
      expect(sub.userId, 'user-1');
      expect(sub.planId, 'plan-1');
      expect(sub.razorpaySubscriptionId, 'sub_razorpay_123');
      expect(sub.status, 'active');
      expect(sub.currentStart, 1700000000);
      expect(sub.lastChargedAt, 1700000000);
      expect(sub.quantity, 1);
      expect(sub.totalCount, 12);
      expect(sub.paidCount, 3);
      expect(sub.plan, isNull);
    });

    test('fromJson parses nested plan when present', () {
      final jsonWithPlan = {
        ...sampleJson,
        'plans': {
          'id': 'plan-1',
          'name': 'Premium',
          'price': 9900,
          'razorpay_plan_id': 'rp_plan_1',
          'interval': 1,
          'period': 'monthly',
          'cycles': 12,
          'created_at': now.toIso8601String(),
        },
      };

      final sub = Subscription.fromJson(jsonWithPlan);
      expect(sub.plan, isNotNull);
      expect(sub.plan!.name, 'Premium');
      expect(sub.plan!.price, 9900);
    });

    test('toJson produces correct keys', () {
      final sub = Subscription.fromJson(sampleJson);
      final json = sub.toJson();

      expect(json['user_id'], 'user-1');
      expect(json['razorpay_subscription_id'], 'sub_razorpay_123');
      expect(json['total_count'], 12);
      expect(json.containsKey('plans'), isFalse); // no plan in original
    });

    test('toJson includes plan when present', () {
      final jsonWithPlan = {
        ...sampleJson,
        'plans': {
          'id': 'plan-1',
          'name': 'Premium',
          'price': 9900,
          'razorpay_plan_id': 'rp_plan_1',
          'interval': 1,
          'period': 'monthly',
          'cycles': 12,
          'created_at': now.toIso8601String(),
        },
      };
      final sub = Subscription.fromJson(jsonWithPlan);
      final json = sub.toJson();
      expect(json.containsKey('plans'), isTrue);
    });

    test('isActive returns true for active status', () {
      final sub = Subscription.fromJson(sampleJson);
      expect(sub.isActive, isTrue);
    });

    test('isActive returns true for authenticated status', () {
      final json = {...sampleJson, 'status': 'authenticated'};
      final sub = Subscription.fromJson(json);
      expect(sub.isActive, isTrue);
    });

    test('isActive returns false for cancelled status', () {
      final json = {...sampleJson, 'status': 'cancelled'};
      final sub = Subscription.fromJson(json);
      expect(sub.isActive, isFalse);
    });

    test('isCancelled returns true for cancelled status', () {
      final json = {...sampleJson, 'status': 'cancelled'};
      final sub = Subscription.fromJson(json);
      expect(sub.isCancelled, isTrue);
    });

    test('isPaused returns true for paused status', () {
      final json = {...sampleJson, 'status': 'paused'};
      final sub = Subscription.fromJson(json);
      expect(sub.isPaused, isTrue);
    });

    test('isPastDue returns true for past_due status', () {
      final json = {...sampleJson, 'status': 'past_due'};
      final sub = Subscription.fromJson(json);
      expect(sub.isPastDue, isTrue);
    });
  });

  group('CreateSubscriptionResponse', () {
    test('shortUrl returns value from razorpaySubscription', () {
      final now = DateTime.now();
      final json = {
        'id': 'sub-1',
        'user_id': 'user-1',
        'plan_id': 'plan-1',
        'razorpay_subscription_id': 'sub_rp_1',
        'status': 'created',
        'quantity': 1,
        'total_count': 12,
        'paid_count': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'razorpay_key_id': 'rzp_test_key',
        'razorpay_subscription': {
          'short_url': 'https://rzp.io/abc123',
        },
      };

      final response = CreateSubscriptionResponse.fromJson(json);
      expect(response.shortUrl, 'https://rzp.io/abc123');
    });

    test('shortUrl returns null when razorpaySubscription is null', () {
      final now = DateTime.now();
      final json = {
        'id': 'sub-1',
        'user_id': 'user-1',
        'plan_id': 'plan-1',
        'razorpay_subscription_id': 'sub_rp_1',
        'status': 'created',
        'quantity': 1,
        'total_count': 12,
        'paid_count': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'razorpay_key_id': 'rzp_test_key',
      };

      final response = CreateSubscriptionResponse.fromJson(json);
      expect(response.shortUrl, isNull);
    });
  });

  group('CurrentSubscriptionResponse', () {
    test('fromJson handles null subscription', () {
      final json = {'subscription': null};
      final response = CurrentSubscriptionResponse.fromJson(json);
      expect(response.subscription, isNull);
    });
  });
}
