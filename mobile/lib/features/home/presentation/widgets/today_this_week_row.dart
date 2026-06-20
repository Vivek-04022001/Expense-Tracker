import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../shared/widgets/shimmer.dart';

class TodayThisWeekRow extends ConsumerWidget {
  const TodayThisWeekRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(currentMonthExpensesProvider);

    return expensesAsync.when(
      loading: () => Row(
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
            SizedBox(width: 10),
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
    return _Card(
      child: SizedBox(
        height: 100,
        child: Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              ShimmerBox(height: 12, width: 60),
              SizedBox(height: 12),
              ShimmerBox(height: 22, width: 90),
              SizedBox(height: 10),
              ShimmerBox(height: 10, width: 70),
            ],
          ),
        ),
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

    // Last 7 days daily totals: index 0 = 6 days ago, index 6 = today
    final spots = <FlSpot>[];
    for (var i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayTotal = expenses
          .where((e) => _sameDay(e.createdAt, day))
          .fold(0.0, (s, e) => s + e.amount);
      spots.add(FlSpot(i.toDouble(), dayTotal));
    }

    final maxY = spots.fold(0.0, (m, s) => s.y > m ? s.y : m);
    final chartMaxY = maxY > 0 ? maxY * 1.3 : 1.0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '₹${_fmt(todayTotal.round())}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              height: 1,
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            height: 40,
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
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: AppColors.primary500,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == 6,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.primary500,
                        strokeWidth: 2,
                        strokeColor: context.bgSurface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary500.withValues(alpha: 0.25),
                          AppColors.primary500.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
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

    final maxVal = weekTotals.fold(0.0, (m, v) => v > m ? v : m);
    final chartMax = maxVal > 0 ? maxVal * 1.3 : 1.0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '₹${_fmt(weekSum.round())}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              height: 1,
            ),
          ),
          SizedBox(height: 14),
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
                        gradient: i == todayIndex
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.primary500,
                                  Color(0xFF5B8DEF),
                                ],
                              )
                            : null,
                        color: i == todayIndex
                            ? null
                            : AppColors.primary500.withValues(alpha: 0.14),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
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
                                : context.textTertiary,
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
        color: context.bgSurface,
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
