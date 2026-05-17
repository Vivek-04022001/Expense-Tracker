import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class TodayThisWeekRow extends StatelessWidget {
  const TodayThisWeekRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _TodayCard()),
        SizedBox(width: 10),
        Expanded(child: _ThisWeekCard()),
      ],
    );
  }
}

// ─── Today card ──────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  static const _spots = [
    FlSpot(0, 3.0), FlSpot(1, 2.2), FlSpot(2, 3.5), FlSpot(3, 2.0),
    FlSpot(4, 2.8), FlSpot(5, 1.6), FlSpot(6, 2.1),
  ];

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                      size: 9,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      '₹420 vs avg',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '₹1,130',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.lightTextPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '4 txns · last 7d',
            style: TextStyle(fontSize: 10, color: AppColors.lightTextTertiary),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6, minY: 0, maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
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
  const _ThisWeekCard();

  static const _values = [0.8, 1.2, 0.6, 1.1, 1.5, 1.9, 0.4];
  static const _todayIndex = 5; // Saturday

  @override
  Widget build(BuildContext context) {
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
          const Text(
            '₹7,240',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.lightTextPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
                size: 11,
                color: AppColors.accent500,
              ),
              const SizedBox(width: 2),
              const Text(
                '8%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: BarChart(
              BarChartData(
                maxY: 2.5,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  _values.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _values[i],
                        color: i == _todayIndex
                            ? AppColors.primary500
                            : const Color(0xFFE5E7EB),
                        width: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 14,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(
                          days[v.toInt()],
                          style: TextStyle(
                            fontSize: 9,
                            color: v.toInt() == _todayIndex
                                ? AppColors.primary500
                                : AppColors.lightTextTertiary,
                            fontWeight: v.toInt() == _todayIndex
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
