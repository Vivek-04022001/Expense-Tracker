import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../budgets/data/models/budget_model.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/data/models/expense_summary_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/data/models/income_model.dart';
import '../../../income/presentation/providers/income_provider.dart';

// ── Data ─────────────────────────────────────────────────────────────────────

class _Slice {
  const _Slice({
    required this.label,
    required this.amount,
    required this.color,
    this.budget,
  });
  final String label;
  final double amount;
  final Color color;
  final double? budget;

  bool get hasBudget => budget != null && budget! > 0;
  bool get isOverBudget => hasBudget && amount > budget!;
  int? get budgetPct =>
      hasBudget ? (amount / budget! * 100).round() : null;
}

final _incomesForMonthProvider = FutureProvider.autoDispose
    .family<List<IncomeModel>, DateTime>((ref, month) async {
  final repo = ref.watch(incomeRepositoryProvider);
  final from = DateTime(month.year, month.month);
  final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  return repo.getIncomes(from: from, to: to);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _periodIdx = 1;
  late DateTime _month;
  final _now = DateTime.now();

  int get _tabIdx => _tabController.index;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _month = DateTime(_now.year, _now.month);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(_now.year, _now.month))) {
      setState(() => _month = next);
    }
  }

  bool get _canGoNext =>
      !DateTime(_month.year, _month.month + 1)
          .isAfter(DateTime(_now.year, _now.month));

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _fmtCompact(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toInt()}';
  }

  List<_Slice> _expenseSlices(
    AsyncValue<ExpenseSummaryModel> async,
    AsyncValue<List<BudgetModel>> budgetsAsync,
  ) {
    final summary = async.valueOrNull;
    if (summary == null) return [];
    final key = DateFormat('yyyy-MM').format(_month);

    final budgetByLabel = <String, double>{};
    for (final b in budgetsAsync.valueOrNull ?? const <BudgetModel>[]) {
      budgetByLabel[CategoryMapper.label(b.category)] = b.limitAmount;
    }

    return summary.byCategoryPerMonth
        .where((m) => m.month == key)
        .expand((m) => m.categories)
        .where((c) => c.total > 0)
        .map((c) {
          final label =
              CategoryMapper.label(ExpenseCategory.fromServer(c.category));
          return _Slice(
            label: label,
            amount: c.total,
            color: AppColors.forCategory(c.category),
            budget: budgetByLabel[label],
          );
        })
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<_Slice> _incomeSlices(AsyncValue<List<IncomeModel>> async) {
    final incomes = async.valueOrNull ?? [];
    final map = <IncomeType, double>{};
    for (final i in incomes) {
      map[i.incomeType] = (map[i.incomeType] ?? 0) + i.amount;
    }
    return map.entries
        .where((e) => e.value > 0)
        .map((e) => _Slice(
              label: e.key.displayLabel,
              amount: e.value,
              color: _incomeColor(e.key),
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static Color _incomeColor(IncomeType t) => switch (t) {
        IncomeType.salary => AppColors.primary500,
        IncomeType.freelance => const Color(0xFFB66BFF),
        IncomeType.investment => AppColors.success,
        IncomeType.reward => AppColors.warning,
        IncomeType.other => AppColors.lightTextTertiary,
      };

  String get _chartKey =>
      '${_tabIdx}_${_month.year}_${_month.month}';

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(expenseSummaryProvider);
    final incomesAsync = ref.watch(_incomesForMonthProvider(_month));
    final budgetsAsync = ref.watch(budgetsForMonthProvider(_month));

    final slices = _tabIdx == 0
        ? _expenseSlices(summaryAsync, budgetsAsync)
        : _incomeSlices(incomesAsync);
    final total = slices.fold<double>(0, (s, c) => s + c.amount);

    final prevDt = DateTime(_month.year, _month.month - 1);
    final nextDt = DateTime(_month.year, _month.month + 1);

    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.15, curve: Curves.easeOut),
            ),
            const SizedBox(height: 20),
            // ── Scrollable body ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  children: [
                    // Type toggle — same style as Expenses screen
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.lightTextPrimary,
                        unselectedLabelColor: AppColors.lightTextSecondary,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        tabs: const [
                          Tab(text: 'Expenses'),
                          Tab(text: 'Income'),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 60.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 16),
                    // Period pills
                    _PeriodPills(
                      selected: _periodIdx,
                      onSelect: (i) => setState(() => _periodIdx = i),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 120.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 20),
                    // Month navigator
                    _MonthNav(
                      prev: prevDt,
                      current: _month,
                      next: nextDt,
                      canGoNext: _canGoNext,
                      onPrev: _prevMonth,
                      onNext: _nextMonth,
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 160.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOut),
                    const SizedBox(height: 28),
                    // Ring chart + legend — key triggers re-animation on
                    // tab switch or month change
                    Column(
                      key: ValueKey(_chartKey),
                      children: [
                        _RingChart(
                          slices: slices,
                          total: total,
                          fmtCompact: _fmtCompact,
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.88, 0.88),
                              end: const Offset(1, 1),
                              duration: 500.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 28),
                        if (slices.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                            child: _LegendGrid(slices: slices),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // History button
                    _HistoryButton(onTap: () => context.push('/expenses'))
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 400.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period pills ──────────────────────────────────────────────────────────────

class _PeriodPills extends StatelessWidget {
  const _PeriodPills({required this.selected, required this.onSelect});
  final int selected;
  final void Function(int) onSelect;

  static const _labels = ['Week', 'Month', 'Quarter'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_labels.length, (i) {
        final active = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary500 : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: active
                  ? null
                  : Border.all(color: AppColors.lightBorderSubtle),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? Colors.white
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Month navigator ───────────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.prev,
    required this.current,
    required this.next,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime prev, current, next;
  final bool canGoNext;
  final VoidCallback onPrev, onNext;

  static String _fmt(DateTime dt) => DateFormat('MMMM').format(dt);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onPrev,
          child: Text(
            _fmt(prev),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.lightTextTertiary,
            ),
          ),
        ),
        const SizedBox(width: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                      .animate(CurvedAnimation(
                parent: anim,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          ),
          child: Text(
            _fmt(current),
            key: ValueKey(_fmt(current)),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: canGoNext ? onNext : null,
          child: Text(
            _fmt(next),
            style: TextStyle(
              fontSize: 15,
              color: canGoNext
                  ? AppColors.lightTextTertiary
                  : AppColors.lightTextTertiary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ring chart ────────────────────────────────────────────────────────────────

class _RingChart extends StatelessWidget {
  const _RingChart({
    required this.slices,
    required this.total,
    required this.fmtCompact,
  });

  final List<_Slice> slices;
  final double total;
  final String Function(double) fmtCompact;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'No data for this period',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.lightTextTertiary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 72,
              startDegreeOffset: -90,
              sections: slices.map((s) {
                final pct = total > 0 ? (s.amount / total * 100) : 0.0;
                return PieChartSectionData(
                  color: s.color,
                  value: s.amount,
                  radius: 56,
                  title: '',
                  borderSide: s.isOverBudget
                      ? const BorderSide(
                          color: AppColors.danger,
                          width: 2,
                        )
                      : BorderSide.none,
                  badgeWidget: pct >= 6
                      ? _SegmentBadge(
                          pct: pct.round(),
                          budgetPct: s.budgetPct,
                          overBudget: s.isOverBudget,
                        )
                      : null,
                  badgePositionPercentageOffset: 0.55,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fmtCompact(total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── In-segment badge: shows expense % + budget consumption pill ───────────────

class _SegmentBadge extends StatelessWidget {
  const _SegmentBadge({
    required this.pct,
    required this.budgetPct,
    required this.overBudget,
  });

  final int pct;
  final int? budgetPct;
  final bool overBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        if (budgetPct != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 1.5,
            ),
            decoration: BoxDecoration(
              color: overBudget
                  ? AppColors.danger
                  : Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$budgetPct%',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _LegendGrid extends StatelessWidget {
  const _LegendGrid({required this.slices});
  final List<_Slice> slices;

  @override
  Widget build(BuildContext context) {
    final half = (slices.length / 2).ceil();
    final left = slices.take(half).toList();
    final right = slices.skip(half).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              left.length,
              (i) => _LegendItem(slice: left[i])
                  .animate(delay: Duration(milliseconds: 40 * i))
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: 0.35,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              right.length,
              (i) => _LegendItem(slice: right[i])
                  .animate(
                    delay: Duration(milliseconds: 40 * (i + half)),
                  )
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: 0.35,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.slice});
  final _Slice slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: slice.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slice.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtLegendAmt(slice.amount),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                if (slice.hasBudget) ...[
                  const SizedBox(height: 2),
                  Text(
                    'of ${_fmtLegendAmt(slice.budget!)} · ${slice.budgetPct}%',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: slice.isOverBudget
                          ? AppColors.danger
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtLegendAmt(double v) {
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
  return '₹${v.toInt()}';
}

// ── History button ────────────────────────────────────────────────────────────

class _HistoryButton extends StatelessWidget {
  const _HistoryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
        decoration: BoxDecoration(
          border:
              Border.all(color: AppColors.lightBorderSubtle, width: 1.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: const Text(
          'View history',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
