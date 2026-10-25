import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:tajvid_yoli/core/services/audio_player_service.dart';
import 'package:tajvid_yoli/core/services/quran_service.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/quran/quran_data.dart' as data;
import 'package:tajvid_yoli/features/quran/quran_reader_screen.dart';
import 'package:tajvid_yoli/features/quran/surah_list_screen.dart';
import 'quran_reliability_test.dart' show MemoryDatabase;

class _Database extends MemoryDatabase {
  @override
  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async =>
      ayahNumber == 2;
}

class _Audio implements AudioPlayerService {
  @override
  Stream<String?> get currentlyPlayingUrlStream =>
      Stream.value('https://audio/1.mp3');
  @override
  Stream<PlayerState> get playerStateStream =>
      Stream.value(PlayerState(true, ProcessingState.ready));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends QuranService {
  @override
  Future<Surah> getSurah(int number) async =>
      Surah(number: 2, name: 'سُورَةُ ٱلْبَقَرَةِ', ayahs: [
        Ayah(
            numberInSurah: 1,
            text: 'الٓمٓ',
            audio: 'https://audio/1.mp3',
            transliteration: 'Alif-Lam-Mim',
            translation: 'Alif, Lam, Mim.'),
        Ayah(
            numberInSurah: 2,
            text:
                'ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ',
            audio: 'https://audio/2.mp3',
            transliteration: 'Zalikal kitabu la raiba fih, hudal lil muttaqin',
            translation: 'This is the Book about which there is no doubt.'),
      ]);
}

class _Repo extends data.QuranRepository {
  _Repo()
      : super(apiService: data.QuranApiService(), database: MemoryDatabase());

  @override
  Future<List<data.Surah>> getSurahList() async => const [
        data.Surah(
            number: 1,
            arabicName: 'سُورَةُ ٱلْفَاتِحَةِ',
            englishName: 'Al-Fatihah',
            revelationType: 'Meccan',
            totalAyahs: 7),
        data.Surah(
            number: 2,
            arabicName: 'سُورَةُ ٱلْبَقَرَةِ',
            englishName: 'Al-Baqarah',
            revelationType: 'Medinan',
            totalAyahs: 286),
        data.Surah(
            number: 3,
            arabicName: 'سُورَةُ آلِ عِمۡرَانَ',
            englishName: 'Ali \'Imran',
            revelationType: 'Medinan',
            totalAyahs: 200),
      ];
}

void main() {
  for (final entry in {
    'surah-list': () => const SurahListScreen(),
    'quran-reader': () =>
        QuranReaderScreen(surahNumber: 2, quranService: _Service()),
  }.entries) {
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
        await tester.pumpWidget(MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: _Database()),
            Provider<AudioPlayerService>.value(value: _Audio()),
            Provider<data.QuranRepository>.value(value: _Repo()),
          ],
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: RepaintBoundary(
              key: boundary,
              child: Builder(
                builder: (ctx) => Container(
                  decoration: AppColors.adaptiveBackground(ctx),
                  child: entry.value(),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
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
