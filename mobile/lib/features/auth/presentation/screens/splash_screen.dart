import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/app_logo.png', width: 80, height: 80),
            SizedBox(height: 16),
            Text(
              'Paisa',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}
