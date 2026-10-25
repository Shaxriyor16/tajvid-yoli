import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigState {
  final ThemeMode themeMode;
  final Locale locale;

  AppConfigState({
    required this.themeMode,
    required this.locale,
  });

  AppConfigState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppConfigState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class AppConfigCubit extends Cubit<AppConfigState> {
  static const String _themeKey = 'pref_theme_mode';
  static const String _langKey = 'pref_language';

  AppConfigCubit()
      : super(AppConfigState(
          themeMode: ThemeMode.system,
          locale: const Locale('uz'),
        )) {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final themeMode = themeIndex >= 0 && themeIndex < ThemeMode.values.length
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system;

    final langCode = prefs.getString(_langKey) ?? 'uz';
    final locale =
        Locale(['uz', 'en', 'ar'].contains(langCode) ? langCode : 'uz');

    if (!isClosed) emit(AppConfigState(themeMode: themeMode, locale: locale));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    if (!isClosed) emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
    if (!isClosed) emit(state.copyWith(locale: locale));
  }
}
