import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

const insightsMonths = [
  InsightsMonth(2026, 5, 'May 2026'),
  InsightsMonth(2026, 4, 'April 2026'),
  InsightsMonth(2026, 3, 'March 2026'),
];

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

// ── Demo data ─────────────────────────────────────────────────────────────────

final _aprilData = InsightsData(
  totalSpend: 42380,
  prevMonthSpend: 37839,
  prevMonthLabel: 'March',
  categories: const [
    CategorySlice(label: 'Food', amount: 8420, color: AppColors.categoryFood),
    CategorySlice(
      label: 'Bills',
      amount: 23999,
      color: AppColors.categoryBills,
    ),
    CategorySlice(
      label: 'Groceries',
      amount: 4120,
      color: AppColors.categoryHealth,
    ),
    CategorySlice(
      label: 'Shopping',
      amount: 3399,
      color: AppColors.categoryShopping,
    ),
    CategorySlice(
      label: 'Transport',
      amount: 1240,
      color: AppColors.categoryTransport,
    ),
    CategorySlice(
      label: 'Entertainment',
      amount: 1202,
      color: AppColors.categoryEntertainment,
    ),
  ],
  dailySpend: [
    320,
    0,
    480,
    210,
    0,
    890,
    150,
    560,
    0,
    1200,
    340,
    210,
    0,
    24620,
    280,
    0,
    410,
    649,
    800,
    560,
    0,
    312,
    175,
    289,
    4599,
    0,
    410,
    3240,
    0,
    342,
  ],
  budgets: const [
    BudgetItem(
      category: 'Food',
      spent: 8420,
      limit: 8000,
      color: AppColors.categoryFood,
    ),
    BudgetItem(
      category: 'Groceries',
      spent: 4120,
      limit: 6000,
      color: AppColors.categoryHealth,
    ),
    BudgetItem(
      category: 'Transport',
      spent: 1240,
      limit: 3000,
      color: AppColors.categoryTransport,
    ),
    BudgetItem(
      category: 'Shopping',
      spent: 3399,
      limit: 5000,
      color: AppColors.categoryShopping,
    ),
    BudgetItem(
      category: 'Entertainment',
      spent: 540,
      limit: 2000,
      color: AppColors.categoryEntertainment,
    ),
  ],
  merchants: const [
    MerchantItem(name: 'Swiggy', txCount: 12, amount: 3840),
    MerchantItem(name: 'Zomato', txCount: 8, amount: 2910),
    MerchantItem(name: 'BigBasket', txCount: 3, amount: 5420),
    MerchantItem(name: 'Uber', txCount: 14, amount: 2180),
    MerchantItem(name: 'Amazon', txCount: 5, amount: 4890),
  ],
  aiInsights: const [
    AiInsight(
      title: 'Weekend spending is 40% higher than weekdays.',
      subtitle: 'Saturdays alone account for ₹9,200 this month.',
    ),
    AiInsight(
      title: 'Swiggy: ₹3,840 across 12 orders.',
      subtitle: "That's up from 8 orders in March.",
    ),
  ],
);

final _mayData = InsightsData(
  totalSpend: 31420,
  prevMonthSpend: 42380,
  prevMonthLabel: 'April',
  categories: const [
    CategorySlice(label: 'Food', amount: 7107, color: AppColors.categoryFood),
    CategorySlice(
      label: 'Bills',
      amount: 23840,
      color: AppColors.categoryBills,
    ),
    CategorySlice(
      label: 'Groceries',
      amount: 6880,
      color: AppColors.categoryHealth,
    ),
    CategorySlice(
      label: 'Shopping',
      amount: 2199,
      color: AppColors.categoryShopping,
    ),
    CategorySlice(
      label: 'Transport',
      amount: 509,
      color: AppColors.categoryTransport,
    ),
    CategorySlice(
      label: 'Entertainment',
      amount: 649,
      color: AppColors.categoryEntertainment,
    ),
  ],
  dailySpend: [
    0,
    0,
    0,
    0,
    2600,
    0,
    0,
    3198,
    0,
    3263,
    0,
    0,
    0,
    22058,
    0,
    0,
    1130,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ],
  budgets: const [
    BudgetItem(
      category: 'Food',
      spent: 7107,
      limit: 8000,
      color: AppColors.categoryFood,
    ),
    BudgetItem(
      category: 'Groceries',
      spent: 6880,
      limit: 6000,
      color: AppColors.categoryHealth,
    ),
    BudgetItem(
      category: 'Transport',
      spent: 509,
      limit: 3000,
      color: AppColors.categoryTransport,
    ),
    BudgetItem(
      category: 'Shopping',
      spent: 2199,
      limit: 5000,
      color: AppColors.categoryShopping,
    ),
    BudgetItem(
      category: 'Entertainment',
      spent: 649,
      limit: 2000,
      color: AppColors.categoryEntertainment,
    ),
  ],
  merchants: const [
    MerchantItem(name: 'DMart', txCount: 2, amount: 3880),
    MerchantItem(name: 'Myntra', txCount: 1, amount: 2199),
    MerchantItem(name: 'Swiggy', txCount: 4, amount: 1312),
    MerchantItem(name: 'Netflix', txCount: 1, amount: 649),
    MerchantItem(name: 'Cult Fit', txCount: 2, amount: 1998),
  ],
  aiInsights: const [
    AiInsight(
      title: 'Groceries over budget by ₹880.',
      subtitle: 'Consider switching to monthly bulk orders.',
    ),
    AiInsight(
      title: 'Bills make up 76% of this month.',
      subtitle: 'Rent (₹22,000) dominates your May spend.',
    ),
  ],
);

