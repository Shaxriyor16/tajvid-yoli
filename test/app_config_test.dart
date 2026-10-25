import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/core/bloc/app_config_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('first launch follows system theme', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = AppConfigCubit();
    addTearDown(cubit.close);
    final loaded = await cubit.stream.first;
    expect(loaded.themeMode, ThemeMode.system);
    expect(loaded.locale.languageCode, 'uz');
  });
  test('invalid stored settings fall back safely', () async {
    SharedPreferences.setMockInitialValues({
      'pref_theme_mode': 99,
      'pref_language': 'invalid',
    });
    final cubit = AppConfigCubit();
    addTearDown(cubit.close);
    final loaded = await cubit.stream.first;
    expect(loaded.themeMode, ThemeMode.system);
    expect(loaded.locale.languageCode, 'uz');
  });
}
