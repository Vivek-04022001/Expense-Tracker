import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/insight_banner.dart';
import '../widgets/monthly_spend_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/today_this_week_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HomeGreetingHeader(),
              SizedBox(height: 18),
              MonthlySpendCard(),
              SizedBox(height: 12),
              TodayThisWeekRow(),
              SizedBox(height: 12),
              BudgetProgressCard(),
              SizedBox(height: 24),
              RecentTransactionsList(),
              SizedBox(height: 14),
              InsightBanner(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
