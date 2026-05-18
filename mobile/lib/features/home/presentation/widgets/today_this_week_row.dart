import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';

class TodayThisWeekRow extends ConsumerWidget {
  const TodayThisWeekRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(currentMonthExpensesProvider);

    return expensesAsync.when(
      loading: () => const Row(
        children: [
          Expanded(child: _SkeletonCard()),
          SizedBox(width: 10),
          Expanded(child: _SkeletonCard()),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (expenses) {
        final now = DateTime.now();
        return Row(
          children: [
            Expanded(child: _TodayCard(expenses: expenses, now: now)),
            const SizedBox(width: 10),
            Expanded(child: _ThisWeekCard(expenses: expenses, now: now)),
          ],
        );
      },
    );
  }
}

// ─── Skeleton card ────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

// ─── Today card ──────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.expenses, required this.now});

  final List<ExpenseModel> expenses;
  final DateTime now;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final todayExpenses =
        expenses.where((e) => _sameDay(e.createdAt, now)).toList();
    final todayTotal = todayExpenses.fold(0.0, (s, e) => s + e.amount);
    final txCount = todayExpenses.length;

    // Last 7 days daily totals: index 0 = 6 days ago, index 6 = today
    final spots = <FlSpot>[];
    double priorSum = 0;
    for (var i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayTotal = expenses
          .where((e) => _sameDay(e.createdAt, day))
          .fold(0.0, (s, e) => s + e.amount);
      if (i < 6) priorSum += dayTotal;
      spots.add(FlSpot(i.toDouble(), dayTotal));
    }

    final avg6 = priorSum / 6;
    final diffVsAvg = todayTotal - avg6;
    final showBadge = avg6 > 0 || todayTotal > 0;

    final maxY = spots.fold(0.0, (m, s) => s.y > m ? s.y : m);
    final chartMaxY = maxY > 0 ? maxY * 1.3 : 1.0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              if (showBadge)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (diffVsAvg >= 0 ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        diffVsAvg >= 0
                            ? PhosphorIcons.arrowUp(PhosphorIconsStyle.bold)
                            : PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
                        size: 9,
                        color: diffVsAvg >= 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '₹${_fmt(diffVsAvg.abs().round())} vs avg',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: diffVsAvg >= 0
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_fmt(todayTotal.round())}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.lightTextPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$txCount txn${txCount == 1 ? '' : 's'} · last 7d',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 1.8,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── This week card ───────────────────────────────────────────────────────────

class _ThisWeekCard extends StatelessWidget {
  const _ThisWeekCard({required this.expenses, required this.now});

  final List<ExpenseModel> expenses;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final todayIndex = now.weekday - 1; // Mon=0 … Sun=6
    final monday = now.subtract(Duration(days: todayIndex));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);

    // Current week daily totals
    final weekTotals = List<double>.filled(7, 0);
    double weekSum = 0;
    for (final e in expenses) {
      final d = DateTime(
          e.createdAt.year, e.createdAt.month, e.createdAt.day);
      final diff = d.difference(mondayDate).inDays;
      if (diff >= 0 && diff < 7) {
        weekTotals[diff] += e.amount;
        weekSum += e.amount;
      }
    }

    // Prior week total for % comparison
    final priorMonday = mondayDate.subtract(const Duration(days: 7));
    double priorSum = 0;
    for (final e in expenses) {
      final d = DateTime(
          e.createdAt.year, e.createdAt.month, e.createdAt.day);
      final diff = d.difference(priorMonday).inDays;
      if (diff >= 0 && diff < 7) priorSum += e.amount;
    }

    final pctChange =
        priorSum > 0 ? ((weekSum - priorSum) / priorSum * 100).round() : null;

    final maxVal = weekTotals.fold(0.0, (m, v) => v > m ? v : m);
    final chartMax = maxVal > 0 ? maxVal * 1.3 : 1.0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_fmt(weekSum.round())}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.lightTextPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          if (pctChange != null)
            Row(
              children: [
                PhosphorIcon(
                  pctChange <= 0
                      ? PhosphorIcons.arrowDown(PhosphorIconsStyle.bold)
                      : PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                  size: 11,
                  color: pctChange <= 0
                      ? AppColors.accent500
                      : AppColors.warning,
                ),
                const SizedBox(width: 2),
                Text(
                  '${pctChange.abs()}% vs last wk',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: pctChange <= 0
                        ? AppColors.accent500
                        : AppColors.warning,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 14),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weekTotals[i],
                        color: i == todayIndex
                            ? AppColors.primary500
                            : const Color(0xFFE5E7EB),
                        width: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 14,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final idx = v.toInt();
                        return Text(
                          days[idx],
                          style: TextStyle(
                            fontSize: 9,
                            color: idx == todayIndex
                                ? AppColors.primary500
                                : AppColors.lightTextTertiary,
                            fontWeight: idx == todayIndex
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared card shell ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(int v) {
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
