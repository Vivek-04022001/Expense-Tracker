import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/data/models/income_model.dart';
import '../../../income/presentation/providers/income_provider.dart';

class MonthlySpendCard extends ConsumerWidget {
  const MonthlySpendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(expenseSummaryProvider);
    final incomesAsync = ref.watch(currentMonthIncomesProvider);

    final isLoading =
        summaryAsync.isLoading || incomesAsync.isLoading;
    final hasError =
        summaryAsync.hasError || incomesAsync.hasError;

    if (isLoading) {
      return _Card(
        child: SizedBox(
          height: 110,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (hasError) {
      return _Card(
        child: SizedBox(
          height: 110,
          child: Center(
            child: Text(
              'Could not load financial data',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
        ),
      );
    }

    final summary = summaryAsync.value!;
    final incomes = incomesAsync.value ?? <IncomeModel>[];

    final now = DateTime.now();
    final currentKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final spent = summary.byMonth
        .where((m) => m.month == currentKey)
        .fold<double>(0, (s, m) => s + m.total);

    final income = incomes.fold<double>(0, (s, e) => s + e.amount);
    final saved = (income - spent).clamp(0.0, double.infinity);
    final savedPct = income > 0 ? (saved / income).clamp(0.0, 1.0) : 0.0;
    final spentPct = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;

    // Latest income entry for sub-label
    final latestIncome = incomes.isNotEmpty ? incomes.first : null;
    final subLabel = latestIncome != null
        ? '${latestIncome.incomeType.displayLabel} · ${DateFormat('MMM d').format(latestIncome.createdAt)}'
        : null;

    final monthLabel = DateFormat('MMMM').format(now);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                '$monthLabel so far',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              if (subLabel != null)
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          // Progress bar: red spent | green saved
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (income == 0) ...[
                    Expanded(child: Container(color: const Color(0xFFE5E7EB))),
                  ] else ...[
                    if (spentPct > 0)
                      Expanded(
                        flex: (spentPct * 1000).round(),
                        child: Container(color: AppColors.danger),
                      ),
                    if (savedPct > 0)
                      Expanded(
                        flex: (savedPct * 1000).round(),
                        child: Container(color: AppColors.success),
                      ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Three-stat row
          Row(
            children: [
              _StatCol(
                dot: const Color(0xFF1A1A2E),
                label: 'INCOME',
                value: '₹${_fmtNum(income.round())}',
                valueColor: context.textPrimary,
              ),
              SizedBox(width: 20),
              _StatCol(
                dot: AppColors.danger,
                label: 'SPENT',
                value: '₹${_fmtNum(spent.round())}',
                valueColor: context.textPrimary,
              ),
              SizedBox(width: 20),
              _StatCol(
                dot: AppColors.success,
                label: 'SAVED',
                value: '₹${_fmtNum(saved.round())}',
                valueColor: AppColors.success,
                subtitle:
                    income > 0 ? '${(savedPct * 100).toStringAsFixed(0)}% of income' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat column ───────────────────────────────────────────────────────────────

class _StatCol extends StatelessWidget {
  const _StatCol({
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
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
