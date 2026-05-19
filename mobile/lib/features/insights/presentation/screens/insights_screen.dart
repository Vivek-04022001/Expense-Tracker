import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/budget_list_card.dart';
import '../widgets/category_donut_card.dart';
import '../widgets/daily_spend_chart.dart';
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

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late DateTime _selectedMonth;

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

    InsightsData data = _buildData(
      summaryAsync: summaryAsync,
      expensesAsync: expensesAsync,
      budgetsAsync: budgetsAsync,
      monthKey: monthKey,
      prevKey: prevKey,
      prevMonthDt: prevMonthDt,
    );

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
                  SizedBox(height: 16),
                  TotalSpendCard(data: data),
                  SizedBox(height: 14),
                  CategoryDonutCard(data: data),
                  SizedBox(height: 14),
                  DailySpendChart(data: data, month: currentInsightsMonth),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

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