final _marchData = InsightsData(
  totalSpend: 37839,
  prevMonthSpend: 34100,
  prevMonthLabel: 'February',
  categories: const [
    CategorySlice(label: 'Food', amount: 7140, color: AppColors.categoryFood),
    CategorySlice(
      label: 'Bills',
      amount: 23540,
      color: AppColors.categoryBills,
    ),
    CategorySlice(
      label: 'Groceries',
      amount: 4890,
      color: AppColors.categoryHealth,
    ),
    CategorySlice(
      label: 'Shopping',
      amount: 1799,
      color: AppColors.categoryShopping,
    ),
    CategorySlice(
      label: 'Health',
      amount: 999,
      color: AppColors.categoryHealth,
    ),
  ],
  dailySpend: [
    0,
    0,
    1540,
    0,
    999,
    0,
    0,
    0,
    0,
    1799,
    0,
    0,
    0,
    22312,
    0,
    0,
    0,
    2890,
    0,
    312,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ],
  budgets: const [
    BudgetItem(
      category: 'Food',
      spent: 7140,
      limit: 8000,
      color: AppColors.categoryFood,
    ),
    BudgetItem(
      category: 'Groceries',
      spent: 4890,
      limit: 6000,
      color: AppColors.categoryHealth,
    ),
    BudgetItem(
      category: 'Transport',
      spent: 0,
      limit: 3000,
      color: AppColors.categoryTransport,
    ),
    BudgetItem(
      category: 'Shopping',
      spent: 1799,
      limit: 5000,
      color: AppColors.categoryShopping,
    ),
    BudgetItem(
      category: 'Entertainment',
      spent: 0,
      limit: 2000,
      color: AppColors.categoryEntertainment,
    ),
  ],
  merchants: const [
    MerchantItem(name: 'BigBasket', txCount: 2, amount: 2890),
    MerchantItem(name: 'Swiggy', txCount: 5, amount: 1560),
    MerchantItem(name: 'Myntra', txCount: 1, amount: 1799),
    MerchantItem(name: 'Cult Fit', txCount: 1, amount: 999),
    MerchantItem(name: 'BESCOM', txCount: 1, amount: 1540),
  ],
  aiInsights: const [
    AiInsight(
      title: 'Great month — under budget across all categories.',
      subtitle: 'Total spend was ₹4,261 less than your combined limits.',
    ),
    AiInsight(
      title: 'No transport expenses recorded.',
      subtitle: 'Did you use your own vehicle this month?',
    ),
  ],
);

InsightsData dataFor(InsightsMonth m) {
  if (m.month == 4) return _aprilData;
  if (m.month == 5) return _mayData;
  return _marchData;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  InsightsMonth _month = insightsMonths[1];

  @override
  Widget build(BuildContext context) {
    final data = dataFor(_month);

    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            InsightsHeader(
              selected: _month,
              months: insightsMonths,
              onSelect: (m) => setState(() => _month = m),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  TotalSpendCard(data: data),
                  const SizedBox(height: 14),
                  CategoryDonutCard(data: data),
                  const SizedBox(height: 14),
                  DailySpendChart(data: data, month: _month),
                  const SizedBox(height: 14),
                  BudgetListCard(data: data),
                  const SizedBox(height: 14),
                  TopMerchantsCard(data: data),
                  const SizedBox(height: 14),
                  ...data.aiInsights.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AiInsightCard(insight: i),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
