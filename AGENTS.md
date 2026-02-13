# Agent Guidelines for yusa_box

This repository uses Flutter 3+ with Dart SDK ^3.11.0, Riverpod for state management, and Hive for local database. Follow these guidelines when working with this codebase.

## Build, Lint, and Test Commands

### Essential Commands
```bash
flutter analyze                    # Run static analysis (linting)
flutter test                       # Run all tests
flutter test test/my_test.dart     # Run single test file
flutter test --name="testName"     # Run tests matching name pattern
flutter test --coverage            # Run tests with coverage
flutter run                        # Run app on connected device/emulator
flutter build apk --release        # Build Android APK (unsigned)
flutter build ios                  # Build iOS application
flutter pub get                    # Install dependencies
flutter pub upgrade                # Upgrade dependencies
dart format .                      # Format code
```

### Code Generation
```bash
flutter pub run build_runner build      # Generate Riverpod code
flutter pub run build_runner watch      # Watch mode for code generation
```

## Code Style Guidelines

### Imports
Group imports in this order with blank lines between groups:
1. Flutter SDK imports
2. Third-party package imports (Riverpod, Hive, HTTP, etc.)
3. Local file imports (relative paths)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/vpn_models.dart';
import 'services/database_service.dart';
```

### Formatting
- Use `dart format .` for consistent formatting
- Use 2-space indentation
- Max line length: 80 characters
- **Use single quotes for strings** (project convention)
- Use trailing commas in multi-line lists and function calls
- Prefer `const` constructors for immutable widgets

### Naming Conventions
- **Classes**: PascalCase (e.g., `VPNServer`, `VPNSubscription`)
- **Functions/Methods**: camelCase (e.g., `_loadSubscriptions`, `fetchData`)
- **Variables**: camelCase (e.g., `_subscriptions`, `userName`)
- **Private members**: Prefix with underscore (e.g., `_privateMethod`, `_selectedServer`)
- **Files**: snake_case (e.g., `database_service.dart`, `vpn_models.dart`)
- **Enums**: camelCase for values (e.g., `SortOption { name, ping }`)

### Type Annotations
- Explicitly type public API members
- Use `var` for local variables when type is obvious
- Use `final` for variables that won't be reassigned
- Always specify return types for public functions
- Use `?` for nullable types

```dart
class VPNServer {
  final String id;
  String name;
  String? path;  // Nullable
  
  VPNServer({
    required this.id,
    required this.name,
    this.path,
  });
  
  Map<String, dynamic> toJson() => {...};
}
```

### Error Handling
- Use `try-catch` for async operations
- Use `debugPrint` instead of `print` (avoid_print lint enabled)
- Don't expose sensitive data in error messages
- Save data immediately after async operations, don't wait for UI updates

```dart
Future<void> fetchData() async {
  try {
    final data = await api.fetch();
    // Save data immediately, outside of mounted check
    await _saveToDatabase(data);
    
    if (mounted) {
      setState(() => _data = data);
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

### State Management (Riverpod)
- Use `ConsumerWidget` and `ConsumerStatefulWidget` for widgets
- Use `WidgetRef ref` to watch providers
- Keep providers in separate files under `providers/`

```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    return Container();
  }
}
```

### Database (Hive)
- Use `DatabaseService` for all database operations
- Initialize Hive in `main()` before `runApp()`
- Don't store BuildContext-related operations in database layer

```dart
// In main.dart
await DatabaseService.initialize();

// Usage
await DatabaseService.saveSubscriptions(_subscriptions);
```

### Widgets
- Use `const` constructors whenever possible
- Separate business logic into services/models
- Keep build methods focused on UI
- Use `super.key` in constructor parameters

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});
  
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
```

### Linting
This project uses `flutter_lints` with these active rules:
- `avoid_print`: Use `debugPrint` instead
- All Flutter/Dart recommended lints active

Suppress lint for a line:
```dart
// ignore: lint_name
```

Suppress for entire file:
```dart
// ignore_for_file: lint_name
```

## Project Structure

```
lib/
  main.dart                    # App entry point
  models/                      # Data models (VPN models)
  services/                    # Business logic (database, VPN, subscriptions)
  providers/                   # Riverpod providers (theme, etc.)
  theme.dart                   # Theme configuration
  strings.dart                 # Localization strings
test/                          # Unit and widget tests
android/                       # Android native code
analysis_options.yaml          # Dart analyzer configuration
pubspec.yaml                   # Dependencies
```

## Key Dependencies
- **flutter_riverpod**: State management
- **hive/hive_flutter**: Local database
- **dynamic_color**: Material You dynamic colors
- **http**: HTTP requests
- **shared_preferences**: Simple key-value storage
- **build_runner**: Code generation for Riverpod

## Testing Guidelines
- Mirror `lib/` structure in `test/`
- Use `flutter_test` framework
- Mock external dependencies
- Test both success and error cases
- Widget tests for UI components
