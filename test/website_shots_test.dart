// Sayt uchun ekran rasmlari: iPhone 16 Pro Max mantiqiy o'lchami (440x956 pt,
// 1320x2868 piksel nisbati), yuqori xavfsiz hudud (Dynamic Island) va pastki
// indikator hududi bilan. Natija: .artifacts/web/*.png
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
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/ai_check/ai_check_screen.dart';
import 'package:tajvid_yoli/features/alphabet/alphabet_screen.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'package:tajvid_yoli/features/auth/login_screen.dart';
import 'package:tajvid_yoli/features/daily_plan/daily_plan_screen.dart';
import 'package:tajvid_yoli/features/harakat/harakat_screen.dart';
import 'package:tajvid_yoli/features/home/home_screen.dart';
import 'package:tajvid_yoli/features/onboarding/onboarding_screen.dart';
import 'package:tajvid_yoli/features/quiz/quiz_screen.dart';
import 'package:tajvid_yoli/features/tajwid_course/tajwid_course_screen.dart';
import 'quran_reliability_test.dart' show MemoryDatabase;
import 'widget_test.dart' show TestAuthBloc;

class _Db extends MemoryDatabase {
  @override
  Future<int> getTodayXp() async => 120;
  @override
  Future<LessonProgressRow?> getLatestLessonProgress() async => null;
  @override
  Future<Set<String>> getCompletedPlanTaskIds(String date) async =>
      {'plan_$date.read_surah', 'plan_$date.quiz'};
  @override
  Future<void> updateLessonProgress(
      String lessonId, double progress, bool completed) async {}
}

typedef _Step = Future<void> Function(WidgetTester tester);

void main() {
  final shots = <String, ({Widget Function() build, bool dark, _Step? act})>{
    'home': (build: () => const HomeScreen(), dark: false, act: null),
    'home-dark': (build: () => const HomeScreen(), dark: true, act: null),
    'alphabet': (build: () => const AlphabetScreen(), dark: false, act: null),
    'tajwid': (build: () => const TajwidCourseScreen(), dark: false, act: null),
    'harakat': (build: () => const HarakatScreen(), dark: false, act: null),
    'quiz': (
      build: () => const QuizScreen(),
      dark: false,
      act: (tester) async {
        await tester.tap(find.text('Alifbo testi'));
      },
    ),
    'ai-check': (build: () => const AiCheckScreen(), dark: false, act: null),
    'daily-plan': (
      build: () => const DailyPlanScreen(),
      dark: false,
      act: null
    ),
    'onboarding': (
      build: () => const OnboardingScreen(),
      dark: false,
      act: null
    ),
    'login': (build: () => const LoginScreen(), dark: false, act: null),
  };

  for (final entry in shots.entries) {
    testWidgets('shot ${entry.key}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (call) async => null);
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
      final auth = TestAuthBloc();
      final boundary = GlobalKey();
      await tester.pumpWidget(RepositoryProvider<AppDatabase>.value(
        value: _Db(),
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
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            theme: entry.value.dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) =>
                RepaintBoundary(key: boundary, child: child),
            home: Builder(
              builder: (ctx) => Container(
                decoration: AppColors.adaptiveBackground(ctx),
                child: entry.value.build(),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await entry.value.act?.call(tester);
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
        final dir = Directory('.artifacts/web')..createSync(recursive: true);
        await File('${dir.path}/${entry.key}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      await config.close();
      await tester.runAsync(auth.close);
      debugDisableShadows = true;
    });
  }
}
