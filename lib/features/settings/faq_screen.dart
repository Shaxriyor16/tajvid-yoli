import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/screen_header.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l10n.get('faq_title')),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _FaqItem(
                      question: l10n.get('faq_q1'),
                      answer: l10n.get('faq_a1'),
                    ),
                    _FaqItem(
                      question: l10n.get('faq_q2'),
                      answer: l10n.get('faq_a2'),
                    ),
                    _FaqItem(
                      question: l10n.get('faq_q3'),
                      answer: l10n.get('faq_a3'),
                    ),
                    _FaqItem(
                      question: l10n.get('faq_q4'),
                      answer: l10n.get('faq_a4'),
                    ),
                    _FaqItem(
                      question: l10n.get('faq_q5'),
                      answer: l10n.get('faq_a5'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isExpanded = !_isExpanded);
        },
        padding: const EdgeInsets.all(18),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                        color: palette.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: _isExpanded ? 0.5 : 0,
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    color: palette.accentGold,
                    size: 18,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Column(
                      // Kengaytirilgan holatda
                      children: [
                        const SizedBox(height: 12),
                        Divider(color: palette.divider, height: 1),
                        const SizedBox(height: 12),
                        Text(
                          widget.answer,
                          style: TextStyle(
                              color: palette.textMid,
                              height: 1.5,
                              fontSize: 14),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(), // Yig'ilgan holatda
            ),
          ],
        ),
      ),
    );
  }
}
