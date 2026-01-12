import 'package:flutter/material.dart';

class CustomSlideTransition extends PageRouteBuilder {
  final Widget page;
  final Offset beginOffset;
  final Offset endOffset;
  final Duration duration;

  CustomSlideTransition({
    required this.page,
    this.beginOffset = const Offset(1.0, 0.0),
    this.endOffset = Offset.zero,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: beginOffset,
              end: endOffset,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ));

            final slideOutAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ));

            return SlideTransition(
              position: secondaryAnimation.value > 0 ? slideOutAnimation : slideAnimation,
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.7),
                )),
                child: child,
              ),
            );
          },
        );
}

class FadeSlideTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  FadeSlideTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            final slideTween = Tween(begin: begin, end: end);
            final slideAnimation = animation.drive(slideTween);

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

class CustomScaleTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  CustomScaleTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8),
            ));

            return Transform.scale(
              scale: scaleAnimation.value,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}