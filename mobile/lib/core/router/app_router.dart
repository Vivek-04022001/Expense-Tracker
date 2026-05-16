import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

part 'app_router.g.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  const protectedRoutes = ['/dashboard'];
  const publicRoutes = ['/splash', '/login', '/register'];

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final asyncAuth = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      return asyncAuth.when(
        loading: () => location == '/splash' ? null : '/splash',
        error: (_, __) => '/login',
        data: (authState) {
          if (authState is AuthInitial) {
            return location == '/splash' ? null : '/splash';
          }
          if (authState is AuthAuthenticated) {
            if (publicRoutes.contains(location)) return '/dashboard';
            return null;
          }
          // AuthUnauthenticated
          if (protectedRoutes.contains(location)) return '/login';
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
}
