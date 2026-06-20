import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/insights_screen.dart';

String _fmtMoney(int v) {
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

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
      color: context.bgSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.borderSubtle),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );

// ── Total income card ─────────────────────────────────────────────────────────

class IncomeTotalCard extends StatelessWidget {
  const IncomeTotalCard({super.key, required this.data});
  final IncomeData data;

  @override
  Widget build(BuildContext context) {
    final delta = data.totalIncome - data.prevIncome;
    final hasPrev = data.prevIncome > 0;
    final pctChange =
        hasPrev ? ((delta / data.prevIncome) * 100).round() : null;
    final up = delta >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total income',
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_fmtMoney(data.totalIncome)}',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (pctChange != null)
            Row(
              children: [
                PhosphorIcon(
                  up
                      ? PhosphorIconsBold.trendUp
                      : PhosphorIconsBold.trendDown,
                  size: 14,
                  color: up ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  '${up ? '+' : ''}$pctChange% vs ${data.prevLabel}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: up ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            )
          else
            Text(
              'No income in ${data.prevLabel}',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
        ],
      ),
    );
  }
}

// ── Breakdown bars (by income type) ───────────────────────────────────────────

class IncomeBreakdownCard extends StatelessWidget {
  const IncomeBreakdownCard({super.key, required this.data});
  final IncomeData data;

  @override
  Widget build(BuildContext context) {
    final slices = data.byType;
    final maxAmount = slices.isEmpty
        ? 1
        : slices.map((s) => s.amount).reduce((a, b) => a > b ? a : b);
    final total = data.totalIncome == 0 ? 1 : data.totalIncome;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By source type',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < slices.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _BreakdownRow(
              slice: slices[i],
              fraction: slices[i].amount / maxAmount,
              pct: ((slices[i].amount / total) * 100).round(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.slice,
    required this.fraction,
    required this.pct,
  });
  final CategorySlice slice;
  final double fraction;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                slice.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            ),
            Text(
              '₹${_fmtMoney(slice.amount)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$pct%',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              backgroundColor: context.bgSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(slice.color),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Top income sources ────────────────────────────────────────────────────────

class IncomeSourcesCard extends StatelessWidget {
  const IncomeSourcesCard({super.key, required this.data});
  final IncomeData data;

  @override
  Widget build(BuildContext context) {
    if (data.sources.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top sources',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < data.sources.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.sources[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '${data.sources[i].txCount} ${data.sources[i].txCount == 1 ? 'entry' : 'entries'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${_fmtMoney(data.sources[i].amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
