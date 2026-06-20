import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/animation/app_motion.dart';
import '../../../../core/animation/pressable_scale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../expenses/presentation/sheets/add_expense_sheet.dart';
import '../../../income/data/models/income_model.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../income/presentation/sheets/add_income_sheet.dart';
import '../widgets/spending_overview_card.dart';
import '../widgets/stats_trend_card.dart';

// ── Range / mode ──────────────────────────────────────────────────────────────

enum AnalysisMode { expense, income }

enum StatsRange { week, month, quarter }

/// A resolved comparison window: the active period plus the matching previous
/// period used for the delta pill.
class _Window {
  const _Window({
    required this.curStart,
    required this.curEnd,
    required this.prevStart,
    required this.prevEnd,
    required this.periodLabel,
    required this.prevShort,
  });

  final DateTime curStart;
  final DateTime curEnd; // exclusive
  final DateTime prevStart;
  final DateTime prevEnd; // exclusive (== curStart)
  final String periodLabel;
  final String prevShort;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  late DateTime _anchor;
  AnalysisMode _mode = AnalysisMode.expense;
  StatsRange _range = StatsRange.month;

  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _mode == AnalysisMode.expense;
    final accent = isExpense ? AppColors.primary500 : AppColors.success;
    final now = DateTime.now();
    final w = _window(_range, _anchor, now);

    // Fetch every month the comparison span touches, then slice client-side.
    final months = _monthsBetween(w.prevStart, w.curEnd);

    List<CategorySlice> slices;
    int total;
    int prevTotal;
    bool loading;

    if (isExpense) {
      final (items, l) = _loadExpenses(months);
      loading = l;
      final cur = items.where((e) => _inRange(e.createdAt, w.curStart, w.curEnd));
      final prev =
          items.where((e) => _inRange(e.createdAt, w.prevStart, w.prevEnd));
      slices = _expenseSlices(cur);
      total = cur.fold<double>(0, (s, e) => s + e.amount).round();
      prevTotal = prev.fold<double>(0, (s, e) => s + e.amount).round();
    } else {
      final (items, l) = _loadIncomes(months);
      loading = l;
      final cur = items.where((e) => _inRange(e.createdAt, w.curStart, w.curEnd));
      final prev =
          items.where((e) => _inRange(e.createdAt, w.prevStart, w.prevEnd));
      slices = _incomeSlices(cur);
      total = cur.fold<double>(0, (s, e) => s + e.amount).round();
      prevTotal = prev.fold<double>(0, (s, e) => s + e.amount).round();
    }

    final trend = isExpense ? _expenseTrend() : _incomeTrend();
    final isEmpty = !loading && total == 0 && slices.isEmpty;

