import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../../shared/widgets/category_avatar.dart';
import '../../data/models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../sheets/add_budget_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgetsAsync = ref.watch(budgetListNotifierProvider);
    final spentAsync = ref.watch(spentForBudgetMonthProvider(selectedMonth));

    return Scaffold(
      backgroundColor: context.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              month: selectedMonth,
              onPrev: () {
                final m = selectedMonth;
                ref
                    .read(selectedBudgetMonthProvider.notifier)
                    .setMonth(
                      m.month == 1 ? m.year - 1 : m.year,
                      m.month == 1 ? 12 : m.month - 1,
                    );
              },
              onNext: () {
                final m = selectedMonth;
                ref
                    .read(selectedBudgetMonthProvider.notifier)
                    .setMonth(
                      m.month == 12 ? m.year + 1 : m.year,
                      m.month == 12 ? 1 : m.month + 1,
                    );
              },
              onReset: () {
                final now = DateTime.now();
                ref
                    .read(selectedBudgetMonthProvider.notifier)
                    .setMonth(now.year, now.month);
              },
              onAdd: () => _openAddSheet(context),
            ),
            Expanded(
              child: budgetsAsync.when(
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load budgets',
                    style: TextStyle(color: context.textSecondary),
                  ),
                ),
                data: (budgets) {
                  if (budgets.isEmpty) {
                    return _EmptyState(onAdd: () => _openAddSheet(context));
                  }
                  final spent = spentAsync.valueOrNull ?? {};
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _OverviewCard(budgets: budgets, spent: spent),
                      const SizedBox(height: 16),
                      for (var i = 0; i < budgets.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == budgets.length - 1 ? 0 : 12,
                          ),
                          child: _BudgetCard(
                            budget: budgets[i],
                            spent: spent[budgets[i].category] ?? 0,
                            onDelete: () =>
                                _confirmDelete(context, ref, budgets[i]),
                            onEdit: () => _openEditSheet(context, budgets[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBudgetSheet(),
    );
  }

  Future<void> _openEditSheet(BuildContext context, BudgetModel budget) async {
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetSheet(prefillCategory: budget.category),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete budget?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Remove the ${CategoryMapper.label(budget.category)} budget of ₹${_fmtNum(budget.limitAmount.round())}?',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(budgetListNotifierProvider.notifier)
                  .delete(budget.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onReset,
    required this.onAdd,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = () {
      final now = DateTime.now();
      return month.year == now.year && month.month == now.month;
    }();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: PhosphorIcon(
                  PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                  size: 20,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
          Text(
            'Budgets',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const Spacer(),
          // Month navigator
          _MonthNavBtn(
            icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
            onTap: onPrev,
          ),
          SizedBox(width: 6),
          GestureDetector(
            onTap: isCurrentMonth ? null : onReset,
            child: Text(
              DateFormat('MMM yyyy').format(month),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCurrentMonth
                    ? context.textPrimary
                    : AppColors.primary500,
              ),
            ),
          ),
          SizedBox(width: 6),
          _MonthNavBtn(
            icon: PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            onTap: onNext,
          ),
          SizedBox(width: 12),
          // Add button
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthNavBtn extends StatelessWidget {
  const _MonthNavBtn({required this.icon, required this.onTap});
  final PhosphorIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Center(
          child: PhosphorIcon(icon, size: 14, color: context.textSecondary),
        ),
      ),
    );
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.budgets, required this.spent});

  final List<BudgetModel> budgets;
  final Map<dynamic, double> spent;

  @override
  Widget build(BuildContext context) {
    final totalLimit = budgets.fold<double>(0, (sum, b) => sum + b.limitAmount);
    final totalSpent = budgets.fold<double>(
      0,
      (sum, b) => sum + (spent[b.category] ?? 0),
    );
    final pct = totalLimit > 0 ? totalSpent / totalLimit : 0.0;
    final isOver = totalSpent > totalLimit;
    final remaining = (totalLimit - totalSpent).clamp(0.0, double.infinity);
    final overCount = budgets
        .where((b) => (spent[b.category] ?? 0) > b.limitAmount)
        .length;

    final barColor = isOver
        ? AppColors.danger
        : pct >= 0.75
        ? AppColors.warning
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    Text(
                      'Total spent',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '₹${_fmtNum(totalSpent.round())}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'of ₹${_fmtNum(totalLimit.round())} budgeted',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (overCount > 0)
                _StatusBadge(label: '$overCount over', color: AppColors.danger),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: context.bgSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${(pct * 100).round()}% used',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                isOver
                    ? '₹${_fmtNum((totalSpent - totalLimit).round())} over'
                    : '₹${_fmtNum(remaining.round())} left',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOver ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Budget card ───────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.onDelete,
    required this.onEdit,
  });

  final BudgetModel budget;
  final double spent;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final limit = budget.limitAmount;
    final remaining = (limit - spent).clamp(0.0, double.infinity);
    final pct = limit > 0 ? (spent / limit).clamp(0.0, double.infinity) : 0.0;
    final isOver = spent > limit;
    final isWarning = pct >= 0.75 && !isOver;
    final color = CategoryMapper.color(budget.category);

    final barColor = isOver
        ? AppColors.danger
        : isWarning
        ? AppColors.warning
        : AppColors.success;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: isOver
              ? Border.all(color: AppColors.danger.withValues(alpha: 0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon
                CategoryAvatar(
                  icon: CategoryMapper.icon(budget.category),
                  color: color,
                  size: 40,
                  iconSize: 18,
                  radius: 12,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CategoryMapper.label(budget.category),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        'Limit: ₹${_fmtNum(limit.round())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOver)
                  _StatusBadge(label: 'Over budget', color: AppColors.danger)
                else if (isWarning)
                  _StatusBadge(label: 'Near limit', color: AppColors.warning),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.trash,
                      size: 16,
                      color: context.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: context.bgSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '₹${_fmtNum(spent.round())} spent · ${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  isOver
                      ? '₹${_fmtNum((spent - limit).round())} over'
                      : '₹${_fmtNum(remaining.round())} left',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isOver ? AppColors.danger : context.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/illustrations/no_budget.png',
              width: 180,
              height: 160,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 16),
            Text(
              'No budgets yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Set monthly limits per category to track your spending.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Set a budget',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
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
