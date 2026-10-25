import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/db/app_database.dart';

class Ayah {
  final int numberInSurah;
  final int globalNumber;
  final int? mushafPageNumber;
  final String arabicText;
  final String? transliteration;

  const Ayah({
    required this.numberInSurah,
    required this.globalNumber,
    this.mushafPageNumber,
    required this.arabicText,
    this.transliteration,
  });

  factory Ayah.fromUthmaniJson(Map<String, dynamic> json) {
    return Ayah(
      numberInSurah: json['numberInSurah'] as int,
      globalNumber: json['number'] as int,
      mushafPageNumber: (json['page'] as num?)?.toInt(),
      arabicText: json['text'] as String,
    );
  }

  Ayah copyWithTransliteration(String? value) {
    return Ayah(
      numberInSurah: numberInSurah,
      globalNumber: globalNumber,
      mushafPageNumber: mushafPageNumber,
      arabicText: arabicText,
      transliteration: value,
    );
  }

  /// Qori tilovati — Islamic Network CDN, global oyat raqami bo'yicha.
  /// Manba: https://alquran.cloud/audio-api (kalitsiz, ochiq).
  String audioUrl({String edition = 'ar.alafasy', int bitrate = 128}) {
    return 'https://cdn.islamic.network/quran/audio/$bitrate/$edition/$globalNumber.mp3';
  }
}

class Surah {
  final int number;
  final String arabicName;
  final String englishName;
  final String revelationType;
  final int totalAyahs;
  final List<Ayah> ayahs;
  final bool isFromCache;

