import 'package:fl_chart/fl_chart.dart';
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

class _Week {
  const _Week(this.index, this.startDay, this.endDay, this.amount);
  final int index;
  final int startDay;
  final int endDay;
  final double amount;
}

class ExpenseFlowCard extends StatelessWidget {
  const ExpenseFlowCard({super.key, required this.data, required this.month});

  final InsightsData data;
  final InsightsMonth month;

  List<_Week> _buildWeeks() {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final nWeeks = (daysInMonth / 7).ceil();
    return List.generate(nWeeks, (w) {
      final startDay = w * 7 + 1;
      final endDay = ((w + 1) * 7).clamp(1, daysInMonth);
      double amount = 0;
      for (var d = startDay; d <= endDay; d++) {
        if (d - 1 < data.dailySpend.length) amount += data.dailySpend[d - 1];
      }
      return _Week(w + 1, startDay, endDay, amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();
    final total = weeks.fold<double>(0, (s, w) => s + w.amount);
    final maxAmount = weeks.isEmpty
        ? 1.0
        : weeks.map((w) => w.amount).reduce((a, b) => a > b ? a : b);
    final monthAbbr = _shortMonth(month.month);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense flow',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Spending by week',
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.25,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'W${value.toInt() + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.textPrimary,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '₹${_fmtMoney(rod.toY.round())}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < weeks.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeks[i].amount,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          color: weeks[i].amount == maxAmount && maxAmount > 0
                              ? AppColors.primary500
                              : AppColors.primary500.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 8),
          for (var i = 0; i < weeks.length; i++)
            _WeekRow(
              week: weeks[i],
              monthAbbr: monthAbbr,
              pct: total > 0 ? ((weeks[i].amount / total) * 100).round() : 0,
              prevAmount: i > 0 ? weeks[i - 1].amount : null,
            ),
        ],
      ),
    );
  }

  String _shortMonth(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.monthAbbr,
    required this.pct,
    required this.prevAmount,
  });

  final _Week week;
  final String monthAbbr;
  final int pct;
  final double? prevAmount;

  @override
  Widget build(BuildContext context) {
    final up = prevAmount != null && week.amount > prevAmount!;
    final down = prevAmount != null && week.amount < prevAmount!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week ${week.index}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '$monthAbbr ${week.startDay}–${week.endDay}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              if (up || down)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: PhosphorIcon(
                    up ? PhosphorIconsBold.trendUp : PhosphorIconsBold.trendDown,
                    size: 13,
                    // Rising spend is unfavourable → red; falling → green.
                    color: up ? AppColors.danger : AppColors.success,
                  ),
                ),
              Text(
                '₹${_fmtMoney(week.amount.round())}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
