import 'package:flutter/material.dart';
import '../../shared/utils/currency.dart';
import 'app_motion.dart';

/// Counts a number up to [value] when it first appears (and re-counts from the
/// previous value whenever [value] changes), formatting each frame through the
/// app's canonical Indian rupee formatter.
///
/// This is the single most "premium" motion win in the app — it makes the
/// screen feel like it's tallying your money in front of you. Reduced-motion
/// users get the final value instantly.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.decimals = 0,
    this.duration,
    this.curve = AppMotion.entrance,
    this.textAlign,
  });

  /// Target value to count to.
  final num value;

  /// Text style for the rendered amount (use tabular figures to avoid jitter).
  final TextStyle style;

  /// Decimal places passed through to [formatRupee].
  final int decimals;

  final Duration? duration;
  final Curve curve;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final target = value.toDouble();

    if (AppMotion.reduceMotion(context)) {
      return Text(
        formatRupee(target, decimals: decimals),
        style: style,
        textAlign: textAlign,
      );
    }

    return TweenAnimationBuilder<double>(
      // Keying on the target lets the tween restart from its current value
      // when [value] changes (month switch, refresh), rather than snapping.
      key: ValueKey(target),
      tween: Tween(begin: 0, end: target),
      duration: duration ?? AppMotion.slow,
      curve: curve,
      builder: (context, animated, _) => Text(
        formatRupee(animated, decimals: decimals),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
