import 'package:flutter/material.dart';

/// Custom page route with subtle fade+slide transition.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
            final position = Tween<Offset>(
              begin: const Offset(0.08, 0.0),
              end: Offset.zero,
            ).animate(curved);
            final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

            return FadeTransition(
              opacity: opacity,
              child: SlideTransition(
                position: position,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 120),
          reverseTransitionDuration: const Duration(milliseconds: 120),
        );
}

/// Custom page route with fade transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
            return FadeTransition(opacity: curved, child: child);
          },
          transitionDuration: const Duration(milliseconds: 120),
          reverseTransitionDuration: const Duration(milliseconds: 120),
        );
}

/// Custom page route with scale transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return ScaleTransition(
              scale: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
