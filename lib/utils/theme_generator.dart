import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../models/theme_state.dart';

/// Helper class for generating ThemeData from ThemeState
class ThemeGenerator {
  /// Generates light theme data
  static ThemeData generateLightTheme({
    required ColorScheme lightColorScheme,
    required bool isDynamicColorEnabled,
  }) {
    return ThemeData(
      colorScheme: lightColorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: lightColorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: lightColorScheme.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightColorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: lightColorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Generates dark theme data with support for true black (OLED) mode
  static ThemeData generateDarkTheme({
    required ColorScheme darkColorScheme,
    required bool isTrueBlackEnabled,
    required bool isDynamicColorEnabled,
  }) {
    // Apply true black mode if enabled
    final surfaceColor = isTrueBlackEnabled
        ? const Color(0xFF000000)
        : darkColorScheme.surface;

    final scaffoldBackgroundColor = isTrueBlackEnabled
        ? const Color(0xFF000000)
        : darkColorScheme.surface;

    return ThemeData(
      colorScheme: darkColorScheme.copyWith(
        surface: surfaceColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: darkColorScheme.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: darkColorScheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isTrueBlackEnabled ? const Color(0xFF000000) : darkColorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkColorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Generates color schemes from theme state
  ///
  /// This method handles dynamic color extraction (Monet) and seed color generation.
  /// It also applies contrast levels for accessibility.
  static ColorSchemes generateColorSchemes({
    required ThemeState themeState,
    Color? dynamicHarmonizedColor,
  }) {
    final seedColor = dynamicHarmonizedColor ?? themeState.seedColor;

    // Generate light color scheme with contrast level
    final lightScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      contrastLevel: themeState.contrastLevel,
    );

    // Generate dark color scheme with contrast level
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      contrastLevel: themeState.contrastLevel,
    );

    return ColorSchemes(
      light: lightScheme,
      dark: darkScheme,
    );
  }

  /// Generates dynamic color schemes using Monet (Android 12+)
  ///
  /// Returns null if dynamic color is not available or not enabled
  static Future<ColorSchemes?> generateDynamicColorSchemes({
    required ThemeState themeState,
  }) async {
    if (!themeState.isDynamicColorEnabled) {
      return null;
    }

    try {
      final corePalette = await DynamicColorPlugin.getCorePalette();
      if (corePalette == null) {
        return null;
      }

      // Generate light scheme from dynamic palette with contrast level
      final lightScheme = ColorScheme.fromCorePalette(
        corePalette,
        brightness: Brightness.light,
        contrastLevel: themeState.contrastLevel,
      );

      // Generate dark scheme from dynamic palette with contrast level
      final darkScheme = ColorScheme.fromCorePalette(
        corePalette,
        brightness: Brightness.dark,
        contrastLevel: themeState.contrastLevel,
      );

      return ColorSchemes(
        light: lightScheme,
        dark: darkScheme,
      );
    } catch (e) {
      // If dynamic color fails, fall back to seed color
      return null;
    }
  }

  /// Wrapper class for holding both light and dark color schemes
  static class ColorSchemes {
    final ColorScheme light;
    final ColorScheme dark;

    const ColorSchemes({
      required this.light,
      required this.dark,
    });
  }
}
