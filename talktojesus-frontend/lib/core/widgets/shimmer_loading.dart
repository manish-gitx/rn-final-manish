import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ShimmerProfileCard extends StatelessWidget {
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerProfileCard({
    super.key,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture
          ShimmerCircle(
            size: 80,
            baseColor: baseColor ?? Colors.white.withValues(alpha: 0.3),
            highlightColor:
                highlightColor ?? Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          // Name
          ShimmerBox(
            width: 150,
            height: 20,
            borderRadius: 4,
            baseColor: baseColor ?? Colors.white.withValues(alpha: 0.3),
            highlightColor:
                highlightColor ?? Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          // Email
          ShimmerBox(
            width: 200,
            height: 14,
            borderRadius: 4,
            baseColor: baseColor ?? Colors.white.withValues(alpha: 0.3),
            highlightColor:
                highlightColor ?? Colors.white.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class ShimmerSubscriptionCard extends StatelessWidget {
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerSubscriptionCard({
    super.key,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(
                width: 100,
                height: 16,
                borderRadius: 4,
                baseColor: baseColor ?? Colors.white.withValues(alpha: 0.3),
                highlightColor:
                    highlightColor ?? Colors.white.withValues(alpha: 0.5),
              ),
              ShimmerBox(
                width: 60,
                height: 20,
                borderRadius: 8,
                baseColor: baseColor ?? Colors.white.withValues(alpha: 0.3),
                highlightColor:
                    highlightColor ?? Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShimmerBox(
            width: 120,
            height: 24,
            borderRadius: 4,
            baseColor: baseColor ?? Colors.white.withValues(alpha: 0.3),
            highlightColor:
                highlightColor ?? Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          ShimmerBox(
            width: 80,
            height: 16,
            borderRadius: 4,
            baseColor: baseColor ?? Colors.white.withValues(alpha: 0.3),
            highlightColor:
                highlightColor ?? Colors.white.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
