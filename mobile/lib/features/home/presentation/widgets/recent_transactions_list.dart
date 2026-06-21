import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/expense_visual.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../expenses/presentation/screens/expense_detail_screen.dart';
import '../../../income/data/models/income_model.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../income/presentation/screens/income_detail_screen.dart';
import '../../../../shared/widgets/category_avatar.dart';
import '../../../../shared/widgets/shimmer.dart';

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
    this.expense,
    this.income,
  });

  factory _Tx.fromExpense(ExpenseModel e, List<CategoryModel> categories) {
    final visual = ExpenseVisual.of(e, categories);
    final time = DateFormat('h:mm a').format(e.createdAt);
    return _Tx._(
      id: e.id,
      name: e.description ?? visual.label,
      subtitle: '${visual.label} · $time · ${e.paymentMethod.displayLabel}',
      icon: visual.icon,
      iconColor: visual.color,
      amountLabel: '-₹${_fmt(e.amount.round())}',
      amountColor: AppColors.danger,
      createdAt: e.createdAt,
      expense: e,
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
      income: e,
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
  final ExpenseModel? expense;
  final IncomeModel? income;

  void openDetail(BuildContext context) {
    if (expense != null) {
      Navigator.of(context, rootNavigator: true)
          .push(slideFadeRoute(ExpenseDetailScreen(expense: expense!)));
    } else if (income != null) {
      Navigator.of(context, rootNavigator: true)
          .push(slideFadeRoute(IncomeDetailScreen(income: income!)));
    }
  }

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
          const _LoadingShimmer()
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
            ref.watch(categoryListNotifierProvider).valueOrNull ?? const [],
          ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ExpenseModel> expenses,
    List<IncomeModel> incomes,
    List<CategoryModel> categories,
  ) {
    final all = [
      ...expenses.map((e) => _Tx.fromExpense(e, categories)),
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
          indent: 68,
          endIndent: 14,
          color: context.borderSubtle.withValues(alpha: 0.6),
        ),
        itemBuilder: (_, i) => _TransactionTile(tx: recent[i])
            .animate()
            .fadeIn(duration: 300.ms, delay: (50 * i).ms)
            .slideX(begin: 0.06, end: 0, curve: Curves.easeOut),
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
    return GestureDetector(
      onTap: () => tx.openDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          CategoryAvatar(
            icon: tx.icon,
            color: tx.iconColor,
            size: 42,
            iconSize: 19,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  tx.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          // Tinted amount pill — green earns, red spends.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tx.amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tx.amountLabel,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: tx.amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: const [
                ShimmerBox(width: 40, height: 40, shape: BoxShape.circle),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 13, width: 120),
                      SizedBox(height: 6),
                      ShimmerBox(height: 11, width: 80),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                ShimmerBox(height: 14, width: 56),
              ],
            ),
          ),
        ),
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
