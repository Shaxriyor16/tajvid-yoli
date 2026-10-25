import 'package:tajvid_yoli/core/widgets/ornaments.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/screen_header.dart';

class HarakatScreen extends StatelessWidget {
  const HarakatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        title: 'Fatha',
        example: 'بَ',
        sound: 'a',
        description: l10n.get('harakat_fatha_desc'),
        accent: const Color(0xFF1E9E7F),
      ),
      (
        title: 'Kasra',
        example: 'بِ',
        sound: 'i',
        description: l10n.get('harakat_kasra_desc'),
        accent: const Color(0xFF3B82C4),
      ),
      (
        title: 'Zamma',
        example: 'بُ',
        sound: 'u',
        description: l10n.get('harakat_zamma_desc'),
        accent: const Color(0xFFC9962F),
      ),
    ];
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l10n.get('harakat_title')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                        child: HeroBanner(
                          title: l10n.get('harakat_title'),
                          subtitle: l10n.get('harakat_intro'),
                          trailing: PaddedShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (b) =>
                                AppColors.goldGradient.createShader(b),
                            child: Text('بَ',
                                style: AppTheme.arabic(
                                    size: 56, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < items.length; i++)
                        FadeSlideIn(
                          delay: Duration(milliseconds: 80 * (i + 1)),
                          child: _HarakatItem(
                            title: items[i].title,
                            example: items[i].example,
                            sound: items[i].sound,
                            description: items[i].description,
                            accent: items[i].accent,
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

class _HarakatItem extends StatelessWidget {
  final String title;
  final String example;
  final String sound;
  final String description;
  final Color accent;

  const _HarakatItem({
    required this.title,
    required this.example,
    required this.sound,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.28),
                    accent.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(example,
                    style: AppTheme.arabic(size: 40, color: palette.textHi)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: palette.textHi,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      GlassChip(
                          label: l10n
                              .get('harakat_sound')
                              .replaceAll('{s}', sound),
                          color: accent),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(description,
                      style: TextStyle(
                          color: palette.textMid, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
