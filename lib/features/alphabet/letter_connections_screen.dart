import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/screen_header.dart';
import 'alphabet_data.dart';

/// Harflarning ulanishi — har bir harf so'z ichida qaysi o'rinda
/// (yakka/boshida/o'rtada/oxirida) qanday shaklga kirishini ko'rsatadi.
///
/// Aniqlik: shakllar tatvil chizig'i (ـ) yordamida ko'rsatilgan — bu
/// Arab yozuvini o'rgatishda ulanish yo'nalishini ko'rsatish uchun
/// ishlatiladigan standart, keng tarqalgan usul. Matn avtomatik shakl
/// birlashtirish (text shaping) orqali to'g'ri chiziladi.
class LetterConnectionsScreen extends StatelessWidget {
  const LetterConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final subtitle = [
      l10n.get('form_isolated'),
      l10n.get('form_initial'),
      l10n.get('form_medial'),
      l10n.get('form_final'),
    ].join(' · ');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(title: l10n.get('conn_title'), subtitle: subtitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.teal1.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppColors.teal1.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.teal1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(builder: (context) {
                      final parts = l10n.get('conn_note').split('{letters}');
                      final base = TextStyle(
                          color: palette.textMid, fontSize: 12.5, height: 1.45);
                      return Text.rich(
                        TextSpan(style: base, children: [
                          TextSpan(text: parts.first),
                          TextSpan(
                              text: 'ا د ذ ر ز و',
                              style: AppTheme.arabic(
                                  size: 17, color: palette.textHi)),
                          if (parts.length > 1) TextSpan(text: parts[1]),
                        ]),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              itemCount: kArabicAlphabet.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final letter = kArabicAlphabet[i];
                final card = GlassCard(
                  radius: 20,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 62,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(letter.uzbekName,
                                style: TextStyle(
                                    color: palette.textHi,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5)),
                            if (!letter.connectsForward)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(l10n.get('conn_one_side'),
                                    style: TextStyle(
                                        color: palette.textLow, fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _FormTile(
                                label: l10n.get('form_isolated'),
                                value: letter.isolatedForm),
                            _FormTile(
                                label: l10n.get('form_initial'),
                                value: letter.initialForm),
                            _FormTile(
                                label: l10n.get('form_medial'),
                                value: letter.medialForm),
                            _FormTile(
                                label: l10n.get('form_final'),
                                value: letter.finalForm),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                return i < 8
                    ? FadeSlideIn(
                        delay: Duration(milliseconds: 40 * i),
                        offset: 10,
                        child: card)
                    : card;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FormTile extends StatelessWidget {
  final String label;
  final String value;
  const _FormTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: palette.accentGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.accentGold.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTheme.arabic(size: 22, color: palette.textHi),
                textDirection: TextDirection.rtl),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: TextStyle(color: palette.textLow, fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}
