import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/domain/models/plan_model.dart';

void main() {
  group('Plan', () {
    final sampleJson = {
      'id': 'plan-1',
      'name': 'Premium Monthly',
      'price': 9900, // 99 rupees in paise
      'razorpay_plan_id': 'plan_razorpay_123',
      'interval': 1,
      'period': 'monthly',
      'cycles': 12,
      'created_at': '2025-01-01T00:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final plan = Plan.fromJson(sampleJson);

      expect(plan.id, 'plan-1');
      expect(plan.name, 'Premium Monthly');
      expect(plan.price, 9900);
      expect(plan.razorpayPlanId, 'plan_razorpay_123');
      expect(plan.interval, 1);
      expect(plan.period, 'monthly');
      expect(plan.cycles, 12);
    });

    test('toJson produces correct keys', () {
      final plan = Plan.fromJson(sampleJson);
      final json = plan.toJson();

      expect(json['id'], 'plan-1');
      expect(json['name'], 'Premium Monthly');
      expect(json['price'], 9900);
      expect(json['razorpay_plan_id'], 'plan_razorpay_123');
    });

    test('fromJson/toJson round-trip preserves data', () {
      final plan = Plan.fromJson(sampleJson);
      final roundTripped = Plan.fromJson(plan.toJson());

      expect(roundTripped.id, plan.id);
      expect(roundTripped.name, plan.name);
      expect(roundTripped.price, plan.price);
      expect(roundTripped.razorpayPlanId, plan.razorpayPlanId);
    });

    test('priceInRupees converts paise to rupees', () {
      final plan = Plan.fromJson(sampleJson);
      expect(plan.priceInRupees, 99.0);
    });

    test('priceInRupees handles fractional amounts', () {
      final json = {...sampleJson, 'price': 9950};
      final plan = Plan.fromJson(json);
      expect(plan.priceInRupees, 99.5);
    });

    test('formattedPrice returns rupee symbol with amount', () {
      final plan = Plan.fromJson(sampleJson);
      expect(plan.formattedPrice, '₹99');
    });

    test('formattedPrice truncates decimals', () {
      final json = {...sampleJson, 'price': 9999};
      final plan = Plan.fromJson(json);
      // 99.99 → toStringAsFixed(0) → "100"
      expect(plan.formattedPrice, '₹100');
    });
  });
}
