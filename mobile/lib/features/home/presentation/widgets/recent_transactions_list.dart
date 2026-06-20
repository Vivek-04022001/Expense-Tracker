import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/data/models/income_model.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../../shared/widgets/category_avatar.dart';

// ── Unified transaction entry ─────────────────────────────────────────────────

class _Tx {
  const _Tx._({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.amountLabel,
    required this.amountColor,
    required this.createdAt,
  });

  factory _Tx.fromExpense(ExpenseModel e) {
    final color = CategoryMapper.color(e.category);
    final label = CategoryMapper.label(e.category);
    final time = DateFormat('h:mm a').format(e.createdAt);
    return _Tx._(
      id: e.id,
      name: e.description ?? label,
      subtitle: '$label · $time · ${e.paymentMethod.displayLabel}',
      icon: CategoryMapper.icon(e.category),
      iconColor: color,
      amountLabel: '-₹${_fmt(e.amount.round())}',
      amountColor: AppColors.danger,
      createdAt: e.createdAt,
    );
  }

  factory _Tx.fromIncome(IncomeModel e) {
    final time = DateFormat('h:mm a').format(e.createdAt);
    return _Tx._(
      id: e.id,
      name: e.description ?? e.incomeType.displayLabel,
      subtitle: '${e.incomeType.displayLabel} · $time',
      icon: _incomeIcon(e.incomeType),
      iconColor: AppColors.success,
      amountLabel: '+₹${_fmt(e.amount.round())}',
      amountColor: AppColors.success,
      createdAt: e.createdAt,
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final PhosphorIconData icon;
  final Color iconColor;
  final String amountLabel;
  final Color amountColor;
  final DateTime createdAt;

  static PhosphorIconData _incomeIcon(IncomeType t) => switch (t) {
        IncomeType.salary => PhosphorIcons.briefcase(),
        IncomeType.freelance => PhosphorIcons.laptop(),
        IncomeType.investment => PhosphorIcons.chartLineUp(),
        IncomeType.reward => PhosphorIcons.gift(),
        IncomeType.other => PhosphorIcons.dotsThree(),
      };
}

// ── Widget ────────────────────────────────────────────────────────────────────

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(currentMonthExpensesProvider);
    final incomesAsync = ref.watch(currentMonthIncomesProvider);

    final isLoading = expensesAsync.isLoading || incomesAsync.isLoading;
    final hasError = expensesAsync.hasError || incomesAsync.hasError;

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Recent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/expenses'),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (isLoading)
          SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasError)
          SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Could not load transactions',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          )
        else
          _buildList(
            context,
            expensesAsync.value ?? [],
            incomesAsync.value ?? [],
          ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<ExpenseModel> expenses, List<IncomeModel> incomes) {
    final all = [
      ...expenses.map(_Tx.fromExpense),
      ...incomes.map(_Tx.fromIncome),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recent = all.take(5).toList();

    if (recent.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No transactions this month',
            style: TextStyle(color: context.textSecondary),
          ),
        ),
      );
    }

    return Container(
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
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recent.length,
        separatorBuilder: (context, __) => Divider(
          height: 1,
          indent: 60,
          color: context.borderSubtle,
        ),
        itemBuilder: (_, i) => _TransactionTile(tx: recent[i]),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final _Tx tx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CategoryAvatar(
            icon: tx.icon,
            color: tx.iconColor,
            size: 40,
            iconSize: 18,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  tx.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            tx.amountLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tx.amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(int v) {
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
