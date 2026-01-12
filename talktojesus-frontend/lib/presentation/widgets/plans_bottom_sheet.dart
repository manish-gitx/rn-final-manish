import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/constants/text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/api_client.dart';
import '../../domain/models/plan_model.dart';
import 'package:google_fonts/google_fonts.dart';

class PlansBottomSheet extends ConsumerStatefulWidget {
  const PlansBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PlansBottomSheet(),
    );
  }

  @override
  ConsumerState<PlansBottomSheet> createState() => _PlansBottomSheetState();
}

class _PlansBottomSheetState extends ConsumerState<PlansBottomSheet> {
  final ApiClient _apiClient = ApiClient();
  final PaymentService _paymentService = PaymentService();
  List<Plan> _plans = [];
  bool _isLoading = true;
  String? _error;
  String? _processingPlanId; // Track which plan is being processed

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
    _loadPlans();
  }

  void _initializePaymentService() {
    _paymentService.initialize(
      onPaymentSuccess: (response) => _handlePaymentSuccess(response),
      onPaymentFailure: (response) => _handlePaymentFailure(response),
      onExternalWallet: (response) => _handleExternalWallet(response),
    );
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.getPlans();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _plans = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load plans';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('[PlansBottomSheet] Payment successful: ${response.paymentId}');

    setState(() {
      _processingPlanId = null;
    });

    // Refresh user data to get updated subscription
    await ref.read(authProvider.notifier).refreshAuthStatus();

    if (mounted) {
      CustomToast.show(
        context,
        message: 'Payment successful! Your subscription is now active.',
        type: ToastType.success,
      );
      Navigator.pop(context);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    debugPrint(
      '[PlansBottomSheet] Payment failed: ${response.message ?? "Unknown error"}',
    );
    setState(() {
      _processingPlanId = null;
    });

    if (mounted) {
      CustomToast.show(
        context,
        message: 'Payment failed: ${response.message ?? "Please try again"}',
        type: ToastType.error,
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PlansBottomSheet] External wallet: ${response.walletName}');
    // Handle external wallet selection if needed
  }

  Future<void> _purchasePlan(Plan plan) async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      CustomToast.show(
        context,
        message: 'Please login to subscribe',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _processingPlanId = plan.id; // Track which plan is being processed
    });

    try {
      await _paymentService.createSubscription(plan, user);
      // Payment will be handled via callbacks
    } catch (e) {
      setState(() {
        _processingPlanId = null;
      });
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF383433),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Subscribe to Talk to Jesus',
            textAlign: TextAlign.center,
            style: AppTextStyles.bottomSheetTitle,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  ShimmerBox(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 12,
                    baseColor: const Color(0xFF4A4443),
                    highlightColor: const Color(0xFF5A5453),
                  ),
                  const SizedBox(height: 12),
                  ShimmerBox(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 12,
                    baseColor: const Color(0xFF4A4443),
                    highlightColor: const Color(0xFF5A5453),
                  ),
                  const SizedBox(height: 12),
                  ShimmerBox(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 12,
                    baseColor: const Color(0xFF4A4443),
                    highlightColor: const Color(0xFF5A5453),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPlans,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_plans.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No plans available',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  final isProcessing = _processingPlanId == plan.id;
                  return _PlanItem(
                    plan: plan,
                    onTap: _processingPlanId != null
                        ? null
                        : () => _purchasePlan(plan),
                    isProcessing: isProcessing,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  final bool isProcessing;

  const _PlanItem({required this.plan, this.onTap, this.isProcessing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4443),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${(plan.price / 100).toStringAsFixed(0)}/${plan.period}',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (plan.cycles > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${plan.cycles} ${plan.period} cycles',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.formattedPrice,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isProcessing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
