import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/savings_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthAsync = ref.watch(currentMonthSavingsProvider);
    final allTimeAsync = ref.watch(allTimeSavingsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: context.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderSubtle),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIconsRegular.caretLeft,
                          size: 18,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Savings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _SectionLabel(label: DateFormat('MMMM yyyy').format(now)),
              SizedBox(height: 10),
              monthAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const _ErrorCard(),
                data: (s) => _SummaryCard(
                  totalIncome: s.totalIncome,
                  totalExpenses: s.totalExpenses,
                  netSavings: s.netSavings,
                  savingsRate: s.savingsRate,
                ),
              ),
              SizedBox(height: 24),
              const _SectionLabel(label: 'All time'),
              SizedBox(height: 10),
              allTimeAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const _ErrorCard(),
                data: (s) => _SummaryCard(
                  totalIncome: s.totalIncome,
                  totalExpenses: s.totalExpenses,
                  netSavings: s.netSavings,
                  savingsRate: s.savingsRate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.savingsRate,
  });

  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final double savingsRate;

  @override
  Widget build(BuildContext context) {
    final isPositive = netSavings >= 0;
    final rateColor = savingsRate >= 20
        ? AppColors.success
        : savingsRate >= 5
            ? AppColors.warning
            : AppColors.danger;

    final spentFlex = totalIncome > 0
        ? (totalExpenses / totalIncome * 1000).round().clamp(0, 1000)
        : 0;
    final savedFlex = (1000 - spentFlex).clamp(0, 1000);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net savings',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : '−'}₹${_fmtNum(netSavings.abs().round())}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isPositive ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${savingsRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: rateColor,
                      ),
                    ),
                    Text(
                      'saved',
                      style: TextStyle(
                        fontSize: 11,
                        color: rateColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: totalIncome > 0
                    ? [
                        Expanded(
                          flex: spentFlex,
                          child: Container(color: AppColors.danger),
                        ),
                        if (savedFlex > 0)
                          Expanded(
                            flex: savedFlex,
                            child: Container(color: AppColors.success),
                          ),
                      ]
                    : [
                        Expanded(
                            child: Container(color: const Color(0xFFECEDF0))),
                      ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                dot: const Color(0xFF1A1A2E),
                label: 'INCOME',
                value: '₹${_fmtNum(totalIncome.round())}',
              ),
              SizedBox(width: 24),
              _StatItem(
                dot: AppColors.danger,
                label: 'SPENT',
                value: '₹${_fmtNum(totalExpenses.round())}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.dot,
    required this.label,
    required this.value,
  });

  final Color dot;
  final String label;
  final String value;

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
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Loading / error ───────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Could not load savings data',
            style: TextStyle(color: context.textSecondary),
          ),
        ),
      );
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