  const Surah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.revelationType,
    required this.totalAyahs,
    this.ayahs = const [],
    this.isFromCache = false,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    final ayahsJson = (json['ayahs'] as List<dynamic>?) ?? const [];
    return Surah(
      number: json['number'] as int,
      arabicName: json['name'] as String,
      englishName: json['englishName'] as String,
      revelationType: json['revelationType'] as String? ?? '',
      totalAyahs: json['numberOfAyahs'] as int? ?? ayahsJson.length,
      ayahs: ayahsJson
          .map((a) => Ayah.fromUthmaniJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuranApiException implements Exception {
  final String message;
  QuranApiException(this.message);
  @override
  String toString() => message;
}

class QuranApiService {
  static const _baseUrl = 'https://api.alquran.cloud/v1';

  /// Barcha 114 sura ro'yxati (nom va oyat soni bilan, matnsiz — tezroq).
  Future<List<Surah>> fetchSurahList() async {
    final uri = Uri.parse('$_baseUrl/surah');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw QuranApiException(
          "Suralar ro'yxati yuklanmadi (${res.statusCode})");
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.map((s) => Surah.fromJson(s as Map<String, dynamic>)).toList();
  }

  /// Bitta suraning xom JSON javobini qaytaradi — buni ham darhol
  /// ko'rsatish uchun (`Surah.fromJson`), ham keshga yozish uchun
  /// ishlatamiz, shunda ikkita alohida "parser" sinxronsizligidan
  /// qochamiz.
  Future<Map<String, dynamic>> fetchSurahRawJson(int number,
      {String edition = 'quran-uthmani'}) async {
    final uri = Uri.parse('$_baseUrl/surah/$number/$edition');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw QuranApiException('$number-sura yuklanmadi (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  /// Bitta suraning to'liq Usmoniy arabcha matni, barcha oyatlari bilan.
  Future<Surah> fetchSurah(int number,
      {String edition = 'quran-uthmani'}) async {
    final data = await fetchSurahRawJson(number, edition: edition);
    return Surah.fromJson(data);
  }

  /// Lotin transliteratsiyasini alohida edition'dan oladi (mavjud bo'lsa).
  ///
  /// DIQQAT: `en.transliteration` identifikatori tekshirilishi kerak —
  /// build qilishdan oldin quyidagi so'rov bilan tasdiqlang:
  /// GET $_baseUrl/edition?language=en&type=transliteration
  /// O'zbekcha transliteratsiya bu xalqaro API'da yo'q — uni alohida,
  /// qori/ustoz tekshiruvidan o'tgan manba sifatida qo'shish kerak
  /// (loyiha hujjatidagi Content QA bosqichi).
  Future<List<String>> fetchTransliterations(int surahNumber,
      {String edition = 'en.transliteration'}) async {
    final uri = Uri.parse('$_baseUrl/surah/$surahNumber/$edition');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final ayahs = (body['data']['ayahs'] as List<dynamic>);
    return ayahs.map((a) => a['text'] as String).toList();
  }
}

/// Offline-first qatlam: har bir muvaffaqiyatli yuklashda xom JSON
/// mahalliy bazaga (`QuranSurahCache`) yoziladi. Internet bo'lmasa yoki
/// so'rov muvaffaqiyatsiz tugasa, oldin ochilgan suralar shu keshdan
/// o'qib beriladi — bu chinakam offline-first, ko'rsatma emas.
class QuranRepository {
  final QuranApiService apiService;
  final AppDatabase database;
  final Map<int, Surah> _memoryCache = {};
  final Map<int, Future<Surah>> _pending = {};
  List<Surah>? _surahListCache;
  Future<List<Surah>>? _pendingList;

  QuranRepository({required this.apiService, required this.database});

  Future<void> _save(int number, Object data) async {
    try {
      await database.cacheSurah(number, jsonEncode(data));
    } catch (_) {
      // A cache write failure must not hide successfully downloaded content.
    }
  }

  Future<dynamic> _read(int number) async {
    try {
      final cached = await database.getCachedSurahJson(number);
      return cached == null ? null : jsonDecode(cached);
    } catch (_) {
      return null;
    }
  }

  Future<List<Surah>> getSurahList() {
    if (_surahListCache != null) return Future.value(_surahListCache!);
    return _pendingList ??= _loadList().whenComplete(() => _pendingList = null);
  }

  Future<List<Surah>> _loadList() async {
    final cached = await _read(0);
    if (cached is List) {
      try {
        final list = cached
            .map((s) => Surah.fromJson(s as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return _surahListCache = list;
      } catch (_) {/* Invalid cache: recover from the network. */}
    }
    final list = await apiService.fetchSurahList();
    _surahListCache = list;
    await _save(
        0,
        list
            .map((s) => {
                  'number': s.number,
                  'name': s.arabicName,
                  'englishName': s.englishName,
                  'revelationType': s.revelationType,
                  'numberOfAyahs': s.totalAyahs,
                })
            .toList());
    return list;
  }

  Future<Surah> getSurah(int number) {
    if (number < 1 || number > 114) {
      return Future.error(ArgumentError.value(number, 'number'));
    }
    final cached = _memoryCache[number];
    if (cached != null &&
        cached.ayahs
            .every((a) => a.transliteration?.trim().isNotEmpty ?? false)) {
      return Future.value(cached);
    }
    return _pending[number] ??= _loadSurah(number).whenComplete(() {
      _pending.remove(number);
    });
  }

  Future<Surah> _loadSurah(int number) async {
    final cached = await _read(number);
    if (cached is Map<String, dynamic>) {
      try {
        final surah = _decode(cached, fromCache: true);
        if (surah.number == number && surah.ayahs.isNotEmpty) {
          if (surah.ayahs
              .any((a) => a.transliteration?.trim().isEmpty ?? true)) {
            final readings = await apiService
                .fetchTransliterations(number)
                .timeout(const Duration(seconds: 5),
                    onTimeout: () => <String>[])
                .catchError((Object _) => <String>[]);
            if (readings.length == surah.ayahs.length &&
                readings.every((text) => text.trim().isNotEmpty)) {
              final repaired = {...cached, '_transliterations': readings};
              await _save(number, repaired);
              return _remember(_decode(repaired, fromCache: true));
            }
          }
          return _remember(surah);
        }
      } catch (_) {/* Invalid cache: recover from the network. */}
    }
    // Optional transliteration starts alongside the Arabic request and cannot
    // keep the reader waiting indefinitely.
    final transliteration = apiService
        .fetchTransliterations(number)
        .timeout(const Duration(seconds: 5), onTimeout: () => <String>[])
        .catchError((Object _) => <String>[]);
    final raw = await apiService.fetchSurahRawJson(number);
    final translit = await transliteration;
    final stored = {...raw, '_transliterations': translit};
    final surah = _decode(stored, fromCache: false);
    await _save(number, stored);
    return _remember(surah);
  }

  Surah _remember(Surah surah) {
    // Bound retained Arabic text on devices with limited memory.
    if (_memoryCache.length >= 12) _memoryCache.remove(_memoryCache.keys.first);
    _memoryCache[surah.number] = surah;
    return surah;
  }

  Surah _decode(Map<String, dynamic> raw, {required bool fromCache}) {
    final surah = Surah.fromJson(raw);
    final translit = raw['_transliterations'] as List? ?? const [];
    return Surah(
      number: surah.number,
      arabicName: surah.arabicName,
      englishName: surah.englishName,
      revelationType: surah.revelationType,
      totalAyahs: surah.totalAyahs,
      isFromCache: fromCache,
      ayahs: [
        for (var i = 0; i < surah.ayahs.length; i++)
          surah.ayahs[i].copyWithTransliteration(
              i < translit.length ? translit[i] as String? : null)
      ],
    );
  }
}
