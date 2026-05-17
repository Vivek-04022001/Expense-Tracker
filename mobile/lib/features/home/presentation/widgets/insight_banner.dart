import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class InsightBanner extends StatefulWidget {
  const InsightBanner({super.key});

  @override
  State<InsightBanner> createState() => _InsightBannerState();
}

class _InsightBannerState extends State<InsightBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'INSIGHT · THIS WEEK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _dismissed = true),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Food spend is 30% higher than last week, mostly from weekend delivery orders.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.lightTextPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
