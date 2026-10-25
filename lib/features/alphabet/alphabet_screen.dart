import 'package:tajvid_yoli/core/widgets/ornaments.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/adaptive_shell.dart';
import '../../core/widgets/answer_option.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/screen_header.dart';
import 'alphabet_data.dart';

class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l10n.get('alphabet_title'),
              subtitle: l10n
                  .get('alphabet_subtitle')
                  .replaceAll('{n}', '${kArabicAlphabet.length}'),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 6 : 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: kArabicAlphabet.length,
                itemBuilder: (context, i) {
                  final tile = _LetterTile(
                    letter: kArabicAlphabet[i],
                    index: i,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => LetterDetailScreen(startIndex: i)),
                    ),
                  );
                  return i < 16
                      ? FadeSlideIn(
                          delay: Duration(milliseconds: 25 * i),
                          offset: 10,
                          child: tile)
                      : tile;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  final ArabicLetter letter;
  final int index;
  final VoidCallback onTap;

  const _LetterTile(
      {required this.letter, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            top: 0,
            child: Text('${index + 1}',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: palette.textLow.withValues(alpha: 0.7))),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PaddedShaderMask(
                  blendMode: BlendMode.srcIn,
                  padding: EdgeInsets.zero,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      palette.accentGold,
                      Color.lerp(palette.accentGold, palette.textHi, 0.35)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(letter.letter,
                      style: AppTheme.arabic(size: 34, color: Colors.white)),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(letter.uzbekName,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textMid,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LetterDetailScreen extends StatefulWidget {
  final int startIndex;
  const LetterDetailScreen({super.key, required this.startIndex});

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen> {
  late int _index;
  int? _selectedOption;
  late List<ArabicLetter> _options;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _buildOptions();
  }

  ArabicLetter get _current => kArabicAlphabet[_index];

  void _buildOptions() {
    final rnd = Random();
    final houses = List<ArabicLetter>.from(kArabicAlphabet)
      ..removeWhere((l) => l.letter == _current.letter);
    houses.shuffle(rnd);
    _options = [_current, ...houses.take(3)]..shuffle(rnd);
    _selectedOption = null;
  }

  void _selectOption(int i) {
    if (_selectedOption != null) return;
    setState(() => _selectedOption = i);
  }

  void _next() {
    setState(() {
      _index = (_index + 1) % kArabicAlphabet.length;
      _buildOptions();
    });
  }

  AnswerState _stateFor(int i) {
    if (_selectedOption == null) return AnswerState.idle;
    final isCorrect = _options[i].letter == _current.letter;
    if (isCorrect) return AnswerState.correct;
    if (i == _selectedOption) return AnswerState.wrong;
    return AnswerState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: isDesktop ? 440 : double.infinity),
              child: Column(
                children: [
                  ScreenHeader(
                    title: l10n.get('letter_learn_title'),
                    subtitle: '${_index + 1}/${kArabicAlphabet.length}',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0,
                            end: (_index + 1) / kArabicAlphabet.length),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 5,
                          backgroundColor: palette.divider,
                          valueColor:
                              AlwaysStoppedAnimation(palette.accentGold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _LetterStage(letter: _current),
                          const SizedBox(height: 24),
                          Text(l10n.get('letter_quiz_prompt'),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textHi)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 58,
                            ),
                            itemCount: _options.length,
                            itemBuilder: (context, i) => AnswerOption(
                              label: _options[i].uzbekName,
                              state: _stateFor(i),
                              onTap: _selectedOption == null
                                  ? () => _selectOption(i)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_selectedOption != null)
                            FadeSlideIn(
                              offset: 10,
                              duration: const Duration(milliseconds: 300),
                              child: GradientButton(
                                label: l10n.get('next_letter'),
                                icon: Icons.arrow_forward_rounded,
                                onTap: _next,
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Harf sahnasi: naqshli zumrad kartada katta oltin harf.
class _LetterStage extends StatelessWidget {
  final ArabicLetter letter;
  const _LetterStage({required this.letter});

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
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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
                        key: ValueKey(letter.letter),
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) =>
                            AppColors.goldGradient.createShader(bounds),
                        child: Text(letter.letter,
                            style: AppTheme.arabic(
                                size: 104, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(letter.uzbekName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        l10n
                            .get('letter_group')
                            .replaceAll('{g}', letter.articulationGroup),
                        style: const TextStyle(
                            color: Color(0xFFCCE1DA), fontSize: 13)),
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
