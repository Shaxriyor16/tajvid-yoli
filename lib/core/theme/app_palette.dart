import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Adaptive design tokens that switch with the active theme.
///
/// Every screen reads colors through [AppPalette] instead of hardcoding
/// dark-mode constants, so light and dark UIs both stay consistent.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.textHi,
    required this.textMid,
    required this.textLow,
    required this.accentGold,
    required this.cardFill,
    required this.cardBorder,
    required this.cardShadow,
    required this.glassBorder,
    required this.sheetFill,
    required this.divider,
    required this.navFill,
    required this.navBorder,
    required this.navUnselected,
    required this.fieldFill,
    required this.fieldBorder,
  });

  /// Primary text / icons — highest contrast.
  final Color textHi;

  /// Secondary text / icons.
  final Color textMid;

  /// Tertiary text, captions, hints.
  final Color textLow;

  /// Gold accent with enough contrast for the current background.
  final Color accentGold;

  /// Card / glass surface fill.
  final Color cardFill;

  /// Hairline border around cards.
  final Color cardBorder;

  /// Soft elevation shadow for cards.
  final List<BoxShadow> cardShadow;

  /// Border for glassy elements (chips, dividers on gradients).
  final Color glassBorder;

  /// Modal bottom-sheet / dialog surface.
  final Color sheetFill;

  /// Divider lines.
  final Color divider;

  /// Floating navigation bar fill (used with a backdrop blur).
  final Color navFill;

  /// Floating navigation bar border.
  final Color navBorder;

  /// Unselected navigation item color.
  final Color navUnselected;

  /// Text-field fill.
  final Color fieldFill;

  /// Text-field border.
  final Color fieldBorder;

  static const AppPalette light = AppPalette(
    textHi: Color(0xFF211D12),
    textMid: Color(0xFF5E5642),
    textLow: Color(0xFF82785C),
    accentGold: Color(0xFFA0762B),
    cardFill: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFEAE3D0),
    cardShadow: [
      BoxShadow(
        color: Color(0x173A2E14),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
    glassBorder: Color(0xFFE4DCC6),
    sheetFill: Color(0xFFFDFBF6),
    divider: Color(0xFFEAE3D0),
    navFill: Color(0xD9FFFFFF),
    navBorder: Color(0xFFE6DECA),
    navUnselected: Color(0xFF918767),
    fieldFill: Color(0xFFF6F1E4),
    fieldBorder: Color(0xFFE4DCC6),
  );

  static const AppPalette dark = AppPalette(
    textHi: AppColors.textHi,
    textMid: AppColors.textMid,
    textLow: AppColors.textLow,
    accentGold: AppColors.gold1,
    cardFill: Color(0x12FFFFFF),
    cardBorder: AppColors.glassBorder,
    cardShadow: [
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 40,
        offset: Offset(0, 20),
      ),
    ],
    glassBorder: AppColors.glassBorder,
    sheetFill: AppColors.ink1,
    divider: AppColors.glassBorder,
    navFill: Color(0xB30A1A17),
    navBorder: Color(0x1FFFFFFF),
    navUnselected: Color(0x80FFFFFF),
    fieldFill: Color(0x0FFFFFFF),
    fieldBorder: Color(0x24FFFFFF),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>()!;
  }

  @override
  AppPalette copyWith({
    Color? textHi,
    Color? textMid,
    Color? textLow,
    Color? accentGold,
    Color? cardFill,
    Color? cardBorder,
    List<BoxShadow>? cardShadow,
    Color? glassBorder,
    Color? sheetFill,
    Color? divider,
    Color? navFill,
    Color? navBorder,
    Color? navUnselected,
    Color? fieldFill,
    Color? fieldBorder,
  }) {
    return AppPalette(
      textHi: textHi ?? this.textHi,
      textMid: textMid ?? this.textMid,
      textLow: textLow ?? this.textLow,
      accentGold: accentGold ?? this.accentGold,
      cardFill: cardFill ?? this.cardFill,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      glassBorder: glassBorder ?? this.glassBorder,
      sheetFill: sheetFill ?? this.sheetFill,
      divider: divider ?? this.divider,
      navFill: navFill ?? this.navFill,
      navBorder: navBorder ?? this.navBorder,
      navUnselected: navUnselected ?? this.navUnselected,
      fieldFill: fieldFill ?? this.fieldFill,
      fieldBorder: fieldBorder ?? this.fieldBorder,
    );
  }

  @override
  AppPalette lerp(AppPalette other, double t) {
    if (identical(this, other)) return this;
    return AppPalette(
      textHi: Color.lerp(textHi, other.textHi, t)!,
      textMid: Color.lerp(textMid, other.textMid, t)!,
      textLow: Color.lerp(textLow, other.textLow, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow:
          BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? const [],
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      sheetFill: Color.lerp(sheetFill, other.sheetFill, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      navFill: Color.lerp(navFill, other.navFill, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      navUnselected: Color.lerp(navUnselected, other.navUnselected, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => AppPalette.of(this);
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
