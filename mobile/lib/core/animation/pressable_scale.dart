import 'package:flutter/material.dart';
import 'app_motion.dart';

/// Wraps any tappable element with a subtle press-down scale, giving the whole
/// app a consistent, tactile response to touch. Settles back on release/cancel.
///
/// Reduced-motion users get the tap behaviour without the scale.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.98,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Scale at full press. Cards use ~0.98; small buttons can go lower.
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: reduce ? null : (_) => _set(true),
      onTapUp: reduce ? null : (_) => _set(false),
      onTapCancel: reduce ? null : () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.press,
        child: widget.child,
      ),
    );
  }
}
