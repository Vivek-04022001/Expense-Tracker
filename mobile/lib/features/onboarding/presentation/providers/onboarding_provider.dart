import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

const _kOnboardingSeen = 'onboarding_seen';

@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeen) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeen, true);
    state = const AsyncValue.data(true);
  }
}
