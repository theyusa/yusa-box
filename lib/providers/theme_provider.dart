import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode enum for application
enum AppThemeMode {
  system,
  light,
  dark;

  /// Converts to Flutter's ThemeMode
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Creates from Flutter's ThemeMode
  static AppThemeMode fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppThemeMode.system;
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
    }
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}

/// Theme state holding all theme-related settings
class ThemeState {
  /// Current theme mode (system, light, dark)
  final AppThemeMode themeMode;

  /// Seed color for theme generation
  final Color seedColor;

  /// Whether to use dynamic color (Android 12+ wallpaper extraction)
  final bool isDynamicColorEnabled;

  /// Whether to enable true black (OLED) mode in dark theme
  final bool isTrueBlackEnabled;

  /// Contrast level for accessibility
  /// Range: -1.0 (low) to 1.0 (high)
  /// Standard: 0.0, High Contrast: 1.0
  final double contrastLevel;

  const ThemeState({
    this.themeMode = AppThemeMode.system,
    this.seedColor = Colors.blue,
    this.isDynamicColorEnabled = true,
    this.isTrueBlackEnabled = false,
    this.contrastLevel = 0.0,
  });

  /// Creates a copy with modified fields
  ThemeState copyWith({
    AppThemeMode? themeMode,
    Color? seedColor,
    bool? isDynamicColorEnabled,
    bool? isTrueBlackEnabled,
    double? contrastLevel,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      isDynamicColorEnabled: isDynamicColorEnabled ?? this.isDynamicColorEnabled,
      isTrueBlackEnabled: isTrueBlackEnabled ?? this.isTrueBlackEnabled,
      contrastLevel: contrastLevel ?? this.contrastLevel,
    );
  }

  /// Converts to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'seedColorValue': seedColor.toARGB32(),
      'isDynamicColorEnabled': isDynamicColorEnabled,
      'isTrueBlackEnabled': isTrueBlackEnabled,
      'contrastLevel': contrastLevel,
    };
  }

  /// Creates from JSON
  factory ThemeState.fromJson(Map<String, dynamic> json) {
    return ThemeState(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      seedColor: Color(json['seedColorValue'] ?? Colors.blue.toARGB32()),
      isDynamicColorEnabled: json['isDynamicColorEnabled'] ?? true,
      isTrueBlackEnabled: json['isTrueBlackEnabled'] ?? false,
      contrastLevel: (json['contrastLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          seedColor == other.seedColor &&
          isDynamicColorEnabled == other.isDynamicColorEnabled &&
          isTrueBlackEnabled == other.isTrueBlackEnabled &&
          contrastLevel == other.contrastLevel;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      seedColor.hashCode ^
      isDynamicColorEnabled.hashCode ^
      isTrueBlackEnabled.hashCode ^
      contrastLevel.hashCode;
}

/// ThemeNotifier manages theme state with persistence
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _loadThemeSettings();
    return const ThemeState();
  }

  /// Keys for storing theme preferences in SharedPreferences
  static const String _keyThemeMode = 'theme_mode';
  static const String _keySeedColor = 'seed_color_value';
  static const String _keyDynamicColor = 'is_dynamic_color_enabled';
  static const String _keyTrueBlack = 'is_true_black_enabled';
  static const String _keyContrastLevel = 'contrast_level';

  /// Load theme settings from SharedPreferences
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeModeIndex = prefs.getInt(_keyThemeMode);
      final seedColorValue = prefs.getInt(_keySeedColor);
      final isDynamicColorEnabled = prefs.getBool(_keyDynamicColor);
      final isTrueBlackEnabled = prefs.getBool(_keyTrueBlack);
      final contrastLevel = prefs.getDouble(_keyContrastLevel);

      final themeMode = themeModeIndex != null &&
              themeModeIndex >= 0 &&
              themeModeIndex < AppThemeMode.values.length
          ? AppThemeMode.values[themeModeIndex]
          : AppThemeMode.system;

      state = ThemeState(
        themeMode: themeMode,
        seedColor: seedColorValue != null
            ? Color(seedColorValue)
            : Colors.blue,
        isDynamicColorEnabled: isDynamicColorEnabled ?? true,
        isTrueBlackEnabled: isTrueBlackEnabled ?? false,
        contrastLevel: contrastLevel?.clamp(-1.0, 1.0) ?? 0.0,
      );
    } catch (e) {
      // Use default settings on error
      state = const ThemeState();
    }
  }

  /// Save all theme settings to SharedPreferences
  Future<void> _saveThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, state.themeMode.index);
      await prefs.setInt(_keySeedColor, state.seedColor.toARGB32());
      await prefs.setBool(_keyDynamicColor, state.isDynamicColorEnabled);
      await prefs.setBool(_keyTrueBlack, state.isTrueBlackEnabled);
      await prefs.setDouble(_keyContrastLevel, state.contrastLevel);
    } catch (e) {
      // Log error but don't crash
      debugPrint('Error saving theme settings: $e');
    }
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
    final newMode =
        state.themeMode == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
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
  /// Level should be between -1.0 (low) and 1.0 (high)
  Future<void> setContrastLevel(double level) async {
    state = state.copyWith(contrastLevel: level.clamp(-1.0, 1.0));
    await _saveThemeSettings();
  }

  /// Toggle between standard (0.0) and high contrast (1.0)
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
