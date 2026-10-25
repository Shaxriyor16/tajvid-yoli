import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding bir marta ko'rsatiladi — holat qurilma xotirasida saqlanadi.
class OnboardingStore {
  OnboardingStore._();

  static const String _key = 'onboarding_completed';
  static bool _completed = false;

  static bool get completed => _completed;

  /// Ilova ishga tushganda bir marta chaqiriladi.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_key) ?? false;
  }

  static Future<void> markCompleted() async {
    _completed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
