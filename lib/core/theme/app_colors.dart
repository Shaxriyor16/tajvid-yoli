import 'package:flutter/material.dart';

/// Centralized premium color palette for Tajvid Yo'li application.
/// Grounded in emerald dark tones, glassmorphism, and warm golden accents.
abstract class AppColors {
  // --- Brand Emerald & Gold Colors ---
  static const primary = Color(0xFF3FCAA8);
  static const secondary = Color(0xFFD9A84E);
  static const accent = Color(0xFFF6E2A8);

  // --- Theme Specific Tones ---
  static const gold1 = Color(0xFFF6E2A8);
  static const gold2 = Color(0xFFD9A84E);
  static const gold3 = Color(0xFFA67A2E);

  static const teal1 = Color(0xFF3FCAA8);
  static const teal2 = Color(0xFF12876C);
  static const teal3 = Color(0xFF0A4F40);

  static const coral1 = Color(0xFFE2917F);
  static const warn = Color(0xFFEEC27A);
  static const ink0 = Color(0xFF050E0C);
  static const ink1 = Color(0xFF0A1A17);
  static const ink2 = Color(0xFF0F231F);

  // --- Background & Surface Shades ---
  static const bg0 = Color(0xFF050E0C);
  static const bg1 = Color(0xFF0A1A17);
  static const bg2 = Color(0xFF0F231F);

  // --- Text Contrast Colors ---
  static const textHi = Color(0xFFF8F6EF);
  static const textMid = Color(0xADF8F6EF);
  static const textLow = Color(0x6BF8F6EF);

  // --- Status Colors ---
  static const success = Color(0xFF7ED6A5);
  static const warning = Color(0xFFEEC27A);
  static const danger = Color(0xFFE2917F);

  // --- Light Mode UI Colors ---
  static const lightBackground = Color(0xFFFAF8F2);
  static const lightBackgroundDeep = Color(0xFFF3EEE0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSoft = Color(0xFFF6F1E4);
  static const lightOnBackground = Color(0xFF211D12);
  static const lightOnSurface = Color(0xFF211D12);
  static const lightSecondary = Color(0xFF5E5642);
  static const lightTertiary = Color(0xFF82785C);
  static const lightBorder = Color(0xFFEAE3D0);
  static const lightBorderStrong = Color(0xFFD9D0B8);
  static const lightGold = Color(0xFFA0762B);
  static const lightEmerald = Color(0xFF12876C);

  // --- Dark Mode UI Colors ---
  static const darkBackground = Color(0xFF050E0C);
  static const darkSurface = Color(0xFF0F231F);
  static const darkOnBackground = Color(0xFFF8F6EF);
  static const darkOnSurface = Color(0xADF8F6EF);
  static const darkBorder = Color(0x24FFFFFF);

  // --- Glassmorphism & Borders ---
  static final lightGlass = const Color(0xFFFFFFFF).withValues(alpha: 0.12);
  static final darkGlass = const Color(0xFFFFFFFF).withValues(alpha: 0.07);
  static const glassBorder = Color(0x24FFFFFF);
  static const glassBorderStrong = Color(0x3DFFFFFF);

  // --- Gradients ---
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF3FCAA8), Color(0xFF12876C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFFF6E2A8), Color(0xFFD9A84E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const loginGradient = LinearGradient(
    colors: [Color(0xFF0F231F), Color(0xFF0A1A17), Color(0xFF050E0C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFF6E2A8), Color(0xFFD9A84E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const tealGradient = LinearGradient(
    colors: [Color(0xFF3FCAA8), Color(0xFF12876C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A1A17), Color(0xFF050E0C), Color(0xFF030807)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const lightBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFAF8F2), Color(0xFFF6F2E7), Color(0xFFF1EBDA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration adaptiveBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: isDark ? backgroundGradient : lightBackgroundGradient,
    );
  }
}
