import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'islamic_pattern.dart';

/// O'quv ekranlari tepasidagi bezakli zumrad blok: kichik sarlavha,
/// asosiy matn, izoh va ixtiyoriy bezak (masalan, arabcha so'z).
class HeroBanner extends StatelessWidget {
  final String? kicker;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const HeroBanner({
    super.key,
    required this.title,
    this.kicker,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(22),
  });

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
            blurRadius: 26,
            offset: const Offset(0, 12),
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
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.3, 1],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(rect),
                child: IslamicPattern(
                  color: _gold.withValues(alpha: 0.12),
                  cell: 48,
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _gold.withValues(alpha: 0.26),
                    _gold.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (kicker != null) ...[
                          Text(kicker!,
                              style: const TextStyle(
                                  color: _gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                        ],
                        Text(title,
                            style: AppTheme.display(
                                size: 22, color: Colors.white)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(subtitle!,
                              style: const TextStyle(
                                  color: Color(0xFFCCE1DA),
                                  fontSize: 13,
                                  height: 1.45)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
