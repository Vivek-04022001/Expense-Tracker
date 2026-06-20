import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_motion.dart';

/// Shared entrance animations so every screen cascades the same way.
///
/// Built on `flutter_animate` (already the app's animation lib) and wired to the
/// [AppMotion] tokens. All helpers respect reduced-motion: when the user has
/// disabled animations they return the child untouched.
extension EntranceAnimations on Widget {
  /// Fade + gentle upward slide. The default entrance for cards and rows.
  Widget fadeSlideIn(
    BuildContext context, {
    Duration? delay,
    double slide = 0.12,
  }) {
    if (AppMotion.reduceMotion(context)) return this;
    return animate()
        .fadeIn(duration: AppMotion.base, delay: delay)
        .slideY(begin: slide, curve: AppMotion.entrance, delay: delay);
  }
}

/// Wraps a list of children in a staggered fade-slide cascade — each child
/// enters [AppMotion.staggerStep] after the previous one. Use for the column of
/// cards on a screen so they ripple in instead of snapping together.
List<Widget> staggeredColumn(
  BuildContext context,
  List<Widget> children, {
  Duration initialDelay = Duration.zero,
  double slide = 0.12,
}) {
  if (AppMotion.reduceMotion(context)) return children;
  return List.generate(children.length, (i) {
    final delay = initialDelay + AppMotion.staggerStep * i;
    return children[i].fadeSlideIn(context, delay: delay, slide: slide);
  });
}
