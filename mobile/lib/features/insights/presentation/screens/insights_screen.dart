import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/data/models/income_model.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/budget_list_card.dart';
import '../widgets/category_donut_card.dart';
import '../widgets/daily_spend_chart.dart';
import '../widgets/expense_flow_card.dart';
import '../widgets/income_analysis_card.dart';
import '../widgets/insights_header.dart';
import '../widgets/top_merchants_card.dart';
import '../widgets/total_spend_card.dart';

// ── Shared data models ────────────────────────────────────────────────────────

class InsightsMonth {
  const InsightsMonth(this.year, this.month, this.label);
  final int year;
  final int month;
  final String label;
}

class InsightsData {
  const InsightsData({
    required this.totalSpend,
    required this.prevMonthSpend,
    required this.prevMonthLabel,
    required this.categories,
    required this.dailySpend,
    required this.budgets,
    required this.merchants,
    required this.aiInsights,
  });

  final int totalSpend;
  final int prevMonthSpend;
  final String prevMonthLabel;
  final List<CategorySlice> categories;
  final List<double> dailySpend;
  final List<BudgetItem> budgets;
  final List<MerchantItem> merchants;
  final List<AiInsight> aiInsights;
}

class IncomeData {
  const IncomeData({
    required this.totalIncome,
    required this.prevIncome,
    required this.prevLabel,
    required this.byType,
    required this.sources,
  });

  final int totalIncome;
  final int prevIncome;
  final String prevLabel;
  final List<CategorySlice> byType;
  final List<MerchantItem> sources;
}

class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final int amount;
  final Color color;
}

class BudgetItem {
  const BudgetItem({
    required this.category,
    required this.spent,
    required this.limit,
    required this.color,
  });
  final String category;
  final int spent;
  final int limit;
  final Color color;
}

class MerchantItem {
  const MerchantItem({
    required this.name,
    required this.txCount,
    required this.amount,
  });
  final String name;
  final int txCount;
  final int amount;
}

class AiInsight {
  const AiInsight({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

enum AnalysisMode { expense, income }

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late DateTime _selectedMonth;
  AnalysisMode _mode = AnalysisMode.expense;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<InsightsMonth> _buildMonthList() {
    return List.generate(6, (i) {
      final d = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - i,
      );
      return InsightsMonth(
        d.year,
        d.month,
        DateFormat('MMMM yyyy').format(d),
      );
    });
  }

  InsightsMonth _toInsightsMonth(DateTime dt) => InsightsMonth(
        dt.year,
        dt.month,
        DateFormat('MMMM yyyy').format(dt),
      );

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(expenseSummaryProvider);
    final expensesAsync = ref.watch(expensesForMonthProvider(_selectedMonth));
    final budgetsAsync = ref.watch(budgetsForMonthProvider(_selectedMonth));

    final months = _buildMonthList();
    final currentInsightsMonth = _toInsightsMonth(_selectedMonth);

    final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);
    final prevMonthDt =
        DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final prevKey = DateFormat('yyyy-MM').format(prevMonthDt);

