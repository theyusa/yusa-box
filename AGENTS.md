# Agent Guidelines for yusa_box

This repository uses Flutter 3+ with Dart SDK ^3.11.0, Riverpod for state management, and Hive for local database. Follow these guidelines when working with this codebase.

## Build, Lint, and Test Commands

**IMPORTANT**: Flutter is not in system PATH. Use full path: `~/v2/flutter/bin/flutter`

```bash
~/v2/flutter/bin/flutter analyze                    # Run static analysis
~/v2/flutter/bin/flutter test                       # Run all tests
~/v2/flutter/bin/flutter test test/my_test.dart     # Run single test file
~/v2/flutter/bin/flutter test --name="testName"     # Run tests matching pattern
~/v2/flutter/bin/flutter run                        # Run app on device/emulator
~/v2/flutter/bin/flutter build apk --release        # Build Android APK
~/v2/flutter/bin/flutter pub get                    # Install dependencies
~/v2/flutter/bin/flutter pub run build_runner build    # Generate Riverpod/Hive code
~/v2/flutter/bin/dart run flutter_launcher_icons   # Generate app icons
```

## Code Style Guidelines

### Imports
Group imports in order: Flutter SDK → Third-party → Local (relative paths), with blank lines between groups.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/vpn_models.dart';
import 'services/database_service.dart';
```

### Formatting
- Use 2-space indentation, 80 char max line length
- **Use single quotes for strings** (project convention)
- Use trailing commas in multi-line lists/function calls
- Prefer `const` constructors for immutable widgets

### Naming Conventions
- Classes: PascalCase (`VPNServer`, `VPNSubscription`)
- Functions/Methods: camelCase (`_loadSubscriptions`, `fetchData`)
- Variables: camelCase (`_subscriptions`, `userName`)
- Private members: Prefix with underscore (`_privateMethod`)
- Files: snake_case (`database_service.dart`)
- Enums: camelCase values (`SortOption { name, ping }`)

### Type Annotations
- Explicitly type public API members
- Use `var` for local variables when type is obvious
- Use `final` for variables that won't be reassigned
- Always specify return types for public functions
- Use `?` for nullable types

### Error Handling
- Use `try-catch` for async operations
- Use `debugPrint` instead of `print` (avoid_print lint enabled)
- Save data immediately after async operations, outside mounted check
- Don't expose sensitive data in error messages

```dart
Future<void> fetchData() async {
  try {
    final data = await api.fetch();
    await _saveToDatabase(data);  // Save first
    
    if (mounted) {
      setState(() => _data = data);
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

### State Management (Riverpod)
- Use `ConsumerWidget` and `ConsumerStatefulWidget`
- Use `WidgetRef ref` to watch providers
- Use `ValueListenableBuilder` with HiveBox for reactive UI updates

### Database (Hive + HiveBox)
- Use `ServerService` for all server/subscription operations
- Initialize Hive in `main()` before `runApp()`
- Use `ValueListenableBuilder` for reactive database updates
- Direct HiveBox manipulation: `box.put()`, `box.get()`, `box.delete()`
- Server modifications: Store in `modifiedServersBox` for persistence

```dart
ValueListenableBuilder<Box<VpnServer>>(
  valueListenable: ServerService.serversListenable,
  builder: (context, box, _) {
    final servers = box.values.toList();
    return ListView.builder(...);
  },
)
```

### Widgets
- Separate business logic into services/models
- Keep build methods focused on UI
- Use `super.key` in constructor parameters

### JSON Config Handling
- Store raw config as JSON string in `config` field
- Use `parsedData` getter to access as Map<String, dynamic>
- Update fields using `updateField()` method for dual field updates

### Linting
This project uses `flutter_lints` with `avoid_print` active.
Suppress: `// ignore: lint_name` or `// ignore_for_file: lint_name`

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
```

## Key Dependencies
- **flutter_riverpod**: State management
- **hive/hive_flutter**: Local database (HiveBox)
- **dynamic_color**: Material You dynamic colors
- **http**: HTTP requests
- **shared_preferences**: Simple key-value storage
- **flutter_launcher_icons**: App icon generation
- **build_runner**: Code generation for Riverpod/Hive
