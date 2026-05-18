import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/insight_banner.dart';
import '../widgets/monthly_spend_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/savings_rate_card.dart';
import '../widgets/today_this_week_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final name = authAsync.valueOrNull is AuthAuthenticated
        ? (authAsync.valueOrNull as AuthAuthenticated).user.name
        : '';

    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeGreetingHeader(name: name),
              const SizedBox(height: 18),
              const MonthlySpendCard(),
              const SizedBox(height: 12),
              const SavingsRateCard(),
              const SizedBox(height: 12),
              const TodayThisWeekRow(),
              const SizedBox(height: 24),
              const RecentTransactionsList(),
              const SizedBox(height: 14),
              const InsightBanner(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
