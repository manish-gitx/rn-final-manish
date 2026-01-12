import 'package:flutter/material.dart';

class EnhancedPageRoute<T> extends MaterialPageRoute<T> {
  final Duration _duration;
  final Curve _curve;

  EnhancedPageRoute({
    required super.builder,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOutCubic,
  })  : _duration = duration,
        _curve = curve;

  @override
  Duration get transitionDuration => _duration;

  @override
  Duration get reverseTransitionDuration => _duration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (settings.name == '/') {
      return child;
    }

    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: _curve,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(0.0, 0.7, curve: _curve),
    ));

    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: _curve,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Transform.scale(
          scale: scaleAnimation.value,
          child: child,
        ),
      ),
    );
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is EnhancedPageRoute || previousRoute is MaterialPageRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is EnhancedPageRoute || nextRoute is MaterialPageRoute;
  }
}