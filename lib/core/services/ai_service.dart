import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'logger_service.dart';

/// Tilovatdan sura/oyatni aniqlash natijasi.
class RecitationMatch {
  final bool found;
  final int? surahNumber;
  final int? ayahNumber;
  final String? surahArabicName;
  final String? surahName;
  final int confidence;
  final String note;

  const RecitationMatch({
    required this.found,
    this.surahNumber,
    this.ayahNumber,
    this.surahArabicName,
    this.surahName,
    this.confidence = 0,
    this.note = '',
  });
}

class AiService {
  // Firebase AI Logic authorizes through the Firebase project; no Gemini key
  // is embedded in the app. App Check protects requests from unauthorized clients.
  static const String _modelName =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.8-flash');
  static const _timeout = Duration(seconds: 45);

  /// Mobil internet orqali yuboriladigan audio uchun oqilona chegara.
  static const int _maxAudioBytes = 3 * 1024 * 1024;

  static bool get isConfigured => Firebase.apps.isNotEmpty;

  late final GenerativeModel _model;
  late final GenerativeModel _pronunciationModel;
  late final GenerativeModel _recitationModel;

  AiService() {
    final ai = FirebaseAI.googleAI();
    _model = ai.generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        maxOutputTokens: 4096,
      ),
    );
    _pronunciationModel = ai.generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(properties: {
          'transcription': Schema.string(),
          'score': Schema.integer(),
          'feedback': Schema.string(),
        }),
      ),
    );
    _recitationModel = ai.generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(properties: {
          'found': Schema.boolean(),
          'surah_number': Schema.integer(nullable: true),
          'ayah_number': Schema.integer(nullable: true),
          'surah_name_arabic': Schema.string(),
          'surah_name': Schema.string(),
          'confidence': Schema.integer(),
          'note': Schema.string(),
        }),
      ),
    );
  }

  Future<String> checkPronunciation(String audioPath, String targetText) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        return _errorJson('Audio fayl topilmadi.');
      }
      if (await file.length() > _maxAudioBytes) {
        return _errorJson('Audio juda uzun. Qisqaroq yozib oling.');
      }
      final audioBytes = await file.readAsBytes();
      if (audioBytes.isEmpty) {
        return _errorJson('Audio yozuvi bo‘sh. Qayta yozib oling.');
      }
      final prompt = [
        Content.multi([
          TextPart(
              "Men Tajvid o'rganyapman. Quyidagi arabcha matnni o'qidim: \"$targetText\". "
              'Faqat audioda aniq eshitilgan so‘zlarni yozing; noaniq joylarni '
              'Qur’onni yoddan davom ettirib to‘ldirmang. '
              'transcription — eshitilgan arabcha matn (harakatlar bilan), '
              'score — eshitilgan so‘zlar mosligining 0 dan 100 gacha taxminiy bali, '
              "feedback — o'zbek tilida qisqa tahlil va maslahat."),
          InlineDataPart('audio/m4a', audioBytes),
        ])
      ];

      final response =
          await _pronunciationModel.generateContent(prompt).timeout(_timeout);
      final data =
          jsonDecode(_extractJson(response.text ?? '')) as Map<String, dynamic>;
      if (data['score'] is! num ||
          data['transcription'] is! String ||
          data['feedback'] is! String ||
          (data['transcription'] as String).trim().isEmpty) {
        return _errorJson('Ovoz aniq eshitilmadi. Qayta yozib oling.');
      }
      data['score'] = _wordMatchScore(
        targetText,
        data['transcription'] as String,
      );
      return jsonEncode(data);
    } on FirebaseAIException catch (e, s) {
      AppLogger.e('Firebase AI Logic xatosi', error: e, stackTrace: s);
      return _errorJson(_aiLogicError(e));
    } catch (e, s) {
      AppLogger.e('AI tahlilida xatolik', error: e, stackTrace: s);
      return _errorJson('Tizimda xatolik yuz berdi. Internetni tekshiring.');
    }
  }

  /// Foydalanuvchi tilovatini tinglab, qaysi sura va oyat ekanligini aniqlaydi.
  Future<RecitationMatch> identifyRecitation(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        return const RecitationMatch(
            found: false, note: 'Audio fayl topilmadi.');
      }
      if (await file.length() > _maxAudioBytes) {
        return const RecitationMatch(
            found: false, note: 'Audio juda uzun. Qisqaroq yozib oling.');
      }
      final audioBytes = await file.readAsBytes();
      final prompt = [
        Content.multi([
          const TextPart(
            'Listen to the M4A Quran recitation and identify one exact surah '
            'and ayah only when the audible Arabic words support that match. '
            'Do not guess from melody, accent, or a short common phrase. '
            'Do not complete unclear words from memory. If several ayahs fit, '
            'the recording is unclear, or confidence is below 70, return '
            'found=false and null verse numbers. Set confidence from 0 to 100 '
            'based on how distinctly the words identify this exact ayah. '
            'Write "note" and "surah_name" in Uzbek (Latin). '
            'Respond ONLY with JSON matching the provided schema.',
          ),
          InlineDataPart('audio/m4a', audioBytes),
        ])
      ];

      final response =
          await _recitationModel.generateContent(prompt).timeout(_timeout);
      final data =
          jsonDecode(_extractJson(response.text ?? '')) as Map<String, dynamic>;

      final found = data['found'] == true;
      final surahNumber = (data['surah_number'] as num?)?.toInt();
      final ayahNumber = (data['ayah_number'] as num?)?.toInt();
      final confidence =
          ((data['confidence'] as num?)?.toInt() ?? 0).clamp(0, 100).toInt();
      final validReference = surahNumber != null &&
          surahNumber >= 1 &&
          surahNumber <= 114 &&
          ayahNumber != null &&
          ayahNumber >= 1 &&
          ayahNumber <= 286;
      final reliableMatch = found && validReference && confidence >= 70;

      return RecitationMatch(
        found: reliableMatch,
        surahNumber: reliableMatch ? surahNumber : null,
        ayahNumber: reliableMatch ? ayahNumber : null,
        surahArabicName: data['surah_name_arabic'] as String?,
        surahName: data['surah_name'] as String?,
        confidence: confidence,
        note: (data['note'] as String? ?? '').trim().isNotEmpty
            ? (data['note'] as String).trim()
            : reliableMatch
                ? ''
                : 'Ovozdan sura yoki oyatni ishonchli aniqlab bo‘lmadi. Ravshanroq va uzunroq tilovat qilib ko‘ring.',
      );
    } catch (e, s) {
      AppLogger.e('Sura aniqlashda xatolik', error: e, stackTrace: s);
      if (e is FirebaseAIException) {
        return RecitationMatch(found: false, note: _aiLogicError(e));
      }
      return const RecitationMatch(
        found: false,
        note: "AI'ga ulanishda xatolik yuz berdi. Internetni tekshirib, "
            "qayta urinib ko'ring.",
      );
    }
  }

  Future<String> askGemini(String question) async {
    try {
      final content = [Content.text(question)];
      final response = await _model.generateContent(content).timeout(_timeout);
      return response.text ?? 'Javob topilmadi.';
    } catch (e, s) {
      AppLogger.e('Gemini savolida xatolik', error: e, stackTrace: s);
      if (e is FirebaseAIException) return _aiLogicError(e);
      return "Javob olishda xatolik yuz berdi. Qayta urinib ko'ring.";
    }
  }

  String _aiLogicError(FirebaseAIException error) {
    if (error is ServiceApiNotEnabled) {
      final projectId = Firebase.app().options.projectId;
      return 'Firebase Console’da AI Logic xizmatini yoqing: '
          'https://console.firebase.google.com/project/$projectId/ailogic';
    }
    if (error is InvalidApiKey) {
      return 'Firebase AI Logic sozlamasi yaroqsiz. Firebase Console sozlamalarini tekshiring.';
    }
    if (error is QuotaExceeded) {
      return 'AI so‘rovlar limiti tugadi. Birozdan keyin qayta urinib ko‘ring.';
    }
    if (error is UnsupportedUserLocation) {
      return 'AI xizmati bu hududda hozircha ishlamaydi.';
    }
    if (error is ServerException) {
      final message = error.message.toLowerCase();
      if (message.contains('app check') ||
          message.contains('attestation') ||
          message.contains('appcheck')) {
        return 'Firebase App Check ilovani tasdiqlamadi. Debug tokenni Firebase Console’da ro‘yxatdan o‘tkazing.';
      }
      if (message.contains('permission_denied') ||
          message.contains('permission denied')) {
        return 'Firebase AI Logic so‘rovi rad etildi. AI Logic va App Check sozlamalarini tekshiring.';
      }
    }
    return 'Firebase AI xizmatida xatolik yuz berdi. Qayta urinib ko‘ring.';
  }

  /// Score the recognized word sequence locally instead of trusting a model's
  /// self-reported number. This measures word recognition, not full tajwid.
  int _wordMatchScore(String target, String transcription) {
    List<String> words(String value) {
      final normalized = value
          .replaceAll('ٱ', 'ا')
          .replaceAll('ۥ', 'و')
          .replaceAll('ۦ', 'ي')
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
          .replaceAll(RegExp(r'[أإآ]'), 'ا')
          .replaceAll('ى', 'ي')
          .replaceAll(RegExp(r'[^\u0621-\u064A\s]'), ' ')
          .trim();
      if (normalized.isEmpty) return const [];
      return normalized
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList(growable: false);
    }

    final expected = words(target);
    final heard = words(transcription);
    final denominator =
        expected.length > heard.length ? expected.length : heard.length;
    if (denominator == 0) return 0;

    var previous = List<int>.generate(heard.length + 1, (index) => index);
    for (var row = 1; row <= expected.length; row++) {
      final current = List<int>.filled(heard.length + 1, 0)..[0] = row;
      for (var column = 1; column <= heard.length; column++) {
        final substitution = previous[column - 1] +
            (expected[row - 1] == heard[column - 1] ? 0 : 1);
        current[column] = [
          previous[column] + 1,
          current[column - 1] + 1,
          substitution,
        ].reduce((a, b) => a < b ? a : b);
      }
      previous = current;
    }
    final distance = previous[heard.length];
    return (100 * (denominator - distance) / denominator)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  String _errorJson(String feedback) => jsonEncode({
        'error': true,
        'transcription': '',
        'score': 0,
        'feedback': feedback,
      });

  /// Markdown kodi yoki ortiqcha belgilardan toza JSON ajratib oladi.
  String _extractJson(String text) {
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(clean);
    return match?.group(0) ?? clean;
  }
}