    return Scaffold(
      backgroundColor: context.bgBase,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            InsightsHeader(
              selected: currentInsightsMonth,
              months: months,
              onSelect: (m) => setState(
                () => _selectedMonth = DateTime(m.year, m.month),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _ModeToggle(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 16),
                  if (_mode == AnalysisMode.expense)
                    _buildExpenseContent(
                      summaryAsync: summaryAsync,
                      expensesAsync: expensesAsync,
                      budgetsAsync: budgetsAsync,
                      monthKey: monthKey,
                      prevKey: prevKey,
                      prevMonthDt: prevMonthDt,
                      currentInsightsMonth: currentInsightsMonth,
                    )
                  else
                    _buildIncomeContent(prevMonthDt: prevMonthDt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseContent({
    required AsyncValue summaryAsync,
    required AsyncValue<List<ExpenseModel>> expensesAsync,
    required AsyncValue budgetsAsync,
    required String monthKey,
    required String prevKey,
    required DateTime prevMonthDt,
    required InsightsMonth currentInsightsMonth,
  }) {
    final data = _buildData(
      summaryAsync: summaryAsync,
      expensesAsync: expensesAsync,
      budgetsAsync: budgetsAsync,
      monthKey: monthKey,
      prevKey: prevKey,
      prevMonthDt: prevMonthDt,
    );

    if (data.totalSpend == 0 && data.categories.isEmpty) {
      return _EmptyAnalysis(
        message: 'Add some expenses to see your spending insights.',
      );
    }

    return Column(
      children: [
        TotalSpendCard(data: data),
        SizedBox(height: 14),
        CategoryDonutCard(data: data),
        SizedBox(height: 14),
        DailySpendChart(data: data, month: currentInsightsMonth),
        SizedBox(height: 14),
        ExpenseFlowCard(data: data, month: currentInsightsMonth),
        SizedBox(height: 14),
        BudgetListCard(data: data),
        SizedBox(height: 14),
        TopMerchantsCard(data: data),
        if (data.aiInsights.isNotEmpty) ...[
          SizedBox(height: 14),
          ...data.aiInsights.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AiInsightCard(insight: i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIncomeContent({required DateTime prevMonthDt}) {
    final incomesAsync = ref.watch(incomesForMonthProvider(_selectedMonth));
    final prevIncomesAsync = ref.watch(incomesForMonthProvider(prevMonthDt));

    final data = _buildIncomeData(
      incomes: incomesAsync.valueOrNull ?? const [],
      prevIncomes: prevIncomesAsync.valueOrNull ?? const [],
      prevMonthDt: prevMonthDt,
    );

    if (data.totalIncome == 0 && data.byType.isEmpty) {
      return _EmptyAnalysis(
        message: 'Add some income to see where your money comes from.',
      );
    }

    return Column(
      children: [
        IncomeTotalCard(data: data),
        SizedBox(height: 14),
        IncomeBreakdownCard(data: data),
        SizedBox(height: 14),
        IncomeSourcesCard(data: data),
      ],
    );
  }

  IncomeData _buildIncomeData({
    required List<IncomeModel> incomes,
    required List<IncomeModel> prevIncomes,
    required DateTime prevMonthDt,
  }) {
    final totalIncome =
        incomes.fold<double>(0, (s, e) => s + e.amount).round();
    final prevIncome =
        prevIncomes.fold<double>(0, (s, e) => s + e.amount).round();

    // Group by income type for the breakdown bars.
    final byTypeMap = <IncomeType, double>{};
    for (final e in incomes) {
      byTypeMap[e.incomeType] = (byTypeMap[e.incomeType] ?? 0) + e.amount;
    }
    final byType = byTypeMap.entries
        .map(
          (e) => CategorySlice(
            label: e.key.displayLabel,
            amount: e.value.round(),
            color: _incomeTypeColor(e.key),
          ),
        )
        .where((s) => s.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Top sources — group by description (fallback to the type label).
    final sourceMap = <String, (int, double)>{};
    for (final e in incomes) {
      final name = (e.description?.trim().isEmpty ?? true)
          ? e.incomeType.displayLabel
          : e.description!.trim();
      final (count, total) = sourceMap[name] ?? (0, 0.0);
      sourceMap[name] = (count + 1, total + e.amount);
    }
    final sources = sourceMap.entries
        .map(
          (e) => MerchantItem(
            name: e.key,
            txCount: e.value.$1,
            amount: e.value.$2.round(),
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return IncomeData(
      totalIncome: totalIncome,
      prevIncome: prevIncome,
      prevLabel: DateFormat('MMMM').format(prevMonthDt),
      byType: byType,
      sources: sources.take(5).toList(),
    );
  }

  Color _incomeTypeColor(IncomeType type) => switch (type) {
        IncomeType.salary => AppColors.success,
        IncomeType.freelance => AppColors.info,
        IncomeType.investment => AppColors.categoryShopping,
        IncomeType.reward => AppColors.warning,
        IncomeType.other => AppColors.categoryOther,
      };

  InsightsData _buildData({
    required AsyncValue summaryAsync,
    required AsyncValue<List<ExpenseModel>> expensesAsync,
    required AsyncValue budgetsAsync,
    required String monthKey,
    required String prevKey,
    required DateTime prevMonthDt,
  }) {
    final summary = summaryAsync.valueOrNull;
    final expenses = expensesAsync.valueOrNull ?? <ExpenseModel>[];
    final rawBudgets = budgetsAsync.valueOrNull;

    // Monthly totals from summary
    int totalSpend = 0;
    int prevMonthSpend = 0;
    List<CategorySlice> categories = [];

    if (summary != null) {
      totalSpend = summary.byMonth
          .where((m) => m.month == monthKey)
          .fold<double>(0, (s, m) => s + m.total)
          .round();

      prevMonthSpend = summary.byMonth
          .where((m) => m.month == prevKey)
          .fold<double>(0, (s, m) => s + m.total)
          .round();

      final monthBreakdown = summary.byCategoryPerMonth
          .where((m) => m.month == monthKey)
          .expand((m) => m.categories)
          .toList();

      categories = monthBreakdown
          .map(
            (c) => CategorySlice(
              label: CategoryMapper.label(
                ExpenseCategory.fromServer(c.category),
              ),
              amount: c.total.round(),
              color: AppColors.forCategory(c.category),
            ),
          )
          .where((c) => c.amount > 0)
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
    }

    // Daily spend — group expenses by day-of-month
    final dailySpend = List<double>.filled(31, 0.0);
    for (final e in expenses) {
      final day = e.createdAt.day;
      if (day >= 1 && day <= 31) dailySpend[day - 1] += e.amount;
    }

    // Top merchants — group by description
    final merchantMap = <String, (int, double)>{};
    for (final e in expenses) {
      final name = e.description?.trim().isEmpty ?? true
          ? CategoryMapper.label(e.category)
          : e.description!.trim();
      final (count, total) = merchantMap[name] ?? (0, 0.0);
      merchantMap[name] = (count + 1, total + e.amount);
    }
    final merchants = merchantMap.entries
        .map(
          (e) => MerchantItem(
            name: e.key,
            txCount: e.value.$1,
            amount: e.value.$2.round(),
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Budgets — merge server budget limits with actual spend from summary
    List<BudgetItem> budgets = [];
    if (rawBudgets != null) {
      final categorySpendMap = <String, double>{};
      if (summary != null) {
        for (final m in summary.byCategoryPerMonth
            .where((m) => m.month == monthKey)) {
          for (final c in m.categories) {
            categorySpendMap[c.category] =
                (categorySpendMap[c.category] ?? 0) + c.total;
          }
        }
      }
      budgets = (rawBudgets as List)
          .map(
            (b) {
              final serverCat = b.category.toServer();
              final spent = categorySpendMap[serverCat] ?? 0.0;
              return BudgetItem(
                category: CategoryMapper.label(b.category),
                spent: spent.round(),
                limit: b.limitAmount.round(),
                color: CategoryMapper.color(b.category),
              );
            },
          )
          .toList();
    }

    return InsightsData(
      totalSpend: totalSpend,
      prevMonthSpend: prevMonthSpend,
      prevMonthLabel: DateFormat('MMMM').format(prevMonthDt),
      categories: categories,
      dailySpend: dailySpend,
      budgets: budgets,
      merchants: merchants.take(5).toList(),
      aiInsights: const [],
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          _segment(context, 'Expenses', AnalysisMode.expense),
          _segment(context, 'Income', AnalysisMode.income),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, AnalysisMode value) {
    final selected = mode == value;
    final activeColor =
        value == AnalysisMode.income ? AppColors.success : AppColors.primary500;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty analysis state ──────────────────────────────────────────────────────

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/illustrations/insight_empty_state.png',
            width: 220,
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
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
