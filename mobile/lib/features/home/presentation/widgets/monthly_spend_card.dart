import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class MonthlySpendCard extends StatelessWidget {
  const MonthlySpendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spent this month',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '₹42,380',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                          size: 13,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '12% vs last month',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _DonutChart(percent: 0.71),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.lightBorderSubtle),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text(
                '₹17,620 left of ₹60,000',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              Spacer(),
              Text(
                '12 days remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 24,
              sectionsSpace: 0,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: percent * 100,
                  color: AppColors.warning,
                  radius: 12,
                  title: '',
                ),
                PieChartSectionData(
                  value: (1 - percent) * 100,
                  color: const Color(0xFFEEF0F5),
                  radius: 12,
                  title: '',
                ),
              ],
            ),
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

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
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
