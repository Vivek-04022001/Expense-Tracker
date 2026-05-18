import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../../savings/presentation/screens/savings_screen.dart';

class SavingsRateCard extends ConsumerWidget {
  const SavingsRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(currentMonthSavingsProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SavingsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: savingsAsync.when(
          loading: () => const _CardShimmer(),
          error: (_, __) => const _CardError(),
          data: (s) => _CardContent(s: s),
        ),
      ),
    );
  }
}

// ── Loaded content ────────────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  const _CardContent({required this.s});
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    final isPositive = s.netSavings >= 0;
    final rateColor = s.savingsRate >= 20
        ? AppColors.success
        : s.savingsRate >= 5
            ? AppColors.warning
            : AppColors.danger;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: rateColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: PhosphorIcon(
              PhosphorIconsFill.piggyBank,
              size: 20,
              color: rateColor,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Savings rate this month',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${s.savingsRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: rateColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isPositive ? '+' : '−'}₹${_fmtNum(s.netSavings.abs().round())} saved',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isPositive
                          ? AppColors.lightTextSecondary
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PhosphorIcon(
          PhosphorIconsRegular.caretRight,
          size: 16,
          color: AppColors.lightTextTertiary,
        ),
      ],
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.lightBorderSubtle,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: 130,
                decoration: BoxDecoration(
                  color: AppColors.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 18,
                width: 90,
                decoration: BoxDecoration(
                  color: AppColors.lightBorderSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _CardError extends StatelessWidget {
  const _CardError();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.lightBorderSubtle,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: PhosphorIcon(
              PhosphorIconsRegular.piggyBank,
              size: 20,
              color: AppColors.lightTextTertiary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Savings rate this month',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Could not load — tap to retry',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ),
        const PhosphorIcon(
          PhosphorIconsRegular.caretRight,
          size: 16,
          color: AppColors.lightTextTertiary,
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
