import 'package:flutter/material.dart';

/// Central motion tokens for the app.
///
/// Keeping durations and curves in one place keeps every entrance, press, and
/// transition feeling like it belongs to the same product. Tune the feel here,
/// not in individual widgets.
abstract class AppMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);

  /// Delay between successive items in a staggered list/card cascade.
  static const Duration staggerStep = Duration(milliseconds: 60);

  // Curves
  /// Default for things entering the screen — decisive, never bouncy.
  static const Curve entrance = Curves.easeOutCubic;

  /// Use sparingly, for a single emphasized element (e.g. a hero number).
  static const Curve emphasized = Curves.easeOutBack;

  /// Press feedback — quick settle.
  static const Curve press = Curves.easeOut;

  /// Returns true when the user has asked the OS to reduce motion.
  /// Animations should fall back to instant / opacity-only when this is set.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
