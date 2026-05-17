import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/insights_screen.dart';

class TotalSpendCard extends StatelessWidget {
  const TotalSpendCard({super.key, required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    final delta = data.totalSpend - data.prevMonthSpend;
    final pct = data.prevMonthSpend > 0
        ? (delta / data.prevMonthSpend * 100).round()
        : 0;
    final isUp = delta >= 0;
    final pctColor = isUp ? AppColors.warning : AppColors.success;
    final pctIcon = isUp
        ? PhosphorIcons.arrowUp(PhosphorIconsStyle.bold)
        : PhosphorIcons.arrowDown(PhosphorIconsStyle.bold);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total spend',
            style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _fmtRupee(data.totalSpend),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(pctIcon, size: 11, color: pctColor),
                    const SizedBox(width: 2),
                    Text(
                      '${pct.abs()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pctColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'vs ${data.prevMonthLabel}',
                style: const TextStyle(fontSize: 12, color: AppColors.lightTextTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _fmtRupee(int v) => '₹${_fmtNum(v)}';

String _fmtNum(int v) {
  if (v < 1000) return v.toString();
  final s = v.toString();
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '$buf,$last3';
}
