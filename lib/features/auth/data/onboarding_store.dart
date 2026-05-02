library;

import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  static const _key = 'has_completed_onboarding';
  final Future<SharedPreferences> Function() _preferencesLoader;

  const OnboardingStore({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  Future<bool> hasCompletedOnboarding() async {
    final preferences = await _preferencesLoader();
    return preferences.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final preferences = await _preferencesLoader();
    await preferences.setBool(_key, true);
  }

  Future<void> reset() async {
    final preferences = await _preferencesLoader();
    await preferences.remove(_key);
  }
}
