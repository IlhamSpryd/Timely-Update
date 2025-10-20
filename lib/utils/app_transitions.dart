// lib/utils/app_transitions.dart

import 'package:flutter/material.dart';

class SlideFadeRoute extends PageRouteBuilder {
  final Widget page;
  final Offset beginOffset;

  SlideFadeRoute({
    required this.page,
    this.beginOffset = const Offset(0.5, 0.0),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            );
            final slideTween = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            );
            final slideAnimation = slideTween.animate(curvedAnimation);
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
            final fadeAnimation = fadeTween.animate(curvedAnimation);
            final scaleTween = Tween<double>(begin: 0.98, end: 1.0);
            final scaleAnimation = scaleTween.animate(curvedAnimation);
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}
