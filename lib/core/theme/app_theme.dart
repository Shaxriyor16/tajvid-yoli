import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tajvid_yoli/core/theme/app_colors.dart';
import 'package:tajvid_yoli/core/theme/app_palette.dart';
export 'package:tajvid_yoli/core/theme/app_colors.dart';
export 'package:tajvid_yoli/core/theme/app_palette.dart';

/// The main theme configuration for the application.
/// This class provides static methods to get the light and dark themes.
class AppTheme {
  static final ThemeData _lightTheme = _buildLightTheme();
  static final ThemeData _darkTheme = _buildDarkTheme();
  static ThemeData get lightTheme => _lightTheme;
  static ThemeData get darkTheme => _darkTheme;

  static ThemeData _buildLightTheme() {
    const palette = AppPalette.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightEmerald,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightEmerald,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD8F0E8),
        onPrimaryContainer: Color(0xFF0B3D31),
        secondary: AppColors.gold2,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF4E5C4),
        onSecondaryContainer: Color(0xFF5C430F),
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        surfaceContainerHighest: AppColors.lightSurfaceSoft,
        onSurfaceVariant: AppColors.lightSecondary,
        outline: AppColors.lightBorderStrong,
        outlineVariant: AppColors.lightBorder,
        error: Color(0xFFC25E4C),
        onError: Colors.white,
      ),
      extensions: const [palette],
      textTheme: _textTheme(AppColors.lightOnBackground),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.lightEmerald),
      cardTheme: _cardTheme(
        AppColors.lightSurface,
        AppColors.lightBorder,
        const [
          BoxShadow(
            color: Color(0x123A2E14),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      appBarTheme: _appBarTheme(
        AppColors.lightBackground,
        AppColors.lightOnBackground,
        SystemUiOverlayStyle.dark,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightSecondary),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.lightTertiary,
        textColor: AppColors.lightOnBackground,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.lightEmerald
              : AppColors.lightBorderStrong,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.sheetFill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.sheetFill,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightOnBackground,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.fieldFill,
        hintStyle: const TextStyle(color: AppColors.lightTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.lightEmerald, width: 1.5),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.lightEmerald,
        selectionColor: Color(0x403FCAA8),
        selectionHandleColor: AppColors.lightEmerald,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.lightEmerald),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.lightEmerald,
        unselectedLabelColor: AppColors.lightTertiary,
        indicatorColor: AppColors.lightEmerald,
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    const palette = AppPalette.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnBackground,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      extensions: const [palette],
      textTheme: _textTheme(AppColors.darkOnBackground),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary),
      cardTheme: _cardTheme(AppColors.darkSurface, AppColors.darkBorder, const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 30,
          offset: Offset(0, 14),
        ),
      ]),
      appBarTheme: _appBarTheme(
        AppColors.darkBackground,
        AppColors.darkOnBackground,
        SystemUiOverlayStyle.light,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textLow,
        textColor: AppColors.textHi,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.ink1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.ink1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x403FCAA8),
        selectionHandleColor: AppColors.primary,
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ).apply(
        fontFamily: 'Supreme',
        fontFamilyFallback: _fontFallback,
        displayColor: color,
        bodyColor: color);
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color primaryColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Chubbo/Supreme da bo'lmagan belgilar (ʻ, →, ✓) uchun zaxira shrift.
  static const List<String> _fontFallback = ['Inter'];

  static ThemeData get dark => darkTheme;
  static ThemeData get light => lightTheme;

  static TextStyle display({
    double size = 16,
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: 'Chubbo',
      fontFamilyFallback: _fontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle arabic({
    double size = 20,
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static CardThemeData _cardTheme(
    Color surfaceColor,
    Color borderColor,
    List<BoxShadow> shadows,
  ) {
    return CardThemeData(
      elevation: 0,
      color: surfaceColor,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1),
      ),
    );
  }

  static AppBarTheme _appBarTheme(
    Color backgroundColor,
    Color foregroundColor,
    SystemUiOverlayStyle overlayStyle,
  ) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      centerTitle: true,
      systemOverlayStyle: overlayStyle,
    );
  }
}
