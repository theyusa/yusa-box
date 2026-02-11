# Theme Management System Documentation

## Overview

This Flutter application implements a robust Theme Management system inspired by `flutter_server_box`, featuring Material 3 design with dynamic color support, true black (OLED) mode, and accessibility features.

## Architecture

### State Management
- **Provider**: `flutter_riverpod` with `Notifier` pattern
- **Code Generation**: Uses `riverpod_generator` for type-safe providers
- **Persistence**: `shared_preferences` for storing theme settings locally

### Key Components

#### 1. ThemeState (`lib/models/theme_state.dart`)
Data model holding all theme-related settings:
- `themeMode`: Enum (system, light, dark)
- `seedColor`: Custom Color for theme generation
- `isDynamicColorEnabled`: Boolean for Monet support
- `isTrueBlackEnabled`: Boolean for OLED optimization
- `contrastLevel`: Double (0.0 = standard, 1.0 = high contrast)

#### 2. ThemeNotifier (`lib/providers/theme_provider.dart`)
Controller that manages theme state with persistence:
- Loads settings from SharedPreferences on app start
- Provides methods to update theme settings
- Automatically saves changes to local storage

#### 3. ThemeGenerator (`lib/utils/theme_generator.dart`)
Utility class for generating ThemeData:
- Generates light/dark themes from ColorScheme
- Applies true black (OLED) override
- Supports dynamic color extraction
- Applies contrast levels for accessibility

#### 4. Integration (`lib/main.dart`)
- Wraps app with `ProviderScope`
- Uses `DynamicColorBuilder` for Monet support
- Consumes `themeProvider` for reactive updates

## Features

### 1. Theme Modes
Three modes supported:
- **System**: Follows device theme
- **Light**: Force light theme
- **Dark**: Force dark theme

Implementation:
```dart
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode toThemeMode() { /* conversion logic */ }
}
```

### 2. Dynamic Color (Monet)
Extracts colors from Android 12+ wallpaper:

```dart
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    if (themeState.isDynamicColorEnabled && lightDynamic != null) {
      lightScheme = lightDynamic.harmonized();
      darkScheme = darkDynamic.harmonized();
    } else {
      // Use seed color
      lightScheme = ColorScheme.fromSeed(seedColor: seedColor, ...);
      darkScheme = ColorScheme.fromSeed(seedColor: seedColor, ...);
    }
  },
)
```

### 3. Custom Seed Color
When dynamic color is disabled, users can pick a custom seed color:

```dart
ColorScheme.fromSeed(
  seedColor: themeState.seedColor,
  brightness: Brightness.light,
  contrastLevel: themeState.contrastLevel,
)
```

### 4. True Black (OLED) Mode
Overrides surface colors with pure black (#000000) in dark mode:

```dart
if (themeState.isTrueBlackEnabled) {
  surfaceColor = const Color(0xFF000000);
  darkScheme = darkScheme.copyWith(
    surface: surfaceColor,
    scaffoldBackgroundColor: surfaceColor,
  );
}
```

Benefits:
- Saves battery on OLED screens
- Better contrast for readability
- True blacks instead of dark grey

### 5. High Contrast Mode
Adjusts `ColorScheme.contrastLevel` for accessibility:

```dart
ColorScheme.fromSeed(
  seedColor: seedColor,
  contrastLevel: themeState.contrastLevel, // 0.0 or 1.0
)
```

- **0.0**: Standard contrast (default)
- **1.0**: High contrast (improved readability)

## ColorScheme.fromSeed Explained

Material 3's `ColorScheme.fromSeed` generates a complete color palette from a single seed color:

```dart
ColorScheme.fromSeed({
  required Color seedColor,
  required Brightness brightness,
  double contrastLevel = 0.0,
})
```

### What it generates:
- **Primary colors**: Main brand colors
- **Secondary colors**: Accent colors
- **Tertiary colors**: Additional accents
- **Error colors**: Error/warning states
- **Container colors**: Background/surface variants
- **On colors**: Text/icon colors for each background

### Example:
```dart
// Seed color: Blue
final scheme = ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.dark,
);

// Generates:
// - primary: Various shades of blue
// - secondary: Purple tones
// - tertiary: Teal tones
// - surface: Dark blue-grey
// - onSurface: White/off-white
```

## Usage

### Setting Theme Mode
```dart
ref.read(themeProvider.notifier).setThemeMode(AppThemeMode.dark);
```

### Toggling True Black
```dart
ref.read(themeProvider.notifier).toggleTrueBlack();
```

### Changing Seed Color
```dart
ref.read(themeProvider.notifier).setSeedColor(Colors.red);
```

### Toggling High Contrast
```dart
ref.read(themeProvider.notifier).toggleContrastMode();
```

## Theme Settings UI

The Settings screen includes:
1. **Theme Mode Selector**: Choose between System/Light/Dark
2. **Dynamic Color Toggle**: Enable/disable Monet
3. **Seed Color Picker**: Select custom color (when dynamic off)
4. **True Black Toggle**: OLED optimization (dark mode only)
5. **High Contrast Toggle**: Accessibility mode

## Storage Structure

Settings are stored in SharedPreferences:

| Key | Type | Value |
|------|------|-------|
| `theme_mode` | int | ThemeMode index (0-2) |
| `seed_color_value` | int | Color ARGB value |
| `is_dynamic_color_enabled` | bool | Dynamic color toggle |
| `is_true_black_enabled` | bool | True black toggle |
| `contrast_level` | double | Contrast level (0.0 or 1.0) |

## Benefits of This Implementation

1. **Separation of Concerns**: State, logic, and UI are separate
2. **Type Safety**: Riverpod with code generation prevents runtime errors
3. **Persistence**: Settings survive app restarts
4. **Reactivity**: UI updates automatically when theme changes
5. **Accessibility**: High contrast mode for better readability
6. **Battery Optimization**: True black mode for OLED displays
7. **Platform Integration**: Dynamic color matches system wallpaper

## Running Code Generation

After modifying providers, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  dynamic_color: ^1.6.9
  shared_preferences: ^2.2.2

dev_dependencies:
  build_runner: ^2.4.13
  riverpod_generator: ^2.4.0
```

## Migration Notes

When migrating from the old theme system:
1. Wrap `MaterialApp` with `ProviderScope`
2. Replace static theme data with `DynamicColorBuilder`
3. Consume `themeProvider` instead of local state
4. Update settings UI to use new theme controls
