import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A single ranked category/source: its label, total amount, and swatch colour.
class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final int amount;
  final Color color;
}

/// Unified period overview: title + total, a vs-previous delta pill, an
/// animated donut whose centre swaps to the tapped slice, and a ranked legend
/// where each row carries its own share bar.
class SpendingOverviewCard extends StatefulWidget {
  const SpendingOverviewCard({
    super.key,
    required this.title,
    required this.total,
    required this.prevTotal,
    required this.prevLabel,
    required this.slices,
    required this.isIncome,
  });

  final String title;
  final int total;
  final int prevTotal;
  final String prevLabel;
  final List<CategorySlice> slices;
  final bool isIncome;

  @override
  State<SpendingOverviewCard> createState() => _SpendingOverviewCardState();
}

class _SpendingOverviewCardState extends State<SpendingOverviewCard> {
  int _sel = -1;

  @override
  void didUpdateWidget(covariant SpendingOverviewCard old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title || old.total != widget.total) _sel = -1;
  }

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices;
    final total = widget.total;
    final maxAmt = slices.isEmpty ? 1 : slices.first.amount;

    final hasPrev = widget.prevTotal > 0;
    final pct = hasPrev
        ? (widget.total - widget.prevTotal) / widget.prevTotal * 100
        : 0.0;
    final isUp = pct > 0;
    // Spending less is good; earning more is good.
    final good = widget.isIncome ? isUp : !isUp;
    final deltaColor = good ? AppColors.success : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + delta ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_grp(total)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPrev)
                _DeltaPill(
                  pct: pct,
                  color: deltaColor,
                  isUp: isUp,
                  label: widget.prevLabel,
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Donut ──
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('${widget.title}-$total'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(
                  painter: _DonutPainter(
                    slices: slices,
                    total: total,
                    progress: t,
                    selected: _sel,
                    track: context.borderSubtle,
                  ),
                  child: Center(child: _centerLabel(context, slices, total)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 12),

          // ── Ranked legend with share bars ──
          ...List.generate(
            slices.length,
            (i) => _LegendRow(
              slice: slices[i],
              maxAmount: maxAmt,
              selected: i == _sel,
              onTap: () => setState(() => _sel = _sel == i ? -1 : i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerLabel(BuildContext context, List<CategorySlice> slices, int total) {
    final selected = _sel >= 0 && _sel < slices.length ? slices[_sel] : null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Column(
        key: ValueKey(selected?.label ?? '__total__'),
        mainAxisSize: MainAxisSize.min,
        children: selected == null
            ? [
                Text(
                  '₹${_compact(total)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total',
                  style: TextStyle(fontSize: 12, color: context.textTertiary),
                ),
              ]
            : [
                Text(
                  '₹${_compact(selected.amount)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selected.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected.color,
                  ),
                ),
                Text(
                  '${total > 0 ? (selected.amount / total * 100).round() : 0}% of total',
                  style: TextStyle(fontSize: 10.5, color: context.textTertiary),
                ),
              ],
      ),
    );
  }
}

// ── Legend row ──────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.maxAmount,
    required this.selected,
    required this.onTap,
  });

  final CategorySlice slice;
  final int maxAmount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final factor = maxAmount > 0 ? (slice.amount / maxAmount).clamp(0.0, 1.0) : 0.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? slice.color.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    slice.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '₹${_grp(slice.amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: context.borderSubtle.withValues(alpha: 0.6)),
                    FractionallySizedBox(
                      widthFactor: factor,
                      child: Container(color: slice.color),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delta pill ──────────────────────────────────────────────────────────────

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.pct,
    required this.color,
    required this.isUp,
    required this.label,
  });

  final double pct;
  final Color color;
  final bool isUp;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUp ? Icons.trending_up : Icons.trending_down,
              size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${pct.abs().toStringAsFixed(1)}% vs $label',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donut painter ─────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.progress,
    required this.selected,
    required this.track,
  });

  final List<CategorySlice> slices;
  final int total;
  final double progress;
  final int selected;
  final Color track;

  static const double thickness = 20;
  static const double selectedThickness = 26;
  static const double arcRadius = 74;
  static const double _gap = 0.11;
  static const double _minSweep = 0.02;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: arcRadius);

    final trackPaint = Paint()
      ..color = track.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, arcRadius, trackPaint);

    if (total <= 0) return;

    const startBase = -math.pi / 2;
    var acc = 0.0;
    for (var i = 0; i < slices.length; i++) {
      final fullSweep = slices[i].amount / total * 2 * math.pi;
      final sweep = fullSweep * progress;
      if (sweep <= 0.0001) {
        acc += fullSweep;
        continue;
      }
      final isSel = i == selected;
      final dim = selected != -1 && !isSel;
      final drawSweep = math.max(sweep - _gap, _minSweep);
      final start = startBase + acc + (sweep - drawSweep) / 2;

      final paint = Paint()
        ..color = dim ? slices[i].color.withValues(alpha: 0.35) : slices[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSel ? selectedThickness : thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, drawSweep, false, paint);
      acc += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      old.slices != slices ||
      old.total != total;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _compact(int v) {
  if (v >= 1000) {
    final k = v / 1000.0;
    return k >= 100 ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
  }
  return v.toString();
}

String _grp(int v) {
  final neg = v < 0;
  final s = v.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    out = '$buf,$last3';
  }
  return neg ? '-$out' : out;
}
