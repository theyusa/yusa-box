import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_state.dart';

/// Keys for storing theme preferences in SharedPreferences
class _ThemeStorageKeys {
  static const String themeMode = 'theme_mode';
  static const String seedColorValue = 'seed_color_value';
  static const String isDynamicColorEnabled = 'is_dynamic_color_enabled';
  static const String isTrueBlackEnabled = 'is_true_black_enabled';
  static const String contrastLevel = 'contrast_level';
}

/// ThemeNotifier manages theme state with persistence
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _loadThemeSettings();
    return const ThemeState();
  }

  /// Load theme settings from SharedPreferences
  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_ThemeStorageKeys.themeMode);
    final seedColorValue = prefs.getInt(_ThemeStorageKeys.seedColorValue);
    final isDynamicColorEnabled = prefs.getBool(_ThemeStorageKeys.isDynamicColorEnabled);
    final isTrueBlackEnabled = prefs.getBool(_ThemeStorageKeys.isTrueBlackEnabled);
    final contrastLevel = prefs.getDouble(_ThemeStorageKeys.contrastLevel);

    final themeMode = themeModeIndex != null && themeModeIndex < AppThemeMode.values.length
        ? AppThemeMode.values[themeModeIndex]
        : AppThemeMode.system;

    state = ThemeState(
      themeMode: themeMode,
      seedColor: seedColorValue != null ? Color(seedColorValue) : Colors.blue,
      isDynamicColorEnabled: isDynamicColorEnabled ?? true,
      isTrueBlackEnabled: isTrueBlackEnabled ?? false,
      contrastLevel: contrastLevel ?? 0.0,
    );
  }

  /// Save all theme settings to SharedPreferences
  Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ThemeStorageKeys.themeMode, state.themeMode.index);
    await prefs.setInt(_ThemeStorageKeys.seedColorValue, state.seedColor.value);
    await prefs.setBool(_ThemeStorageKeys.isDynamicColorEnabled, state.isDynamicColorEnabled);
    await prefs.setBool(_ThemeStorageKeys.isTrueBlackEnabled, state.isTrueBlackEnabled);
    await prefs.setDouble(_ThemeStorageKeys.contrastLevel, state.contrastLevel);
  }

  /// Update theme mode and save to storage
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveThemeSettings();
  }

  /// Toggle between light and dark mode (when not in system mode)
  Future<void> toggleThemeMode() async {
    if (state.themeMode == AppThemeMode.system) {
      return;
    }
    final newMode = state.themeMode == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
    state = state.copyWith(themeMode: newMode);
    await _saveThemeSettings();
  }

  /// Update seed color and save to storage
  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    await _saveThemeSettings();
  }

  /// Toggle dynamic color and save to storage
  Future<void> toggleDynamicColor() async {
    state = state.copyWith(isDynamicColorEnabled: !state.isDynamicColorEnabled);
    await _saveThemeSettings();
  }

  /// Set dynamic color state and save to storage
  Future<void> setDynamicColor(bool enabled) async {
    state = state.copyWith(isDynamicColorEnabled: enabled);
    await _saveThemeSettings();
  }

  /// Toggle true black (OLED) mode and save to storage
  Future<void> toggleTrueBlack() async {
    state = state.copyWith(isTrueBlackEnabled: !state.isTrueBlackEnabled);
    await _saveThemeSettings();
  }

  /// Set true black mode state and save to storage
  Future<void> setTrueBlack(bool enabled) async {
    state = state.copyWith(isTrueBlackEnabled: enabled);
    await _saveThemeSettings();
  }

  /// Set contrast level and save to storage
  Future<void> setContrastLevel(double level) async {
    state = state.copyWith(contrastLevel: level);
    await _saveThemeSettings();
  }

  /// Toggle between standard and high contrast
  Future<void> toggleContrastMode() async {
    final newLevel = state.contrastLevel > 0 ? 0.0 : 1.0;
    state = state.copyWith(contrastLevel: newLevel);
    await _saveThemeSettings();
  }

  /// Reset all theme settings to default
  Future<void> resetToDefaults() async {
    state = const ThemeState();
    await _saveThemeSettings();
  }
}

/// Provider for theme state
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
  name: 'themeProvider',
);

/// Provider for accessing theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode.toThemeMode();
});

/// Provider for accessing seed color
final seedColorProvider = Provider<Color>((ref) {
  return ref.watch(themeProvider).seedColor;
});

/// Provider for checking if dynamic color is enabled
final isDynamicColorProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDynamicColorEnabled;
});

/// Provider for checking if true black is enabled
final isTrueBlackProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isTrueBlackEnabled;
});

/// Provider for accessing contrast level
final contrastLevelProvider = Provider<double>((ref) {
  return ref.watch(themeProvider).contrastLevel;
});
