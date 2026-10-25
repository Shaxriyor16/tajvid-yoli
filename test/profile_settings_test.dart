import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/core/bloc/app_config_cubit.dart';
import 'package:tajvid_yoli/core/services/notification_service.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/auth/auth_model.dart';
import 'package:tajvid_yoli/features/profile/profile_cubit.dart';
import 'package:tajvid_yoli/features/profile/profile_screen.dart';
import 'package:tajvid_yoli/features/settings/settings_screen.dart';

class _Notifications extends NotificationService {
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<({bool enabled, TimeOfDay time})> getReminderSettings() async =>
      (enabled: true, time: const TimeOfDay(hour: 20, minute: 0));
}

void main() {
  final profileState = ProfileState(
    user: UserModel(
      uid: 'u1',
      email: 'sattorov@example.com',
      firstName: 'Sattor',
      lastName: 'Karimov',
      provider: 'google',
    ),
    completedLessons: 24,
    streakDays: 7,
    averageAccuracy: 86,
    certificateCount: 2,
  );

  for (final entry in {
    'profile': (AppConfigCubit c) => ProfileView(state: profileState),
    'settings': (AppConfigCubit c) => const SettingsScreen(),
  }.entries) {
    for (final dark in [false, true]) {
      testWidgets('${entry.key} dark=$dark', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        await tester.runAsync(() async {
          for (final font in {
            'Inter': 'assets/fonts/Inter.ttf',
            'Chubbo': 'assets/fonts/Chubbo-Bold.ttf',
            'Supreme': 'assets/fonts/Supreme-Regular.ttf',
            'Amiri': 'assets/fonts/Amiri-Regular.ttf',
            'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
            'packages/cupertino_icons/CupertinoIcons':
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
          }.entries) {
            final loader = FontLoader(font.key)
              ..addFont(rootBundle.load(font.value));
            await loader.load();
          }
        });
        final config = AppConfigCubit();
        final boundary = GlobalKey();
        await tester.pumpWidget(RepositoryProvider<NotificationService>.value(
          value: _Notifications(),
          child: BlocProvider<AppConfigCubit>.value(
            value: config,
            child: MaterialApp(
              locale: const Locale('uz'),
              supportedLocales: const [Locale('uz')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: RepaintBoundary(
                key: boundary,
                child: Builder(
                  builder: (ctx) => Container(
                    decoration: AppColors.adaptiveBackground(ctx),
                    child: entry.value(config),
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() => precacheImage(
            const AssetImage('assets/logo.png'), boundary.currentContext!));
        await tester.pump();
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('.artifacts/ui')..createSync(recursive: true);
          await File('${dir.path}/${entry.key}-${dark ? 'dark' : 'light'}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox());
        await config.close();
        debugDisableShadows = true;
      });
    }
  }
}
