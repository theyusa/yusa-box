# Agent Guidelines for yusa_box

This repository is a Flutter application using Dart SDK ^3.11.0. It leverages **Riverpod** for state management and **build_runner** for code generation. The app focuses on VPN management with V2Ray/Singbox configurations.

## Build, Lint, and Test Commands

### Essential Commands
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis (linting)
- `flutter test` - Run all tests
- `dart run build_runner build -d` - Run code generation (once)
- `dart run build_runner watch -d` - Watch for changes and generate code
- `flutter run` - Run the app on connected device
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS application

### Testing
- **Run a single test file:** `flutter test test/path/to/file_test.dart`
- **Run tests by name:** `flutter test --name="description"`
- **Run with coverage:** `flutter test --coverage`

## Code Style & Conventions

### Imports
- **Absolute Imports:** Always use `package:yusa_box/...` for project files.
- **Ordering:**
  1. Dart SDK imports (e.g., `dart:async`)
  2. Flutter package imports (e.g., `package:flutter/material.dart`)
  3. Third-party package imports (e.g., `package:flutter_riverpod/flutter_riverpod.dart`)
  4. Project imports (e.g., `package:yusa_box/models/user.dart`)
- **Relative Imports:** Avoid relative imports unless strictly necessary for private implementation files within the same directory.

### Formatting & Syntax
- **Line Length:** 80 characters.
- **Indentation:** 2 spaces.
- **Quotes:** Prefer single quotes `'text'` over double quotes, unless the string contains single quotes.
- **Commas:** Use trailing commas `,` in argument lists, lists, and map literals to enforce multiline formatting.
- **Semicolons:** Don't forget them at the end of statements.

### Naming
- **Classes/Types:** `PascalCase` (e.g., `VPNServer`, `ThemeNotifier`).
- **Variables/Functions:** `camelCase` (e.g., `isConnected`, `refreshServers`).
- **Files:** `snake_case.dart` (e.g., `vpn_models.dart`, `theme_provider.dart`).
- **Constants:** `lowerCamelCase` (e.g., `kDefaultTimeout`) or `SCREAMING_SNAKE_CASE` for strictly static consts.
- **Riverpod Providers:** `camelCase` suffixed with `Provider` (e.g., `themeProvider`, `seedColorProvider`).

### Type Annotations
- **Strict Typing:** Always specify return types for functions and methods.
- **Inference:** Use `final` or `const` for local variables where type is obvious.
- **Null Safety:** Use `?` for nullable types. Avoid `!` (bang operator) unless absolutely certain. Prefer conditional access `?.` or `??` operators.

### Error Handling
- Use `try-catch` blocks for async operations and external calls.
- Catch specific exceptions (e.g., `on SocketException catch (e)`).
- Use a top-level error reporting mechanism or logging service (e.g., `debugPrint` or a logger).

## Architecture & State Management

### Riverpod
- **Providers:** Defined in `lib/providers/`.
- **Notifier:** Use `Notifier` and `NotifierProvider` for complex state (e.g., `ThemeNotifier`).
- **Read/Watch:**
  - Use `ref.watch` inside `build` methods for reactive updates.
  - Use `ref.read` inside callbacks (e.g., `onPressed`).
- **Immutability:** State classes (e.g., `ThemeState`) should be immutable with `copyWith` methods.

### Models
- Located in `lib/models/`.
- Simple data classes (e.g., `VPNServer`, `VPNSubscription`).
- Should handle JSON serialization/deserialization if needed.

### Localization
- Managed via `AppStrings` in `lib/strings.dart`.
- Access strings using `AppStrings.get('key')`.
- Support multiple languages (currently 'tr' and 'en').

### Theming
- Managed via `ThemeNotifier` in `lib/providers/theme_provider.dart`.
- Supports Light, Dark, and System modes.
- Supports Dynamic Color (Material You) and True Black (OLED) modes.

## Project Structure
```
lib/
  main.dart                  # Entry point and main UI logic
  strings.dart               # Localization string constants
  theme.dart                 # Static theme definitions
  models/                    # Data models
    vpn_models.dart          # VPN Server and Subscription models
  providers/                 # State management
    theme_provider.dart      # Theme state and logic
test/                        # Tests mirroring lib structure
```

## Linting
- Follow rules in `analysis_options.yaml` (based on `flutter_lints`).
- Fix all warnings before committing.
- Use `// ignore: lint_code` sparingly and only with a comment explaining why.
- Common issues to watch:
  - Unused imports
  - Deprecated members (e.g., `withOpacity` -> `withValues`)
  - Missing const constructors
