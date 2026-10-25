import 'package:tajvid_yoli/core/widgets/ornaments.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/adaptive_shell.dart';
import '../../core/widgets/answer_option.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/db/app_database.dart';
import '../alphabet/alphabet_data.dart';

/// Harf-nom mosligini tekshiruvchi qisqa test. Har bir savol tugagach
/// natija saqlanadi; testni tugatgach haqiqiy XP `AppDatabase.awardXp`
/// orqali yoziladi — bu demo emas, real yozuv.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizQuestion {
  final ArabicLetter answer;
  final List<ArabicLetter> options;
  _QuizQuestion({required this.answer, required this.options});
}

class _QuizScreenState extends State<QuizScreen> {
  static const _questionCount = 8;
  static const _xpPerCorrect = 10;

  late List<_QuizQuestion> _questions;
  int _current = 0;
  int _correctCount = 0;
  int? _selected;
  bool _finished = false;
  bool _xpSaved = false;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();
  }

  List<_QuizQuestion> _generateQuestions() {
    final rnd = Random();
    final pool = List<ArabicLetter>.from(kArabicAlphabet)..shuffle(rnd);
    final picked = pool.take(_questionCount).toList();
    return picked.map((letter) {
      final distractors = List<ArabicLetter>.from(kArabicAlphabet)
        ..remove(letter);
      distractors.shuffle(rnd);
      final options = [letter, ...distractors.take(3)]..shuffle(rnd);
      return _QuizQuestion(answer: letter, options: options);
    }).toList();
  }

  void _selectAnswer(int i) {
    if (_selected != null) return;
    final correct = _questions[_current].options[i].letter ==
        _questions[_current].answer.letter;
    setState(() {
      _selected = i;
      if (correct) _correctCount++;
    });
  }

  Future<void> _next() async {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
      });
    } else {
      setState(() => _finished = true);
      if (!_xpSaved) {
        _xpSaved = true;
        final earned = _correctCount * _xpPerCorrect;
        if (earned > 0) {
          await context
              .read<AppDatabase>()
              .awardXp(amount: earned, reason: 'alifbo_testi');
        }
      }
    }
  }

  void _restart() {
    setState(() {
      _questions = _generateQuestions();
      _current = 0;
      _correctCount = 0;
      _selected = null;
      _finished = false;
      _xpSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l10n.get('quiz_title')),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(isDesktop ? 60 : 20, 0,
                      isDesktop ? 60 : 20, isDesktop ? 40 : 120),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: isDesktop ? 460 : double.infinity),
                      child: _finished
                          ? _ResultView(
                              correct: _correctCount,
                              total: _questions.length,
                              xpEarned: _correctCount * _xpPerCorrect,
                              onRestart: _restart,
                            )
                          : _QuestionView(
                              question: _questions[_current],
                              index: _current,
                              total: _questions.length,
                              selected: _selected,
                              onSelect: _selectAnswer,
                              onNext: _next,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final _QuizQuestion question;
  final int index;
  final int total;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;

  const _QuestionView({
    required this.question,
    required this.index,
    required this.total,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  AnswerState _stateFor(int i) {
    if (selected == null) return AnswerState.idle;
    if (question.options[i].letter == question.answer.letter) {
      return AnswerState.correct;
    }
    return i == selected ? AnswerState.wrong : AnswerState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.get('quiz_alpha'), style: AppTheme.display(size: 19)),
            const Spacer(),
            Text('${index + 1}/$total',
                style: TextStyle(
                    color: palette.accentGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(
                begin: 0, end: (index + (selected != null ? 1 : 0)) / total),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: palette.divider,
              valueColor: AlwaysStoppedAnimation(palette.accentGold),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _QuestionStage(letter: question.answer.letter),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 58,
          ),
          itemCount: question.options.length,
          itemBuilder: (context, i) => AnswerOption(
            label: question.options[i].uzbekName,
            state: _stateFor(i),
            onTap: selected == null ? () => onSelect(i) : null,
          ),
        ),
        const SizedBox(height: 20),
        if (selected != null)
          FadeSlideIn(
            offset: 10,
            duration: const Duration(milliseconds: 300),
            child: GradientButton(
              label: index == total - 1
                  ? l10n.get('quiz_finish')
                  : l10n.get('quiz_next'),
              icon: Icons.arrow_forward_rounded,
              onTap: onNext,
            ),
          ),
      ],
    );
  }
}

/// Savol sahnasi: naqshli zumrad kartada katta oltin harf.
class _QuestionStage extends StatelessWidget {
  final String letter;
  const _QuestionStage({required this.letter});

  static const _gold = Color(0xFFE8C77B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF16604F), Color(0xFF0F4A3D), Color(0xFF0A2E27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4A3D).withValues(alpha: 0.3),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const RadialGradient(
                  colors: [Colors.white, Colors.transparent],
                  radius: 0.85,
                ).createShader(rect),
                child: IslamicPattern(
                  color: _gold.withValues(alpha: 0.14),
                  cell: 50,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                          child: child,
                        ),
                      ),
                      child: PaddedShaderMask(
                        key: ValueKey(letter),
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) =>
                            AppColors.goldGradient.createShader(b),
                        child: Text(letter,
                            style: AppTheme.arabic(
                                size: 110,
                                weight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(l10n.get('quiz_which'),
                        style: const TextStyle(
                            color: Color(0xFFCCE1DA),
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
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

class _ResultView extends StatelessWidget {
  final int correct;
  final int total;
  final int xpEarned;
  final VoidCallback onRestart;

  const _ResultView(
      {required this.correct,
      required this.total,
      required this.xpEarned,
      required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final ratio = total == 0 ? 0.0 : correct / total;
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.gold2.withValues(alpha: 0.3),
                    AppColors.gold2.withValues(alpha: 0),
                  ]),
                ),
              ),
              SizedBox(
                width: 140,
                height: 140,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: palette.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold2),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ratio >= 0.7
                        ? Icons.emoji_events_rounded
                        : Icons.workspace_premium_rounded,
                    color: palette.accentGold,
                    size: 34,
                  ),
                  const SizedBox(height: 4),
                  Text('${(ratio * 100).round()}%',
                      style: AppTheme.display(size: 26, color: palette.textHi)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(l10n.get('quiz_done'), style: AppTheme.display(size: 22)),
        const SizedBox(height: 8),
        Text(
            l10n
                .get('quiz_score')
                .replaceAll('{c}', '$correct')
                .replaceAll('{t}', '$total'),
            style: TextStyle(color: palette.textMid, fontSize: 14)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: palette.accentGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
            border:
                Border.all(color: palette.accentGold.withValues(alpha: 0.3)),
          ),
          child: Text(l10n.get('quiz_xp').replaceAll('{n}', '$xpEarned'),
              style: TextStyle(
                  color: palette.accentGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 28),
        GradientButton(
            label: l10n.get('plan_retry'),
            icon: Icons.refresh_rounded,
            onTap: onRestart),
      ],
    );
  }
}
