import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/savings/presentation/screens/savings_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/navigation/presentation/screens/shell_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'transitions.dart';

part 'app_router.g.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
    ref.listen<AsyncValue<bool>>(onboardingNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  const publicRoutes = ['/splash', '/login', '/register', '/onboarding'];
  const authScreens = ['/login', '/register'];

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final asyncAuth = ref.read(authNotifierProvider);
      final asyncOnboarding = ref.read(onboardingNotifierProvider);
      final location = state.matchedLocation;

      if (asyncAuth.isLoading || asyncOnboarding.isLoading) {
        return location == '/splash' ? null : '/splash';
      }
      if (asyncAuth.hasError) return '/login';

      final authState = asyncAuth.value!;
      final onboardingSeen = asyncOnboarding.valueOrNull ?? false;

      if (authState is AuthInitial) {
        return location == '/splash' ? null : '/splash';
      }
      if (authState is AuthAuthenticated) {
        // Once a user has authenticated, onboarding is considered seen for
        // good, so it never reappears (e.g. after a future logout).
        if (!onboardingSeen) {
          Future.microtask(
            () => ref.read(onboardingNotifierProvider.notifier).markSeen(),
          );
        }
        if (publicRoutes.contains(location)) return '/home';
        return null;
      }
      // AuthUnauthenticated
      if (!onboardingSeen) {
        return location == '/onboarding' ? null : '/onboarding';
      }
      if (authScreens.contains(location)) return null;
      return '/login';
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/budgets',
        pageBuilder: (context, state) =>
            slideFadePage(state: state, child: const BudgetsScreen()),
      ),
      GoRoute(
        path: '/savings',
        pageBuilder: (context, state) =>
            slideFadePage(state: state, child: const SavingsScreen()),
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
}
