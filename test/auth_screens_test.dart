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
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'package:tajvid_yoli/features/auth/login_screen.dart';
import 'package:tajvid_yoli/features/auth/register_screen.dart';
import 'package:tajvid_yoli/features/onboarding/onboarding_screen.dart';
import 'quran_reliability_test.dart' show MemoryDatabase;
import 'widget_test.dart' show FakeAuthService;

void main() {
  final screens = <String, Widget>{
    'login': const LoginScreen(),
    'register': const RegisterScreen(),
    'onboarding': const OnboardingScreen(),
  };

  for (final entry in screens.entries) {
    for (final dark in [false, true]) {
      for (final width in [360.0, 800.0]) {
        testWidgets('${entry.key} width=$width dark=$dark', (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = Size(width, 800);
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
            }.entries) {
              final loader = FontLoader(font.key)
                ..addFont(rootBundle.load(font.value));
              await loader.load();
            }
          });
          final config = AppConfigCubit();
          final auth = AuthBloc(FakeAuthService(), MemoryDatabase());
          final boundary = GlobalKey();
          await tester.pumpWidget(BlocProvider<AuthBloc>.value(
            value: auth,
            child: MaterialApp(
              locale: const Locale('uz'),
              supportedLocales: const [Locale('uz')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: RepaintBoundary(key: boundary, child: entry.value),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.runAsync(() => precacheImage(
              const AssetImage('assets/logo.png'), boundary.currentContext!));
          await tester.pump();
          if (width == 360) {
            await tester.runAsync(() async {
              final image = await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final dir = Directory('.artifacts/ui')
                ..createSync(recursive: true);
              await File(
                      '${dir.path}/${entry.key}-${dark ? 'dark' : 'light'}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
          await config.close();
          await tester.runAsync(auth.close);
          debugDisableShadows = true;
        });
      }
    }
  }
}
