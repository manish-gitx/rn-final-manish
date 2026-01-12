import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable shimmer widget that follows SOLID principles
/// Single Responsibility: Only handles shimmer animation
/// Open/Closed: Can be extended for different shimmer types
/// Dependency Inversion: Depends on abstractions (Widget) not concretions
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  });

  /// Factory constructor for dark theme shimmer (default for this app)
  factory AppShimmer.dark({
    Duration? period,
    required Widget child,
  }) {
    return AppShimmer(
      baseColor: Colors.grey[900]?.withValues(alpha: 0.3),
      highlightColor: Colors.grey[700]?.withValues(alpha: 0.1),
      period: period ?? const Duration(milliseconds: 1500),
      child: child,
    );
  }

  /// Factory constructor for light theme shimmer
  factory AppShimmer.light({
    Duration? period,
    required Widget child,
  }) {
    return AppShimmer(
      baseColor: Colors.grey[300],
      highlightColor: Colors.grey[100],
      period: period ?? const Duration(milliseconds: 1500),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[900]?.withValues(alpha: 0.3) ?? Colors.grey,
      highlightColor: highlightColor ?? Colors.grey[700]?.withValues(alpha: 0.1) ?? Colors.white,
      period: period,
      child: child,
    );
  }
}

/// Abstract class for shimmer shapes (Open/Closed Principle)
abstract class ShimmerShape extends StatelessWidget {
  const ShimmerShape({super.key});
}

/// Concrete implementations of shimmer shapes
class ShimmerBox extends ShimmerShape {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

class ShimmerCircle extends ShimmerShape {
  final double diameter;
  final Color? color;

  const ShimmerCircle({
    super.key,
    required this.diameter,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ShimmerLine extends ShimmerShape {
  final double width;
  final double height;
  final Color? color;

  const ShimmerLine({
    super.key,
    required this.width,
    this.height = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}