import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Wraps a subtree of placeholder boxes and sweeps an animated highlight
/// gradient across them, producing a classic "shimmer" loading effect.
///
/// Use [ShimmerBox] for the individual placeholder shapes inside the child.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? context.borderSubtle;
    final highlight = widget.highlightColor ??
        Color.alphaBlend(
          (context.bgSurface).withValues(alpha: 0.6),
          base,
        );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.30, 0.50, 0.70],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  /// Animation value in [0, 1].
  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Sweep from off the left edge to off the right edge.
    return Matrix4.translationValues(
      bounds.width * (value * 2 - 1),
      0,
      0,
    );
  }
}

/// A solid rounded placeholder shape. Its color is irrelevant — the parent
/// [Shimmer]'s gradient paints over every opaque pixel via [BlendMode.srcATop].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 6,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.borderSubtle,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}
