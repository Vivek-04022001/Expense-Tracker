import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../../savings/presentation/screens/savings_screen.dart';
import '../../../../shared/widgets/shimmer.dart';

/// Hero overview: this month's income split into spent / saved on a single
/// progress bar, with a forward-looking projection. Rendered on a brand-blue
/// gradient so it anchors the home screen.
class MonthlySpendCard extends ConsumerWidget {
  const MonthlySpendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(currentMonthSavingsProvider);

    if (savingsAsync.isLoading) {
      return const _Shell(child: _LoadingShimmer());
    }
    if (savingsAsync.hasError) {
      return const _Shell(child: _ErrorState());
    }

    final s = savingsAsync.value!;
    final now = DateTime.now();

    final income = s.totalIncome;
    final spent = s.totalExpenses;
    final saved = s.netSavings;
    final rate = s.savingsRate;

    // Pace → end-of-month projection.
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final daysLeft = daysInMonth - dayOfMonth;
    final dailyAvg = dayOfMonth > 0 ? spent / dayOfMonth : 0.0;
    final projectedSaved = saved - dailyAvg * daysLeft;

    // Bar split (income = spent + saved).
    final segSpent = spent < 0 ? 0.0 : spent;
    final segSaved = saved < 0 ? 0.0 : saved;
    final segTotal = segSpent + segSaved;

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month + days left ──
          Row(
            children: [
              _Pill(
                child: Text(
                  '${_monthNames[now.month - 1].toUpperCase()} ${now.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              _Pill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      daysLeft <= 0
                          ? 'Last day'
                          : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Hero figure ──
          Text(
            '₹${_fmt(income.round())}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total income',
                style: TextStyle(fontSize: 13, color: Colors.white60),
              ),
              const SizedBox(width: 10),
              if (income > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.trendUp(PhosphorIconsStyle.bold),
                        size: 12,
                        color: const Color(0xFF6BF0C4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${rate.toStringAsFixed(1)}% saved',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6BF0C4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Spent / saved bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: segTotal <= 0
                  ? Container(color: Colors.white.withValues(alpha: 0.18))
                  : Row(
                      children: [
                        if (segSpent > 0)
                          Expanded(
                            flex: (segSpent / segTotal * 1000).round(),
                            child: Container(color: AppColors.danger),
                          ),
                        if (segSaved > 0)
                          Expanded(
                            flex: (segSaved / segTotal * 1000).round(),
                            child: Container(color: const Color(0xFF2BE0A6)),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Legend ──
          Row(
            children: [
              _Legend(
                color: AppColors.danger,
                label: '₹${_fmt(spent.round())} spent',
              ),
              const SizedBox(width: 20),
              _Legend(
                color: const Color(0xFF2BE0A6),
                label: '₹${_fmt(saved.round())} saved',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 14),

          // ── Footer: projection + drill-in ──
          Row(
            children: [
              Expanded(
                child: Text(
                  projectedSaved >= 0
                      ? "On track to save ₹${_fmt(projectedSaved.round())} this month"
                      : "On track to overspend ₹${_fmt(projectedSaved.abs().round())} this month",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true)
                    .push(slideFadeRoute(const SavingsScreen())),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Gradient shell ──────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E60FF), Color(0xFF0B3CC9)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Small parts ───────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Loading / error ─────────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      baseColor: Colors.white.withValues(alpha: 0.12),
      highlightColor: Colors.white.withValues(alpha: 0.26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(height: 14, width: 110, borderRadius: 8),
          SizedBox(height: 18),
          ShimmerBox(height: 34, width: 200, borderRadius: 8),
          SizedBox(height: 18),
          ShimmerBox(height: 10, width: double.infinity, borderRadius: 6),
          SizedBox(height: 16),
          ShimmerBox(height: 12, width: 220, borderRadius: 6),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 110,
      child: Center(
        child: Text(
          'Could not load this month',
          style: TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _fmt(int v) {
  final neg = v < 0;
  final s = v.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    out = '$buf,$last3';
  }
  return neg ? '-$out' : out;
}
