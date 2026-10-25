import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/screen_header.dart';

class SyllablePracticeScreen extends StatelessWidget {
  const SyllablePracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: const SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'Bug‘inlarni o‘qish'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    children: [
                      _SyllableDescription(),
                      SizedBox(height: 24),
                      _SyllableItem(arabic: 'بَ', pronunciation: 'Ba'),
                      _SyllableItem(arabic: 'بِ', pronunciation: 'Bi'),
                      _SyllableItem(arabic: 'بُ', pronunciation: 'Bu'),
                      _SyllableItem(arabic: 'تَ', pronunciation: 'Ta'),
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

class _SyllableDescription extends StatelessWidget {
  const _SyllableDescription();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Text(
      'Harf va harakatlarni birlashtirib bug‘inlarni hosil qilishni o‘rganamiz.',
      style: TextStyle(color: palette.textMid),
    );
  }
}

class _SyllableItem extends StatelessWidget {
  final String arabic;
  final String pronunciation;

  const _SyllableItem({required this.arabic, required this.pronunciation});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(arabic,
                style: AppTheme.arabic(size: 32, color: palette.accentGold)),
            Text(pronunciation,
                style: TextStyle(
                    color: palette.textHi,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
