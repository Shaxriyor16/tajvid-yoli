import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';

/// A reading aid stays visible directly beneath its corresponding Arabic ayah.
class AyahReading extends StatelessWidget {
  final String? text;
  final Color color;

  const AyahReading({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reading = (text ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&quot;', '"')
        .trim();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.get('lat_reading'),
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          SelectableText(
            reading.isEmpty ? l10n.get('reading_unavailable') : reading,
            textDirection: TextDirection.ltr,
            style: TextStyle(color: color, fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}
