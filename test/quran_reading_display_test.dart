import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:tajvid_yoli/core/services/audio_player_service.dart';
import 'package:tajvid_yoli/core/services/quran_service.dart';
import 'package:tajvid_yoli/core/theme/app_theme.dart';
import 'package:tajvid_yoli/features/quran/quran_reader_screen.dart';
import 'package:tajvid_yoli/features/quran/book_reader_screen.dart';
import 'package:tajvid_yoli/features/quran/quran_data.dart' as data;
import 'quran_reliability_test.dart' show MemoryDatabase, FakeApi, rawSurah;

class _Database extends MemoryDatabase {
  @override
  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async => false;
}

class _Audio implements AudioPlayerService {
  @override
  Stream<String?> get currentlyPlayingUrlStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends QuranService {
  @override
  Future<Surah> getSurah(int number) async =>
      Surah(number: 1, name: 'Fotiha', ayahs: [
        Ayah(
            numberInSurah: 1,
            text: 'بِسْمِ اللَّهِ',
            audio: '',
            transliteration: 'Bismillahir rohmanir rohiym',
            translation: 'Tarjima')
      ]);
}

void main() {
  testWidgets('reading is visible under Arabic without expanding translation',
      (tester) async {
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: _Database()),
          Provider<AudioPlayerService>.value(value: _Audio()),
        ],
        child: MaterialApp(
            theme: AppTheme.light,
            home:
                QuranReaderScreen(surahNumber: 1, quranService: _Service()))));
    await tester.pumpAndSettle();
    expect(find.text('Bismillahir rohmanir rohiym'), findsOneWidget);
    expect(find.text('Tarjima'), findsNothing);
    expect(tester.getTopLeft(find.text('Bismillahir rohmanir rohiym')).dy,
        greaterThan(tester.getTopLeft(find.text('بِسْمِ اللَّهِ')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('book pages include their ayahs Latin readings', (tester) async {
    await tester.pumpWidget(Provider<data.QuranRepository>.value(
      value: data.QuranRepository(
          apiService: FakeApi(), database: MemoryDatabase()),
      child: MaterialApp(
          theme: AppTheme.light, home: const BookReaderScreen(surahNumber: 1)),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitobni ochish'));
    await tester.pumpAndSettle();
    expect(find.text('1. Bismillah'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('cached Arabic without reading repairs the missing reading', () async {
    final db = MemoryDatabase()..cache[1] = jsonEncode(rawSurah(1));
    final api = FakeApi();
    final surah =
        await data.QuranRepository(apiService: api, database: db).getSurah(1);
    expect(surah.ayahs.single.transliteration, 'Bismillah');
    expect(api.calls, 0);
    expect(jsonDecode(db.cache[1]!)['_transliterations'], ['Bismillah']);
  });

  test('reader service maps Latin text to its ayah number', () {
    final raw = rawSurah(1);
    final surah = Surah.fromJson([
      raw,
      {
        ...raw,
        'ayahs': [
          {'numberInSurah': 1, 'text': 'Tarjima'}
        ]
      },
      {
        ...raw,
        'edition': {'identifier': 'en.transliteration'},
        'ayahs': [
          {'numberInSurah': 1, 'text': 'Bismillah'}
        ]
      },
    ]);
    expect(surah.ayahs.single.transliteration, 'Bismillah');
    expect(surah.ayahs.single.translation, 'Tarjima');
  });
}
