import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/core/widgets/answer_option.dart';
import 'package:tajvid_yoli/core/widgets/glass_widgets.dart';
import 'package:tajvid_yoli/features/alphabet/alphabet_screen.dart';
import 'package:tajvid_yoli/features/harakat/harakat_screen.dart';
import 'package:tajvid_yoli/features/quiz/quiz_screen.dart';
import 'package:tajvid_yoli/features/tajwid_course/tajwid_course_screen.dart';
import 'quran_reliability_test.dart' show MemoryDatabase;

class _LearningDb extends MemoryDatabase {
  @override
  Future<void> updateLessonProgress(
      String lessonId, double progress, bool completed) async {}
}

typedef _Step = Future<void> Function(WidgetTester tester);

void main() {
  final screens = <String, ({Widget Function() build, _Step? act})>{
    'alphabet': (build: () => const AlphabetScreen(), act: null),
    'letter-detail': (
      build: () => const LetterDetailScreen(startIndex: 0),
      act: (tester) async {
        await tester.tap(find.byType(AnswerOption).first);
        await tester.pumpAndSettle();
      },
    ),
    'harakat': (build: () => const HarakatScreen(), act: null),
    'quiz': (
      build: () => const QuizScreen(),
      act: (tester) async {
        await tester.tap(find.byType(AnswerOption).first);
        await tester.pumpAndSettle();
      },
    ),
    'tajwid': (build: () => const TajwidCourseScreen(), act: null),
    'tajwid-detail': (
      build: () => const TajwidCourseScreen(),
      act: (tester) async {
        await tester.tap(find.byType(GlassCard).at(0));
        await tester.pumpAndSettle();
      },
    ),
  };

  for (final entry in screens.entries) {
    for (final dark in [false, true]) {
      testWidgets('${entry.key} dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
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
        final boundary = GlobalKey();
        await tester.pumpWidget(Provider<AppDatabase>.value(
          value: _LearningDb(),
          child: MaterialApp(
            locale: const Locale('uz'),
            supportedLocales: const [Locale('uz')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) =>
                RepaintBoundary(key: boundary, child: child),
            home: Builder(
              builder: (ctx) => Container(
                decoration: AppColors.adaptiveBackground(ctx),
                child: entry.value.build(),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        await entry.value.act?.call(tester);
        expect(tester.takeException(), isNull);
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
        debugDisableShadows = true;
      });
    }
  }
}
