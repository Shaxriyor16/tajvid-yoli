import 'package:tajvid_yoli/core/widgets/ornaments.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/mic_orb.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../quran/quran_data.dart';

/// Foydalanuvchi tilovatini tinglab, AI yordamida qaysi sura/oyat
/// ekanligini aniqlaydi va arabcha matnini kitob (mushaf) uslubida
/// ko'rsatadi.
class RecitationFinderScreen extends StatefulWidget {
  const RecitationFinderScreen({super.key});

  @override
  State<RecitationFinderScreen> createState() => _RecitationFinderScreenState();
}

class _RecitationFinderScreenState extends State<RecitationFinderScreen> {
  static const _maxSeconds = 20;

  final _recorder = AudioRecorder();
  Timer? _timer;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isLoadingAyah = false;
  bool _micBusy = false;
  int _seconds = 0;

  RecitationMatch? _match;
  String? _ayahText;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _handleMicPress() async {
    if (_isAnalyzing || _isLoadingAyah || _micBusy) return;
    if (!AiService.isConfigured) {
      setState(() => _match = const RecitationMatch(
          found: false, note: 'AI xizmati hali sozlanmagan.'));
      return;
    }
    _micBusy = true;
    try {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    } catch (e, s) {
      AppLogger.e('Mikrofon xatosi', error: e, stackTrace: s);
      if (mounted) setState(() => _errorMessage = 'sura_finder_mic_error');
    } finally {
      _micBusy = false;
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      setState(() => _errorMessage = 'sura_finder_mic_permission');
      return;
    }
    final dir = await getTemporaryDirectory();
    if (!mounted) return;
    final path = '${dir.path}/recitation_audio.m4a';
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    } catch (e, s) {
      AppLogger.e('Yozib olish boshlanmadi', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() => _errorMessage = 'sura_finder_mic_error');
      return;
    }
    if (!mounted) {
      await _recorder.cancel();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _seconds = 0;
      _match = null;
      _ayahText = null;
      _errorMessage = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _seconds++);
      if (_seconds >= _maxSeconds) {
        _handleMicPress();
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    final duration = _seconds;
    if (!mounted) return;
    setState(() => _isRecording = false);
    if (path == null) return;
    if (duration < 2) {
      await _deleteQuietly(path);
      setState(() => _errorMessage = 'sura_finder_too_short');
      return;
    }
    _analyze(path);
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Tozalay olmamasak ham kritik emas.
    }
  }

  Future<void> _analyze(String path) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    try {
      final match = await context.read<AiService>().identifyRecitation(path);
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _match = match;
      });
      if (match.found) {
        _loadAyah(match);
      }
    } catch (e, s) {
      AppLogger.e('Sura aniqlash xatosi', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'error_occurred';
      });
    } finally {
      // Maxfiylik: tahlil tugagach, vaqtinchalik audio faylni o'chiramiz.
      await _deleteQuietly(path);
    }
  }

  Future<void> _loadAyah(RecitationMatch match) async {
    setState(() => _isLoadingAyah = true);
    try {
      final repository = context.read<QuranRepository>();
      final surah = await repository.getSurah(match.surahNumber!);
      if (!mounted || !identical(_match, match)) return;
      final index = (match.ayahNumber ?? 1) - 1;
      if (index < 0 || index >= surah.ayahs.length) {
        setState(() {
          _isLoadingAyah = false;
          _match = const RecitationMatch(
              found: false,
              note: 'Oyat raqamini tasdiqlab bo‘lmadi. Qayta urinib ko‘ring.');
        });
        return;
      }
      final ayah = surah.ayahs[index];
      if (!mounted) return;
      setState(() {
        _isLoadingAyah = false;
        _ayahText = ayah.arabicText;
      });
    } catch (e, s) {
      AppLogger.e('Oyat matni yuklanmadi', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoadingAyah = false);
    }
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _match = null;
      _ayahText = null;
      _errorMessage = null;
      _seconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l10n.get('recitation_finder')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (_errorMessage != null) ...[
                      _ErrorBanner(
                          message: l10n.get(_errorMessage!),
                          color: AppColors.danger),
                      const SizedBox(height: 16),
                    ],
                    if (_match == null) ...[
                      _DescriptionCard(text: l10n.get('finder_description')),
                      const SizedBox(height: 12),
                      Text(l10n.get('ai_audio_notice'),
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: palette.textLow, fontSize: 12)),
                      const SizedBox(height: 44),
                      _FinderMicButton(
                        isRecording: _isRecording,
                        isAnalyzing: _isAnalyzing,
                        seconds: _seconds,
                        maxSeconds: _maxSeconds,
                        onTap: _handleMicPress,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusText(l10n),
                        style: TextStyle(
                            color: palette.textLow,
                            fontSize: 13,
                            letterSpacing: 0.4),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      _ResultView(
                        match: _match!,
                        ayahText: _ayahText,
                        isLoadingAyah: _isLoadingAyah,
                        onOpenBook: () =>
                            context.push('/book/${_match!.surahNumber}'),
                        onOpenList: () =>
                            context.push('/quran/${_match!.surahNumber}'),
                        onRetry: _reset,
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(AppLocalizations l10n) {
    if (_isAnalyzing) return l10n.get('identifying');
    if (_isRecording) {
      return '${l10n.get('listening')} $_seconds / $_maxSeconds';
    }
    return l10n.get('finder_hint');
  }
}

class _DescriptionCard extends StatelessWidget {
  final String text;
  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return HeroBanner(
      title: AppLocalizations.of(context).get('recitation_finder'),
      subtitle: text,
      trailing: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(CupertinoIcons.waveform,
            color: Color(0xFFE8C77B), size: 26),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Color color;
  const _ErrorBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 13, height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FinderMicButton extends StatelessWidget {
  final bool isRecording;
  final bool isAnalyzing;
  final int seconds;
  final int maxSeconds;
  final VoidCallback onTap;

  const _FinderMicButton({
    required this.isRecording,
    required this.isAnalyzing,
    required this.seconds,
    required this.maxSeconds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MicOrb(
      isRecording: isRecording,
      isBusy: isAnalyzing,
      onTap: onTap,
      progress: maxSeconds == 0 ? null : seconds / maxSeconds,
    );
  }
}

class _ResultView extends StatelessWidget {
  final RecitationMatch match;
  final String? ayahText;
  final bool isLoadingAyah;
  final VoidCallback onOpenBook;
  final VoidCallback onOpenList;
  final VoidCallback onRetry;

  const _ResultView({
    required this.match,
    required this.ayahText,
    required this.isLoadingAyah,
    required this.onOpenBook,
    required this.onOpenList,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    if (!match.found) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Icon(CupertinoIcons.question_circle,
              size: 44, color: palette.textLow),
          const SizedBox(height: 14),
          Text(l10n.get('not_recognized'),
              style: AppTheme.display(size: 20, color: palette.textHi)),
          const SizedBox(height: 10),
          Text(
            match.note,
            style: TextStyle(color: palette.textMid, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GradientButton(
              label: l10n.get('try_again'),
              icon: CupertinoIcons.arrow_clockwise,
              onTap: onRetry),
        ],
      );
    }

    return Column(
      children: [
        HeroBanner(
          kicker: l10n.get('surah_found').toUpperCase(),
          title: match.surahName ?? '',
          subtitle: '${match.surahNumber}-${l10n.get('surah')} · '
              '${match.ayahNumber ?? 1}-${l10n.get('ayah')}'
              '${match.confidence > 0 ? ' · ${match.confidence}%' : ''}',
          trailing: PaddedShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              match.surahArabicName ?? '',
              textDirection: TextDirection.rtl,
              style: AppTheme.arabic(
                  size: 30, color: Colors.white, weight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isLoadingAyah)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: CircularProgressIndicator(color: palette.accentGold),
          )
        else if (ayahText != null)
          _MushafPanel(
            ayahText: ayahText!,
            ayahNumber: match.ayahNumber ?? 1,
            surahArabicName: match.surahArabicName ?? '',
          ),
        if (match.note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            match.note,
            style:
                TextStyle(color: palette.textLow, fontSize: 12.5, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 22),
        GradientButton(
          label: l10n.get('open_book'),
          icon: CupertinoIcons.book,
          onTap: onOpenBook,
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: l10n.get('open_list'),
          icon: CupertinoIcons.list_bullet,
          gradient: AppColors.tealGradient,
          labelColor: Colors.white,
          onTap: onOpenList,
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onRetry,
          icon: Icon(CupertinoIcons.arrow_clockwise,
              size: 16, color: palette.textMid),
          label: Text(l10n.get('try_again'),
              style: TextStyle(color: palette.textMid, fontSize: 14)),
        ),
      ],
    );
  }
}

/// Mushaf uslubidagi pergament panel — oyat arabcha matni uchun.
class _MushafPanel extends StatelessWidget {
  final String ayahText;
  final int ayahNumber;
  final String surahArabicName;

  const _MushafPanel({
    required this.ayahText,
    required this.ayahNumber,
    required this.surahArabicName,
  });

  static const _inkColor = Color(0xFF4A3B1E);
  static const _goldLine = Color(0xFFB08D3E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF6E8), Color(0xFFF1E7C8)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(14)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1F3A2E14), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _goldLine, width: 1.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            if (surahArabicName.isNotEmpty) ...[
              Text(
                surahArabicName,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    color: _inkColor,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: _goldLine.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
            ],
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$ayahText ',
                    style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 26,
                        color: _inkColor,
                        height: 2.1),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _AyahBadge(number: ayahNumber),
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text('$ayahNumber',
                style: TextStyle(
                    fontSize: 10,
                    color: _goldLine.withValues(alpha: 0.8),
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _AyahBadge extends StatelessWidget {
  final int number;
  const _AyahBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB08D3E), width: 1.2),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B4E1E)),
      ),
    );
  }
}
