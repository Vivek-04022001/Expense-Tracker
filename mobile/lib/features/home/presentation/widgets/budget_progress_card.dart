import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({super.key});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Text(
                'April so far',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              Spacer(),
              Text(
                'Salary · Apr 15',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Income bar (full, near black)
          _ProgressBar(
            fraction: 1.0,
            color: const Color(0xFF1A1A2E),
          ),
          const SizedBox(height: 5),
          // Savings bar (66%, green)
          _ProgressBar(
            fraction: 0.66,
            color: AppColors.accent500,
          ),
          const SizedBox(height: 16),
          // Metrics row
          const Row(
            children: [
              Expanded(
                child: _Metric(
                  dot: Color(0xFF1A1A2E),
                  label: 'INCOME',
                  value: '₹1,25,000',
                  valueColor: AppColors.lightTextPrimary,
                ),
              ),
              Expanded(
                child: _Metric(
                  dot: AppColors.lightTextSecondary,
                  label: 'SPENT',
                  value: '₹42,380',
                  valueColor: AppColors.lightTextPrimary,
                ),
              ),
              Expanded(
                child: _Metric(
                  dot: AppColors.accent500,
                  label: 'SAVED',
                  value: '₹82,620',
                  valueColor: AppColors.accent500,
                  subtitle: '66% of income',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Stack(
        children: [
          Container(
            width: constraints.maxWidth,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.lightBorderSubtle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: constraints.maxWidth * fraction,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.dot,
    required this.label,
    required this.value,
    required this.valueColor,
    this.subtitle,
  });

  final Color dot;
  final String label;
  final String value;
  final Color valueColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextTertiary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.lightTextTertiary,
            ),
          ),
        ],
      ],
    );
  }
}
