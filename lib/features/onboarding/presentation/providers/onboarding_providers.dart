import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

const _globalOnboardingKey = 'has_seen_onboarding';
String _userOnboardingKey(String userId) => 'has_seen_onboarding:$userId';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user != null) {
    return preferences.getBool(_userOnboardingKey(user.id)) ?? false;
  }
  return preferences.getBool(_globalOnboardingKey) ?? false;
});

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref);
});

class OnboardingController {
  const OnboardingController(this._ref);

  final Ref _ref;

  Future<void> complete() async {
    final preferences = await _ref.read(sharedPreferencesProvider.future);
    await preferences.setBool(_globalOnboardingKey, true);

    final user = _ref.read(currentUserProvider).asData?.value;
    if (user != null) {
      await preferences.setBool(_userOnboardingKey(user.id), true);
    }

    _ref.invalidate(hasSeenOnboardingProvider);
  }
}
