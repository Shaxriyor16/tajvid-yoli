import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/screen_header.dart';

class WordReadingScreen extends StatelessWidget {
  const WordReadingScreen({super.key});

  static const _words = [
    (arabic: 'كَتَبَ', pronunciation: 'Kataba'),
    (arabic: 'قَرَأَ', pronunciation: "Qara'a"),
    (arabic: 'خَلَقَ', pronunciation: 'Khalaqa'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l10n.get('word_title')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  child: Column(
                    children: [
                      FadeSlideIn(
                        child: HeroBanner(
                          title: l10n.get('word_title'),
                          subtitle: l10n.get('word_intro'),
                          trailing: PaddedShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (b) =>
                                AppColors.goldGradient.createShader(b),
                            child: Text('كَتَبَ',
                                style: AppTheme.arabic(
                                    size: 38, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < _words.length; i++)
                        FadeSlideIn(
                          delay: Duration(milliseconds: 80 * (i + 1)),
                          child: _WordItem(
                            number: i + 1,
                            arabic: _words[i].arabic,
                            pronunciation: _words[i].pronunciation,
                          ),
                        ),
                    ],
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

class _WordItem extends StatelessWidget {
  final int number;
  final String arabic;
  final String pronunciation;

  const _WordItem({
    required this.number,
    required this.arabic,
    required this.pronunciation,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            StarBadge(
              size: 44,
              child: Text('$number',
                  style: TextStyle(
                      color: palette.accentGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(pronunciation,
                  style: TextStyle(
                      color: palette.textHi,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            PaddedShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => LinearGradient(
                colors: [
                  palette.accentGold,
                  Color.lerp(palette.accentGold, palette.textHi, 0.35)!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(b),
              child: Text(arabic,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabic(size: 36, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
