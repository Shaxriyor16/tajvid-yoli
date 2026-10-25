import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/core/bloc/app_config_cubit.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'package:tajvid_yoli/features/home/home_screen.dart';
import 'quran_reliability_test.dart' show MemoryDatabase;
import 'widget_test.dart' show FakeAuthService;

class HomeDatabase extends MemoryDatabase {
  @override
  Future<int> getTodayXp() async => 120;
  @override
  Future<LessonProgressRow?> getLatestLessonProgress() async => null;
}

void main() {
  for (final width in [360.0, 320.0, 800.0]) {
    for (final dark in [false, true]) {
      testWidgets('home layout $width dark=$dark', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        await tester.runAsync(() async {
          for (final entry in {
            'Inter': 'assets/fonts/Inter.ttf',
            'Chubbo': 'assets/fonts/Chubbo-Bold.ttf',
            'Supreme': 'assets/fonts/Supreme-Regular.ttf',
            'Amiri': 'assets/fonts/Amiri-Regular.ttf',
            'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
            'packages/cupertino_icons/CupertinoIcons':
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
          }.entries) {
            final loader = FontLoader(entry.key)
              ..addFont(rootBundle.load(entry.value));
            await loader.load();
          }
        });
        final config = AppConfigCubit();
        final auth = AuthBloc(FakeAuthService(), HomeDatabase());
        final boundary = GlobalKey();
        await tester.pumpWidget(MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AppDatabase>.value(value: HomeDatabase())
          ],
          child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: auth),
                BlocProvider<AppConfigCubit>.value(value: config),
              ],
              child: MaterialApp(
                  locale: const Locale('uz'),
                  supportedLocales: const [Locale('uz')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate
                  ],
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  home: MediaQuery(
                      data: MediaQueryData(
                          size: Size(width, 1000),
                          textScaler:
                              TextScaler.linear(width == 320 ? 1.5 : 1)),
                      child: RepaintBoundary(
                          key: boundary,
                          child: ColoredBox(
                              color: dark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              child: const HomeScreen()))))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Mashqni boshlash'), findsOneWidget);
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
            final dir = Directory('.artifacts/ui')..createSync(recursive: true);
            await File('${dir.path}/home-${dark ? 'dark' : 'light'}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await config.close();
        await tester.runAsync(auth.close);
        debugDisableShadows = true;
      });
    }
  }
}
