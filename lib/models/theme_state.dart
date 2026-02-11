import 'package:flutter/material.dart';

/// Theme mode enum for the application
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

  /// Contrast level for accessibility (standard or high)
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
      'seedColorValue': seedColor.value,
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
      seedColor: Color(json['seedColorValue'] ?? Colors.blue.value),
      isDynamicColorEnabled: json['isDynamicColorEnabled'] ?? true,
      isTrueBlackEnabled: json['isTrueBlackEnabled'] ?? false,
      contrastLevel: json['contrastLevel']?.toDouble() ?? 0.0,
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
