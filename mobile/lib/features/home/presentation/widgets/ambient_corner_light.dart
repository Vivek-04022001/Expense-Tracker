import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A fixed, non-interactive light that rakes down from the top-right corner —
/// a soft teal spotlight that "breathes" slowly. Mirrors the glow in the
/// reference design. Only meant for the dark theme, where additive light reads
/// as atmosphere; on light surfaces it would just wash things out, so callers
/// should gate on [Brightness.dark].
///
/// Respects the platform "reduce motion" setting: when animations are
/// disabled, the light holds at its mid-intensity instead of pulsing.
class AmbientCornerLight extends StatefulWidget {
  const AmbientCornerLight({super.key});

  @override
  State<AmbientCornerLight> createState() => _AmbientCornerLightState();
}

class _AmbientCornerLightState extends State<AmbientCornerLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    // Ease in and out so the pulse never feels mechanical.
    _breath = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
      return const IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _CornerLightPainter(t: 0.5),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _CornerLightPainter(t: _breath.value),
          ),
        ),
      ),
    );
  }
}

class _CornerLightPainter extends CustomPainter {
  const _CornerLightPainter({required this.t});

  /// Breathing phase, 0 (dim) → 1 (bright).
  final double t;

  // A brightened, slightly cyan-shifted take on the app accent so the light
  // feels luminous rather than just tinted.
  static const _glow = Color(0xFF3FE3C8);

  @override
  void paint(Canvas canvas, Size size) {
    // Source sits just outside the top-right corner.
    final source = Offset(size.width * 0.96, -size.height * 0.04);

    // 1) Broad halo — the soft fill that bleeds across the upper area.
    final haloRadius = size.width * lerpDouble(0.92, 0.02, t)!;
    final haloAlpha = lerpDouble(0.10, 0.16, t)!;
    _paintRadial(
      canvas,
      size,
      source,
      haloRadius,
      [
        _glow.withValues(alpha: haloAlpha),
        _glow.withValues(alpha: haloAlpha * 1.35),
        Colors.transparent,
      ],
      const [0.0, 0.45, 1.0],
    );

    // 2) Tight core — the bright pool right at the corner.
    final coreRadius = size.width * lerpDouble(1.34, 0.40, t)!;
    final coreAlpha = lerpDouble(0.22, 0.34, t)!;
    _paintRadial(
      canvas,
      size,
      source,
      coreRadius,
      [
        _glow.withValues(alpha: coreAlpha),
        _glow.withValues(alpha: coreAlpha * 0.4),
        Colors.transparent,
      ],
      const [0.0, 0.5, 1.0],
    );

    // 3) Beam — an elongated, blurred streak raking down toward the lower
    //    left, giving the corner light its directional "spotlight" feel.
    final beamAlpha = lerpDouble(0.05, 0.10, t)!;
    final beamPaint = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48)
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          _glow.withValues(alpha: beamAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.save();
    canvas.translate(source.dx, source.dy);
    canvas.rotate(0.9); // ~51°, angled down-left
    final beamRect = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * 0.42,
      height: size.height * 1.6,
    );
    canvas.drawRect(beamRect, beamPaint);
    canvas.restore();
  }

  void _paintRadial(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    List<Color> colors,
    List<double> stops,
  ) {
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_CornerLightPainter oldDelegate) => oldDelegate.t != t;
}
