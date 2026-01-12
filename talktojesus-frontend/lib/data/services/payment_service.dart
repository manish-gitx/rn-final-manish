import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../domain/models/plan_model.dart';
import '../../domain/models/user_model.dart';
import 'api_client.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Razorpay? _razorpay;
  final ApiClient _apiClient = ApiClient();

  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;

  void initialize({
    Function(PaymentSuccessResponse)? onPaymentSuccess,
    Function(PaymentFailureResponse)? onPaymentFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _onPaymentSuccess = onPaymentSuccess;
    _onPaymentFailure = onPaymentFailure;
    _onExternalWallet = onExternalWallet;

    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('[PaymentService] Payment success: ${response.paymentId}');
    _onPaymentSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[PaymentService] Payment error: ${response.message}');
    _onPaymentFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PaymentService] External wallet: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  /// Create subscription and open Razorpay subscription checkout
  Future<void> createSubscription(Plan plan, UserModel user) async {
    try {
      debugPrint(
        '[PaymentService] Creating subscription for plan: ${plan.name}',
      );

      // Create subscription via API
      final subscriptionResponse = await _apiClient.createSubscription(plan.id);

      if (!subscriptionResponse.isSuccess ||
          subscriptionResponse.data == null) {
        throw Exception(
          subscriptionResponse.error ?? 'Failed to create subscription',
        );
      }

      final createSubscriptionResponse = subscriptionResponse.data!;
      final subscription = createSubscriptionResponse.subscription;
      final razorpayKeyId = createSubscriptionResponse.razorpayKeyId;

      debugPrint(
        '[PaymentService] Subscription created: ${subscription.razorpaySubscriptionId}',
      );

      // Prepare Razorpay options for subscription
      final options = {
        'key': razorpayKeyId,
        'subscription_id': subscription.razorpaySubscriptionId,
        'name': 'Talk to Jesus',
        'description': plan.name,
        'prefill': {'contact': '', 'email': user.email},
      };

      // Open Razorpay subscription checkout
      _razorpay?.open(options);
    } catch (e, stackTrace) {
      debugPrint('[PaymentService] Error in createSubscription: $e');
      debugPrint('[PaymentService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
