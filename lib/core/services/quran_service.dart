import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranService {
  final String _baseUrl = 'https://api.alquran.cloud/v1';

  /// Tarmoq so'rovi uchun maksimal kutish vaqti — ilova osilib qolmasligi uchun.
  static const Duration _requestTimeout = Duration(seconds: 20);

  Future<Surah> getSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError.value(surahNumber, 'surahNumber',
          'Sura raqami 1..114 oralig\'ida bo\'lishi kerak');
    }

    final response = await http
        .get(
          Uri.parse(
              '$_baseUrl/surah/$surahNumber/editions/quran-uthmani,uz.sodik,en.transliteration'),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes))['data'];
      return Surah.fromJson(data);
    } else {
      throw Exception('Failed to load surah');
    }
  }
}

class Surah {
  final int number;
  final String name;
  final List<Ayah> ayahs;

  Surah({required this.number, required this.name, required this.ayahs});

  factory Surah.fromJson(List<dynamic> json) {
    final quranEdition = json[0];
    final translationEdition = json[1];
    final readingEdition = json.cast<Map<String, dynamic>>().where(
        (edition) => edition['edition']?['identifier'] == 'en.transliteration');
    final readings = <int, String>{
      if (readingEdition.isNotEmpty)
        for (final ayah in readingEdition.first['ayahs'] as List)
          ayah['numberInSurah'] as int: ayah['text'] as String,
    };
    // Tafsir uchun qo'shimcha edition'larni ham olish mumkin

    final List<Ayah> ayahs = [];
    for (int i = 0; i < quranEdition['ayahs'].length; i++) {
      ayahs.add(Ayah(
        numberInSurah: quranEdition['ayahs'][i]['numberInSurah'],
        text: quranEdition['ayahs'][i]['text'],
        audio:
            "https://cdn.islamic.network/quran/audio/128/ar.alafasy/${quranEdition['ayahs'][i]['number']}.mp3",
        translation: translationEdition['ayahs'][i]['text'],
        transliteration: readings[quranEdition['ayahs'][i]['numberInSurah']],
        tafsir: null, // Tafsir manbasi qo'shilsa, shu yerda olinadi
      ));
    }

    return Surah(
      number: quranEdition['number'],
      name: quranEdition['name'],
      ayahs: ayahs,
    );
  }
}

class Ayah {
  final int numberInSurah;
  final String text;
  final String audio;
  final String? translation;
  final String? transliteration;
  final String? tafsir;

  Ayah(
      {required this.numberInSurah,
      required this.text,
      required this.audio,
      this.translation,
      this.transliteration,
      this.tafsir});
}
