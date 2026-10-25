import 'package:tajvid_yoli/core/widgets/ornaments.dart';
import 'dart:async';
import 'dart:convert';
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
import '../../core/widgets/screen_header.dart';
import '../../core/db/app_database.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/mic_orb.dart';
import '../../core/widgets/motion.dart';

class AiCheckScreen extends StatefulWidget {
  final String? initialText;
  const AiCheckScreen({super.key, this.initialText});

  @override
  State<AiCheckScreen> createState() => _AiCheckScreenState();
}

class _AiCheckScreenState extends State<AiCheckScreen> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isChecking = false;
  bool _micBusy = false;
  Timer? _recordingLimit;

  String? _transcription;
  String? _feedback;
  int _score = 0;
  bool _showResult = false;

  late String _targetText;

  static const _commonPhrases = [
    {'uz': 'Bismillah', 'ar': 'بِسْمِ اللَّهِ'},
    {'uz': 'Alhamdulillah', 'ar': 'الْحَمْدُ لِلَّهِ'},
    {'uz': 'SubhanAllah', 'ar': 'سُبْحَانَ اللَّهِ'},
    {'uz': 'Allahu Akbar', 'ar': 'اللَّهُ أَكْبَرُ'},
    {'uz': 'La ilaha illallah', 'ar': 'لَا إِلَهَ إِلَّا اللَّهُ'},
  ];

  @override
  void initState() {
    super.initState();
    _targetText = widget.initialText ?? _commonPhrases[0]['ar']!;
  }

  @override
  void didUpdateWidget(AiCheckScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != null &&
        widget.initialText != oldWidget.initialText) {
      setState(() {
        _targetText = widget.initialText!;
        _showResult = false;
        _transcription = null;
      });
    }
  }

  @override
  void dispose() {
    _recordingLimit?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _showL10nSnackBar(String key, {bool isError = false}) {
    if (!mounted) return;
    _showSnackBar(AppLocalizations.of(context).get(key), isError: isError);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Material(
          type: MaterialType.transparency,
          child: Text(message,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        backgroundColor: isError
            ? AppColors.danger
            : AppColors.success.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      ),
    );
  }

  Future<void> _handleMicPress() async {
    if (_micBusy || _isChecking) return;
    if (!AiService.isConfigured) {
      _showL10nSnackBar('ai_not_configured', isError: true);
      return;
    }
    _micBusy = true;
    try {
      if (_isRecording) {
        _recordingLimit?.cancel();
        final path = await _recorder.stop();
        if (!mounted) return;
        setState(() => _isRecording = false);
        if (path != null) {
          _analyzeAudio(path);
        }
      } else {
        if (await _recorder.hasPermission()) {
          if (!mounted) return;
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/check_audio.m4a';

          await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
              path: path);
          if (!mounted) {
            await _recorder.cancel();
            return;
          }
          setState(() {
            _isRecording = true;
            _showResult = false;
            _transcription = null;
            _feedback = null;
          });
          HapticFeedback.mediumImpact();
          _recordingLimit = Timer(const Duration(seconds: 30), _handleMicPress);
        } else {
          _showL10nSnackBar('ai_mic_permission', isError: true);
        }
      }
    } catch (e, s) {
      AppLogger.e('Mikrofon xatosi', error: e, stackTrace: s);
      if (mounted) setState(() => _isRecording = false);
      _showL10nSnackBar('ai_mic_failed', isError: true);
    } finally {
      _micBusy = false;
    }
  }

  void _analyzeAudio(String path) async {
    setState(() => _isChecking = true);

    try {
      final aiService = context.read<AiService>();
      final result = await aiService.checkPronunciation(path, _targetText);

      // Robust JSON extraction
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(result);
      final jsonString = jsonMatch != null ? jsonMatch.group(0)! : result;
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (data['error'] == true) {
        if (mounted) setState(() => _isChecking = false);
        _showSnackBar(data['feedback'] as String, isError: true);
        return;
      }

      final score = ((data['score'] as num?)?.toInt() ?? 0).clamp(0, 100);
      final transcription = data['transcription'] as String? ?? '';
      final feedback = data['feedback'] as String? ?? '';

      if (mounted) {
        setState(() {
          _isChecking = false;
          _transcription = transcription;
          _feedback = feedback;
          _score = score;
          _showResult = true;
        });

        if (score >= 90) {
          final db = context.read<AppDatabase>();
          await db.updateLessonProgress('ai_check_dynamic', score / 100, true);
        }
      }
    } catch (e, s) {
      AppLogger.e('AI tahlilida xato', error: e, stackTrace: s);
      if (mounted) {
        setState(() => _isChecking = false);
        _showL10nSnackBar('ai_failed', isError: true);
      }
    } finally {
      // Maxfiylik: tahlil tugagach, vaqtinchalik audio faylni o'chiramiz.
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // Tozalay olmamasak ham kritik emas.
      }
    }
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
            ScreenHeader(title: l10n.get('ai_analysis'), showBackButton: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _SubtleTarget(text: _targetText),
                    const SizedBox(height: 12),
                    if (widget.initialText == null) _buildPhrasePicker(palette),
                    if (widget.initialText == null) ...[
                      const SizedBox(height: 16),
                      _FinderTeaser(
                        onTap: () => context.push('/recitation-finder'),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Text(
                        '${l10n.get('ai_audio_notice')} ${l10n.get('ai_score_notice')}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: palette.textLow, fontSize: 12, height: 1.5)),
                    const SizedBox(height: 24),
                    _MicButton(
                      isRecording: _isRecording,
                      isChecking: _isChecking,
                      onTap: _handleMicPress,
                    ),
                    const SizedBox(height: 24),
                    Text(
                        _isChecking
                            ? l10n.get('ai_analyzing')
                            : (_isRecording
                                ? l10n.get('listening')
                                : l10n.get('tap_to_read')),
                        style: TextStyle(
                            color: palette.textLow,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 32),
                    if (_showResult && _transcription != null)
                      FadeSlideIn(
                        key: ValueKey(_transcription),
                        child: _AnalysisView(
                          transcription: _transcription!,
                          score: _score,
                          feedback: _feedback ?? '',
                        ),
                      ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhrasePicker(AppPalette palette) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _commonPhrases.map((p) {
          final selected = _targetText == p['ar'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p['uz']!),
              selected: selected,
              onSelected: _isRecording || _isChecking || _micBusy
                  ? null
                  : (val) {
                      if (val) {
                        setState(() {
                          _targetText = p['ar']!;
                          _showResult = false;
                        });
                        HapticFeedback.selectionClick();
                      }
                    },
              backgroundColor: palette.fieldFill,
              selectedColor: palette.accentGold.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: selected ? palette.accentGold : palette.textMid,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: selected ? palette.accentGold : palette.fieldBorder),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubtleTarget extends StatelessWidget {
  final String text;
  const _SubtleTarget({required this.text});

  static const _gold = Color(0xFFE8C77B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF16604F), Color(0xFF0F4A3D), Color(0xFF0A2E27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4A3D).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const RadialGradient(
                  colors: [Colors.white, Colors.transparent],
                  radius: 0.9,
                ).createShader(rect),
                child: IslamicPattern(
                  color: _gold.withValues(alpha: 0.13),
                  cell: 48,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).get('ai_target_label'),
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        text,
                        key: ValueKey(text),
                        style: AppTheme.arabic(size: 32, color: Colors.white),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final bool isChecking;
  final VoidCallback onTap;

  const _MicButton(
      {required this.isRecording,
      required this.isChecking,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MicOrb(isRecording: isRecording, isBusy: isChecking, onTap: onTap);
  }
}

class _AnalysisView extends StatelessWidget {
  final String transcription;
  final int score;
  final String feedback;
  const _AnalysisView(
      {required this.transcription,
      required this.score,
      required this.feedback});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Text(l10n.get('ai_heard_label'),
            style: TextStyle(
                color: palette.accentGold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        const SizedBox(height: 16),
        PaddedShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: Text(
            transcription,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTheme.arabic(
                size: 44, color: Colors.white, weight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 32),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  _ScoreIndicator(score: score),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.get('ai_result'),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: palette.textHi)),
                        Text(
                            score >= 90
                                ? l10n.get('perfect_result')
                                : l10n.get('keep_trying'),
                            style: TextStyle(
                                fontSize: 12, color: palette.textLow)),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 32, color: palette.glassBorder),
              Text(
                feedback,
                style: TextStyle(
                    color: palette.textMid, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final int score;
  const _ScoreIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = score >= 90 ? AppColors.success : AppColors.warn;
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: palette.divider,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          Text('$score%',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _FinderTeaser extends StatelessWidget {
  final VoidCallback onTap;
  const _FinderTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: palette.fieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.fieldBorder),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.waveform,
                  size: 18, color: palette.accentGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.get('finder_teaser'),
                  style: TextStyle(
                      color: palette.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Icon(CupertinoIcons.chevron_right,
                  size: 14, color: palette.textLow),
            ],
          ),
        ),
      ),
    );
  }
}
