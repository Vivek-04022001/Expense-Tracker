import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/sync/connectivity_provider.dart';
import 'core/sync/sync_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/reminders/presentation/providers/reminder_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const PaisaApp(),
    ),
  );
}

class PaisaApp extends ConsumerStatefulWidget {
  const PaisaApp({super.key});

  @override
  ConsumerState<PaisaApp> createState() => _PaisaAppState();
}

class _PaisaAppState extends ConsumerState<PaisaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Sync whenever the user becomes authenticated (restored session or login).
    ref.listenManual(
      authNotifierProvider,
      (previous, next) {
        if (next.valueOrNull is AuthAuthenticated) _syncIfAuthed();
      },
      fireImmediately: true,
    );

    // Sync the moment connectivity is restored.
    ref.listenManual(connectivityProvider, (previous, next) {
      final wasOffline = previous?.valueOrNull == false;
      if (wasOffline && next.valueOrNull == true) _syncIfAuthed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sync when the app returns to the foreground.
    if (state == AppLifecycleState.resumed) _syncIfAuthed();
  }

  void _syncIfAuthed() {
    if (ref.read(authNotifierProvider).valueOrNull is AuthAuthenticated) {
      ref.read(syncControllerProvider.notifier).syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Reschedule any persisted reminder on launch.
    ref.watch(reminderProvider);

    // Tapping a reminder opens the expenses tab so the user can log right away.
    ref.read(notificationServiceProvider).onTap = (_) => router.go('/expenses');

    return MaterialApp.router(
      title: 'Paisa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