    return Scaffold(
      backgroundColor: context.bgBase,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: accent,
          onRefresh: () async {
            ref.invalidate(expenseSummaryProvider);
            for (final m in months) {
              ref.invalidate(expensesForMonthProvider(m));
              ref.invalidate(incomesForMonthProvider(m));
            }
            await ref.read(expenseSummaryProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onFilter: _openMonthFilter),
                const SizedBox(height: 16),
                _ModeToggle(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: 16),
                _RangePills(
                  range: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
                const SizedBox(height: 18),
                _MonthStrip(
                  anchor: _anchor,
                  onSelect: (d) => setState(() => _anchor = d),
                ),
                const SizedBox(height: 18),
                if (loading && total == 0 && slices.isEmpty)
                  SizedBox(
                    height: 320,
                    child: Center(
                      child: CircularProgressIndicator(color: accent),
                    ),
                  )
                else if (isEmpty)
                  _EmptyAnalysis(
                    message: isExpense
                        ? 'Add some expenses to see your spending breakdown.'
                        : 'Add some income to see where your money comes from.',
                    ctaLabel:
                        isExpense ? 'Add your first expense' : 'Add income',
                    accent: accent,
                    onAdd: () => _openAddSheet(isExpense: isExpense),
                  )
                else ...[
                  SpendingOverviewCard(
                    title:
                        '${w.periodLabel} ${isExpense ? 'Spending' : 'Income'}',
                    total: total,
                    prevTotal: prevTotal,
                    prevLabel: w.prevShort,
                    slices: slices,
                    isIncome: !isExpense,
                  ),
                  const SizedBox(height: 14),
                  StatsTrendCard(points: trend, accent: accent),
                  if (slices.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _InsightFooter(
                      top: slices.first,
                      total: total,
                      isExpense: isExpense,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  (List<ExpenseModel>, bool) _loadExpenses(List<DateTime> months) {
    final all = <ExpenseModel>[];
    var loading = false;
    for (final m in months) {
      final a = ref.watch(expensesForMonthProvider(m));
      if (a.isLoading) loading = true;
      all.addAll(a.valueOrNull ?? const []);
    }
    return (all, loading);
  }

  (List<IncomeModel>, bool) _loadIncomes(List<DateTime> months) {
    final all = <IncomeModel>[];
    var loading = false;
    for (final m in months) {
      final a = ref.watch(incomesForMonthProvider(m));
      if (a.isLoading) loading = true;
      all.addAll(a.valueOrNull ?? const []);
    }
    return (all, loading);
  }

  List<CategorySlice> _expenseSlices(Iterable<ExpenseModel> items) {
    final map = <ExpenseCategory, double>{};
    for (final e in items) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map.entries
        .map((e) => CategorySlice(
              label: CategoryMapper.label(e.key),
              amount: e.value.round(),
              color: CategoryMapper.color(e.key),
            ))
        .where((s) => s.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<CategorySlice> _incomeSlices(Iterable<IncomeModel> items) {
    final map = <IncomeType, double>{};
    for (final e in items) {
      map[e.incomeType] = (map[e.incomeType] ?? 0) + e.amount;
    }
    return map.entries
        .map((e) => CategorySlice(
              label: e.key.displayLabel,
              amount: e.value.round(),
              color: _incomeTypeColor(e.key),
            ))
        .where((s) => s.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Color _incomeTypeColor(IncomeType type) => switch (type) {
        IncomeType.salary => AppColors.info,
        IncomeType.freelance => AppColors.success,
        IncomeType.investment => AppColors.categoryShopping,
        IncomeType.reward => AppColors.warning,
        IncomeType.other => AppColors.categoryOther,
      };

  /// Trailing six months ending at the anchor, from the cached summary.
  List<TrendPoint> _expenseTrend() {
    final summary = ref.watch(expenseSummaryProvider).valueOrNull;
    final pts = <TrendPoint>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(_anchor.year, _anchor.month - i);
      final key = DateFormat('yyyy-MM').format(d);
      final v = summary?.byMonth
              .where((m) => m.month == key)
              .fold<double>(0, (s, m) => s + m.total) ??
          0;
      pts.add(TrendPoint(_monthsShort[d.month - 1], v));
    }
    return pts;
  }

  List<TrendPoint> _incomeTrend() {
    final pts = <TrendPoint>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(_anchor.year, _anchor.month - i);
      final items = ref.watch(incomesForMonthProvider(d)).valueOrNull ?? const [];
      final v = items.fold<double>(0, (s, e) => s + e.amount);
      pts.add(TrendPoint(_monthsShort[d.month - 1], v));
    }
    return pts;
  }

  // ── Window maths ──────────────────────────────────────────────────────────────

  _Window _window(StatsRange r, DateTime anchor, DateTime now) {
    switch (r) {
      case StatsRange.month:
        final cs = DateTime(anchor.year, anchor.month, 1);
        final ce = DateTime(anchor.year, anchor.month + 1, 1);
        final ps = DateTime(anchor.year, anchor.month - 1, 1);
        final prevMonth = DateTime(anchor.year, anchor.month - 1);
        return _Window(
          curStart: cs,
          curEnd: ce,
          prevStart: ps,
          prevEnd: cs,
          periodLabel: _monthsFull[anchor.month - 1],
          prevShort: _monthsShort[prevMonth.month - 1],
        );
      case StatsRange.quarter:
        final q = (anchor.month - 1) ~/ 3;
        final qStart = q * 3 + 1;
        final cs = DateTime(anchor.year, qStart, 1);
        final ce = DateTime(anchor.year, qStart + 3, 1);
        final ps = DateTime(anchor.year, qStart - 3, 1);
        return _Window(
          curStart: cs,
          curEnd: ce,
          prevStart: ps,
          prevEnd: cs,
          periodLabel: 'Q${q + 1} ${anchor.year}',
          prevShort: 'last qtr',
        );
      case StatsRange.week:
        final inCurrentMonth =
            anchor.year == now.year && anchor.month == now.month;
        final ref = inCurrentMonth
            ? now
            : DateTime(anchor.year, anchor.month + 1, 0); // last day of month
        final refDate = DateTime(ref.year, ref.month, ref.day);
        final ws = refDate.subtract(Duration(days: refDate.weekday - 1));
        final cs = DateTime(ws.year, ws.month, ws.day);
        final ce = cs.add(const Duration(days: 7));
        final ps = cs.subtract(const Duration(days: 7));
        final label = inCurrentMonth
            ? 'This Week'
            : 'Week of ${cs.day} ${_monthsShort[cs.month - 1]}';
        return _Window(
          curStart: cs,
          curEnd: ce,
          prevStart: ps,
          prevEnd: cs,
          periodLabel: label,
          prevShort: 'last wk',
        );
    }
  }

  /// Every month (day-1 DateTimes) overlapping [start, endExclusive).
  List<DateTime> _monthsBetween(DateTime start, DateTime endExclusive) {
    final months = <DateTime>[];
    final lastInclusive = endExclusive.subtract(const Duration(days: 1));
    var d = DateTime(start.year, start.month);
    final last = DateTime(lastInclusive.year, lastInclusive.month);
    while (!d.isAfter(last)) {
      months.add(d);
      d = DateTime(d.year, d.month + 1);
    }
    return months;
  }

  bool _inRange(DateTime t, DateTime start, DateTime endExclusive) =>
      !t.isBefore(start) && t.isBefore(endExclusive);

  // ── Sheets ────────────────────────────────────────────────────────────────────

  Future<void> _openAddSheet({required bool isExpense}) async {
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          isExpense ? const AddExpenseSheet() : const AddIncomeSheet(),
    );
  }

  void _openMonthFilter() {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jump to month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...months.map((m) {
              final selected =
                  m.month == _anchor.month && m.year == _anchor.year;
              return PressableScale(
                onTap: () {
                  setState(() => _anchor = DateTime(m.year, m.month));
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary500.withValues(alpha: 0.12)
                        : context.bgSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(m),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary500
                              : context.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        PhosphorIcon(
                          PhosphorIcons.check(PhosphorIconsStyle.bold),
                          size: 16,
                          color: AppColors.primary500,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onFilter});
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Statistics',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        PressableScale(
          onTap: onFilter,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: context.borderSubtle),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.slidersHorizontal(),
                size: 18,
                color: context.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final AnalysisMode mode;
  final ValueChanged<AnalysisMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isIncome = mode == AnalysisMode.income;
    final pillColor = isIncome ? AppColors.success : AppColors.primary500;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: AppMotion.base,
                curve: AppMotion.entrance,
                alignment:
                    isIncome ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.entrance,
                  width: pillWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  _segment(context, 'Expenses', AnalysisMode.expense),
                  _segment(context, 'Income', AnalysisMode.income),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(BuildContext context, String label, AnalysisMode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.base,
            curve: AppMotion.entrance,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.textSecondary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ── Range pills ───────────────────────────────────────────────────────────────

class _RangePills extends StatelessWidget {
  const _RangePills({required this.range, required this.onChanged});
  final StatsRange range;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in StatsRange.values) ...[
          _pill(context, r),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _pill(BuildContext context, StatsRange r) {
    final selected = r == range;
    final label = switch (r) {
      StatsRange.week => 'Week',
      StatsRange.month => 'Month',
      StatsRange.quarter => 'Quarter',
    };
    return GestureDetector(
      onTap: () => onChanged(r),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary500 : context.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary500 : context.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Month strip ───────────────────────────────────────────────────────────────

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({required this.anchor, required this.onSelect});
  final DateTime anchor;
  final ValueChanged<DateTime> onSelect;

  static const _short = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final items =
        List.generate(5, (i) => DateTime(anchor.year, anchor.month - 2 + i));
    return Row(
      children: items.map((d) {
        final selected = d.month == anchor.month && d.year == anchor.year;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(DateTime(d.year, d.month)),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                curve: AppMotion.entrance,
                style: TextStyle(
                  fontSize: selected ? 22 : 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? context.textPrimary : context.textTertiary,
                  letterSpacing: selected ? -0.5 : 0,
                ),
                child: Text(_short[d.month - 1]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Insight footer ────────────────────────────────────────────────────────────

class _InsightFooter extends StatelessWidget {
  const _InsightFooter({
    required this.top,
    required this.total,
    required this.isExpense,
  });

  final CategorySlice top;
  final int total;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (top.amount / total * 100).round() : 0;
    final text = isExpense
        ? '${top.label} is your top expense — ₹${_grp(top.amount)}, $pct% of spending'
        : '${top.label} is your biggest source — ₹${_grp(top.amount)}, $pct% of income';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: context.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty analysis state ──────────────────────────────────────────────────────

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({
    required this.message,
    this.ctaLabel,
    this.onAdd,
    this.accent = AppColors.primary500,
  });

  final String message;
  final String? ctaLabel;
  final VoidCallback? onAdd;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/illustrations/insight_empty_state.png',
              width: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'No data yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: reduce
                  ? Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    )
                  : AnimatedTextKit(
                      key: ValueKey(message),
                      isRepeatingAnimation: false,
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          message,
                          textAlign: TextAlign.center,
                          speed: const Duration(milliseconds: 28),
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: context.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
            if (ctaLabel != null && onAdd != null) ...[
              const SizedBox(height: 24),
              PressableScale(
                onTap: onAdd,
                scale: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.plus(PhosphorIconsStyle.bold),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ctaLabel!,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: AppMotion.base, delay: AppMotion.slow),
            ],
          ],
        ),
      ),
    );
  }
}

String _grp(int v) {
  final s = v.abs().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '$buf,$last3';
}
