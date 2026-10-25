import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajvid_yoli/core/db/app_database.dart';
import 'package:tajvid_yoli/features/quran/quran_data.dart';
import 'package:tajvid_yoli/features/quran/quran_reader_cubit.dart';

class MemoryDatabase implements AppDatabase {
  final cache = <int, String>{};
  bool failWrites = false;
  @override
  Future<String?> getCachedSurahJson(int number) async => cache[number];
  @override
  Future<void> cacheSurah(int number, String data) async {
    if (failWrites) throw StateError('disk full');
    cache[number] = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> rawSurah(int n) => {
      'number': n,
      'name': 'سورة',
      'englishName': 'Surah $n',
      'revelationType': 'Meccan',
      'numberOfAyahs': 1,
      'ayahs': [
        {'numberInSurah': 1, 'number': n, 'text': 'بِسْمِ اللَّهِ'}
      ],
    };

class FakeApi extends QuranApiService {
  int calls = 0;
  bool fail = false;
  Completer<Map<String, dynamic>>? pending;
  @override
  Future<Map<String, dynamic>> fetchSurahRawJson(int number,
      {String edition = 'quran-uthmani'}) async {
    calls++;
    if (fail) throw StateError('offline');
    if (pending != null) return pending!.future;
    return rawSurah(number);
  }

  @override
  Future<List<String>> fetchTransliterations(int number,
          {String edition = 'en.transliteration'}) async =>
      ['Bismillah'];
}

void main() {
  test('persistent cache opens offline without a network request', () async {
    final db = MemoryDatabase();
    db.cache[1] = jsonEncode({
      ...rawSurah(1),
      '_transliterations': ['Bismillah']
    });
    final api = FakeApi()..fail = true;
    final surah =
        await QuranRepository(apiService: api, database: db).getSurah(1);
    expect(api.calls, 0);
    expect(surah.isFromCache, isTrue);
    expect(surah.ayahs.single.transliteration, 'Bismillah');
  });
  test('concurrent readers share one network request', () async {
    final api = FakeApi()..pending = Completer<Map<String, dynamic>>();
    final repo = QuranRepository(apiService: api, database: MemoryDatabase());
    final first = repo.getSurah(1);
    final second = repo.getSurah(1);
    await Future<void>.delayed(Duration.zero);
    expect(api.calls, 1);
    api.pending!.complete(rawSurah(1));
    expect(identical(await first, await second), isTrue);
  });
  test('cache write failure does not lose downloaded Quran', () async {
    final db = MemoryDatabase()..failWrites = true;
    final surah =
        await QuranRepository(apiService: FakeApi(), database: db).getSurah(1);
    expect(surah.ayahs, hasLength(1));
  });
  test('corrupt cached content recovers from network', () async {
    final db = MemoryDatabase()..cache[1] = '{invalid';
    final api = FakeApi();
    await QuranRepository(apiService: api, database: db).getSurah(1);
    expect(api.calls, 1);
  });
  test('leaving reader during loading does not emit after close', () async {
    final api = FakeApi()..pending = Completer<Map<String, dynamic>>();
    final cubit = QuranReaderCubit(
        repository:
            QuranRepository(apiService: api, database: MemoryDatabase()));
    final loading = cubit.loadSurah(1);
    await cubit.close();
    api.pending!.complete(rawSurah(1));
    await expectLater(loading, completes);
  });
  test('invalid surah is rejected before any network request', () async {
    final api = FakeApi();
    final repo = QuranRepository(apiService: api, database: MemoryDatabase());
    await expectLater(repo.getSurah(115), throwsArgumentError);
    expect(api.calls, 0);
  });
}
