import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/ambient_corner_light.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/monthly_spend_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/today_this_week_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final name = authAsync.valueOrNull is AuthAuthenticated
        ? (authAsync.valueOrNull as AuthAuthenticated).user.name
        : '';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.bgBase,
      body: Stack(
        children: [
          // Fixed atmospheric glow raking down from the top-right corner.
          // Stays put while the content scrolls beneath it. Dark theme only.
          if (isDark) const Positioned.fill(child: AmbientCornerLight()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeGreetingHeader(name: name),
                  SizedBox(height: 18),
                  const MonthlySpendCard(),
                  SizedBox(height: 12),
                  const TodayThisWeekRow(),
                  SizedBox(height: 24),
                  const RecentTransactionsList(),
                  SizedBox(height: 102),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
