import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

// ── Public API ────────────────────────────────────────────────────────────────

Future<void> showSuccessOverlay(
  BuildContext context, {
  required bool isExpense,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _SuccessOverlay(isExpense: isExpense),
    ),
  );
}

// ── Overlay page ──────────────────────────────────────────────────────────────

class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay({required this.isExpense});
  final bool isExpense;

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay> {
  bool _dismissing = false;

  Color get _color => widget.isExpense ? AppColors.danger : AppColors.success;
  String get _label => widget.isExpense ? 'Expense Added' : 'Income Added';
  String get _subtitle =>
      widget.isExpense ? 'Tracked & saved' : 'Recorded successfully';

  @override
  void initState() {
    super.initState();
    _fireHaptics();
    Future.delayed(2400.ms, _dismiss);
  }

  Future<void> _fireHaptics() async {
    // Soft tap as overlay appears
    await HapticFeedback.lightImpact();
    // Satisfying thud as circle pops in
    await Future.delayed(const Duration(milliseconds: 340));
    await HapticFeedback.heavyImpact();
    // Quick double-tap for the "success" feel
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }

  void _dismiss() {
    if (!mounted || _dismissing) return;
    setState(() => _dismissing = true);
    Future.delayed(380.ms, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedOpacity(
        opacity: _dismissing ? 0.0 : 1.0,
        duration: 380.ms,
        curve: Curves.easeOut,
        child: Material(
          color: Colors.black.withValues(alpha: 0.72),
          child: Stack(
            children: [
              // Radial particle burst
              _ParticleBurst(
                centerX: size.width / 2,
                centerY: size.height / 2 - 70,
                color: _color,
              ),

              // Main centered content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/illustrations/success.png',
                      width: 220,
                      height: 180,
                      fit: BoxFit.contain,
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.0, 0.0),
                          end: const Offset(1.0, 1.0),
                          duration: 600.ms,
                          delay: 60.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 250.ms, delay: 60.ms),
                    const SizedBox(height: 20),
                    Text(
                      _label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 520.ms)
                        .slideY(
                          begin: 0.25,
                          end: 0,
                          duration: 380.ms,
                          delay: 520.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 640.ms)
                        .slideY(
                          begin: 0.25,
                          end: 0,
                          duration: 380.ms,
                          delay: 640.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 48),
                    // Tap to dismiss hint
                    Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.28),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 1200.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Particle burst ────────────────────────────────────────────────────────────

class _ParticleBurst extends StatelessWidget {
  const _ParticleBurst({
    required this.centerX,
    required this.centerY,
    required this.color,
  });
  final double centerX;
  final double centerY;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rng = Random(7);
    const count = 16;

    return Stack(
      children: List.generate(count, (i) {
        final angle = (i / count) * 2 * pi + rng.nextDouble() * 0.4 - 0.2;
        final distance = 90.0 + rng.nextDouble() * 100;
        final size = 5.0 + rng.nextDouble() * 9;
        final delay = Duration(milliseconds: 260 + rng.nextInt(180));
        final isSquare = i % 4 == 3;

        final particleColor = switch (i % 3) {
          0 => color,
          1 => Color.lerp(color, Colors.white, 0.45)!,
          _ => Colors.white.withValues(alpha: 0.85),
        };

        final dx = cos(angle) * distance;
        final dy = sin(angle) * distance;

        return Positioned(
          left: centerX - size / 2,
          top: centerY - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: particleColor,
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isSquare ? BorderRadius.circular(2) : null,
            ),
          )
              .animate(delay: delay)
              .moveX(begin: 0, end: dx, duration: 500.ms, curve: Curves.easeOutCubic)
              .moveY(begin: 0, end: dy, duration: 500.ms, curve: Curves.easeOutCubic)
              .scaleXY(begin: 0, end: 1, duration: 300.ms, curve: Curves.easeOutBack)
              .then(delay: 180.ms)
              .fadeOut(duration: 350.ms, curve: Curves.easeIn),
        );
      }),
    );
  }
}
