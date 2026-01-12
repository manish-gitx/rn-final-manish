import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/custom_toast.dart';
import '../../data/services/api_client.dart';
import '../../domain/models/subscription_model.dart';
import '../../core/providers/auth_provider.dart';
import 'plans_bottom_sheet.dart';

class SubscriptionBadge extends ConsumerStatefulWidget {
  const SubscriptionBadge({super.key});

  @override
  ConsumerState<SubscriptionBadge> createState() => _SubscriptionBadgeState();
}

class _SubscriptionBadgeState extends ConsumerState<SubscriptionBadge> {
  final ApiClient _apiClient = ApiClient();
  Subscription? _subscription;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    // Check if user is authenticated before loading subscription
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      setState(() {
        _subscription = null;
        _isLoadingSubscription = false;
      });
      return;
    }

    // Don't load subscription for tester accounts
    if (authState.user!.isTester) {
      setState(() {
        _subscription = null;
        _isLoadingSubscription = false;
      });
      return;
    }

    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final response = await _apiClient.getCurrentSubscription();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _subscription = response.data!.subscription;
          _isLoadingSubscription = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _subscription = null;
            _isLoadingSubscription = false;
          });

          // Don't show error toast for 401 (unauthorized) - user just isn't logged in
          if (response.statusCode != 401 &&
              response.error != null &&
              response.error!.isNotEmpty) {
            CustomToast.show(
              context,
              message: response.error!,
              type: ToastType.error,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subscription = null;
          _isLoadingSubscription = false;
        });

        // Don't show error toast - fail silently
        debugPrint('[SubscriptionBadge] Failed to load subscription: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    final authState = ref.watch(authProvider);

    // Reload subscription when user logs in (but not for tester accounts)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null && !next.user!.isTester) {
        // User just logged in (non-tester), reload subscription
        _loadSubscription();
      } else if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        // User just logged out, clear subscription
        setState(() {
          _subscription = null;
          _isLoadingSubscription = false;
        });
      }
    });

    // Check if user is a tester account - hide subscription badge for testers
    final isTester = authState.user?.isTester ?? false;

    if (isTester) {
      // Return an empty SizedBox to hide the badge for tester accounts
      return const SizedBox.shrink();
    }

    // If not authenticated, show inactive badge without loading
    if (!authState.isAuthenticated || authState.user == null) {
      return _buildInactiveBadge();
    }

    if (_isLoadingSubscription) {
      return _buildShimmer();
    }

    if (_subscription != null && _subscription!.isActive) {
      return _buildActiveBadge();
    }

    return _buildInactiveBadge();
  }

  Widget _buildShimmer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: AppColors.whiteTransparent5.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: AppColors.blackTransparent10),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Center(
            child: ShimmerBox(
              width: 30,
              height: 30,
              borderRadius: 8,
              baseColor: Color.fromRGBO(255, 255, 255, 0.3),
              highlightColor: Color.fromRGBO(255, 255, 255, 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: AppColors.whiteTransparent5.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: AppColors.blackTransparent10),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInactiveBadge() {
    return GestureDetector(
      onTap: () => PlansBottomSheet.show(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: AppColors.whiteTransparent5.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: AppColors.blackTransparent10),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/cross.svg',
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.8),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
