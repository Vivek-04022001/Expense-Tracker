import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../animation/app_motion.dart';

/// Shared fade + subtle upward-slide transition for pushed (detail) routes, so
/// screens don't hard-cut in. Centralised here so every route feels the same.
CustomTransitionPage<T> slideFadePage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.base,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondary, child) {
      if (AppMotion.reduceMotion(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.entrance,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Imperative-navigation twin of [slideFadePage] for screens pushed with
/// `Navigator.push` (detail screens, profile sub-pages). Keeps push transitions
/// consistent with the declarative routes.
Route<T> slideFadeRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    transitionDuration: AppMotion.base,
    reverseTransitionDuration: AppMotion.fast,
    pageBuilder: (context, animation, secondary) => child,
    transitionsBuilder: (context, animation, secondary, child) {
      if (AppMotion.reduceMotion(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.entrance,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

