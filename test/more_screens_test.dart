import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/ai_check/ai_check_screen.dart';
import 'package:tajvid_yoli/features/alphabet/letter_connections_screen.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'package:tajvid_yoli/features/auth/auth_model.dart';
import 'package:tajvid_yoli/features/bookmarks/bookmarks_screen.dart';
import 'package:tajvid_yoli/features/certificate/certificate_screen.dart';
import 'package:tajvid_yoli/features/daily_plan/daily_plan_screen.dart';
import 'package:tajvid_yoli/features/harakat/word_reading_screen.dart';
import 'package:tajvid_yoli/features/quran/quran_data.dart' as data;
import 'package:tajvid_yoli/features/search/search_screen.dart';
import 'quran_reliability_test.dart' show MemoryDatabase;
import 'widget_test.dart' show TestAuthBloc;

class _Db extends MemoryDatabase {
  @override
  Future<Set<String>> getCompletedPlanTaskIds(String date) async =>
      {'plan_$date.read_surah', 'plan_$date.quiz'};
  @override
  Future<int> getCompletedLessonsCount() async => 5;
  @override
  Stream<List<QuranBookmark>> watchBookmarks() => Stream.value([
        QuranBookmark(
            id: 1, surahNumber: 2, ayahNumber: 255, savedAt: DateTime(2026)),
        QuranBookmark(
            id: 2, surahNumber: 36, ayahNumber: 1, savedAt: DateTime(2026)),
      ]);
}

class _EmptyDb extends _Db {
  @override
  Stream<List<QuranBookmark>> watchBookmarks() => Stream.value([]);
}

class _Repo extends data.QuranRepository {
  _Repo()
      : super(apiService: data.QuranApiService(), database: MemoryDatabase());

  @override
  Future<List<data.Surah>> getSurahList() async => const [
        data.Surah(
            number: 1,
            arabicName: 'الفاتحة',
            englishName: 'Al-Fatihah',
            revelationType: 'Meccan',
            totalAyahs: 7),
      ];
}

void main() {
  final user = UserModel(
      uid: 'u',
      email: 'a@b.c',
      firstName: 'Sattor',
      lastName: 'Karimov',
      provider: 'google');

  final screens = <String, ({Widget Function() build, AppDatabase db})>{
    'word-reading': (build: () => const WordReadingScreen(), db: _Db()),
    'letter-connections': (
      build: () => const LetterConnectionsScreen(),
      db: _Db()
    ),
    'bookmarks': (build: () => const BookmarksScreen(), db: _Db()),
    'bookmarks-empty': (build: () => const BookmarksScreen(), db: _EmptyDb()),
    'search': (build: () => const SearchScreen(), db: _Db()),
    'daily-plan': (build: () => const DailyPlanScreen(), db: _Db()),
    'ai-check': (build: () => const AiCheckScreen(), db: _Db()),
    'certificate': (build: () => const CertificateScreen(), db: _Db()),
  };

  for (final entry in screens.entries) {
    for (final dark in [false, true]) {
      testWidgets('${entry.key} dark=$dark', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('com.llfbandit.record/messages'),
            (call) async => null);
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
        final auth = TestAuthBloc()..setStateForTest(AuthAuthenticated(user));
        final boundary = GlobalKey();
        await tester.pumpWidget(MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AppDatabase>.value(value: entry.value.db),
            RepositoryProvider<data.QuranRepository>.value(value: _Repo()),
          ],
          child: BlocProvider<AuthBloc>.value(
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
        await tester.runAsync(auth.close);
        debugDisableShadows = true;
      });
    }
  }
}
