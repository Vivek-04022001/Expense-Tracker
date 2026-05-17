import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/insights_screen.dart';

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key, required this.insight});
  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                size: 16,
                color: AppColors.primary500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
