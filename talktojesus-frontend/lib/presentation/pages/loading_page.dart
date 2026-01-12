import 'package:flutter/material.dart';
import '../../core/widgets/shimmer_loading.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image - exact same as Jesus page
          Transform.translate(
            offset: const Offset(0, 60),
            child: Transform.scale(
              scale: 1.3,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/jesus.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Top bar shimmer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: _buildTopBarShimmer(),
            ),
          ),
          // Subscription badge shimmer in top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: _buildSubscriptionShimmer(),
          ),
          // Bottom section shimmer
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildBottomSectionShimmer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarShimmer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button shimmer
        ShimmerBox(
          width: 48,
          height: 48,
          borderRadius: 12,
          baseColor: Colors.white.withValues(alpha: 0.3),
          highlightColor: Colors.white.withValues(alpha: 0.5),
        ),
        // Language selector shimmer
        ShimmerBox(
          width: 120,
          height: 48,
          borderRadius: 24,
          baseColor: Colors.white.withValues(alpha: 0.3),
          highlightColor: Colors.white.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildBottomSectionShimmer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Inspirational message shimmer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              ShimmerBox(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
                baseColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
                baseColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                width: 200,
                height: 16,
                borderRadius: 4,
                baseColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bible button shimmer
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerCircle(
                    size: 24,
                    baseColor: Colors.white.withValues(alpha: 0.3),
                    highlightColor: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  ShimmerBox(
                    width: 60,
                    height: 16,
                    borderRadius: 4,
                    baseColor: Colors.white.withValues(alpha: 0.3),
                    highlightColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Voice input bar shimmer
        Container(
          width: double.infinity,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerCircle(
                size: 26,
                baseColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              ShimmerBox(
                width: 150,
                height: 16,
                borderRadius: 4,
                baseColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionShimmer() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: ShimmerBox(
          width: 30,
          height: 30,
          borderRadius: 8,
          baseColor: Colors.white.withValues(alpha: 0.3),
          highlightColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
