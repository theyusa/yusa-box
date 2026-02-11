# Agent Guidelines for yusa_box

This repository uses Flutter 3+ with Dart SDK ^3.11.0. Follow these guidelines when working with this codebase.

## Build, Lint, and Test Commands

### Essential Commands
- `flutter analyze` - Run static analysis (linting)
- `flutter test` - Run all tests
- `flutter test test/my_test.dart` - Run single test file
- `flutter run` - Run the app on connected device/emulator
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS application
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Running Specific Tests
```bash
# Run tests matching a name pattern
flutter test --name="testName"

# Run tests in a specific file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

## Code Style Guidelines

### Imports
- Use absolute imports for package dependencies
- Group imports: Flutter packages → Third-party packages → Local files
- Separate groups with blank lines
- Use `package:` for local lib imports

Example:
```dart
import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:yusa_box/services/api_service.dart';
```

### Formatting
- Use Dart formatter: `dart format .` (or `flutter format .`)
- Use 2-space indentation
- Max line length: 80 characters
- Prefer double quotes for strings
- Use trailing commas in multi-line lists and function calls

### Naming Conventions
- **Classes**: PascalCase (e.g., `MyHomePage`, `DataModel`)
- **Functions/Methods**: camelCase (e.g., `_incrementCounter`, `fetchData`)
- **Variables**: camelCase (e.g., `_counter`, `userName`)
- **Constants**: lowerCamelCase with leading underscore for private (e.g., `_maxItems`)
- **Files**: snake_case (e.g., `api_service.dart`, `user_model.dart`)
- **Private members**: Prefix with underscore (e.g., `_privateMethod`, `_localVariable`)
- **Widget types**: PascalCase suffix (e.g., `MyHomePageState`, `CustomButtonWidget`)

### Type Annotations
- Explicitly type public API members
- Use `var` for local variables when type is obvious
- Use `final` for variables that won't be reassigned
- Always specify return types for public functions
- Use `?` for nullable types, `!` for null assertion when guaranteed non-null

Example:
```dart
class User {
  final String name;
  final int? age;
  
  const User({required this.name, this.age});
  
  String get displayName => name;
}

void processData(String input) {
  final result = input.length;
}
```

### Error Handling
- Use `try-catch` blocks for exception handling
- Prefer `Exception` and custom exception classes
- Use `throw` for unrecoverable errors
- Return `Result` types or nullable types for expected failures
- Log errors appropriately but don't expose sensitive data

Example:
```dart
Future<User?> fetchUser(String id) async {
  try {
    final data = await api.get('/users/$id');
    return User.fromJson(data);
  } on NetworkException catch (e) {
    debugPrint('Network error: $e');
    return null;
  } catch (e) {
    debugPrint('Unexpected error: $e');
    rethrow;
  }
}
```

### Widgets
- Use `const` constructors for widgets whenever possible
- Separate business logic into models/services/repositories
- Keep widget build methods focused on UI composition
- Use `const` for all static widgets and icons
- Prefer `StatefulWidget` only when state management is required

Example:
```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});
  
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

### Asynchronous Code
- Use `async/await` over `.then()` chains
- Handle exceptions in async functions
- Use `FutureBuilder` or proper state management for async UI
- Cancel subscriptions and dispose controllers properly

### Linting
This project uses `flutter_lints` with the following notable rules:
- `avoid_print` enabled (use `debugPrint` instead)
- `prefer_single_quotes` available but not enforced
- All Flutter/Dart recommended lints active

To suppress a lint for a line:
```dart
// ignore: lint_name
```

To suppress for an entire file:
```dart
// ignore_for_file: lint_name
```

## Project Structure

```
lib/
  main.dart              # App entry point
test/                    # Unit and widget tests
android/                 # Android native code
analysis_options.yaml    # Dart analyzer configuration
pubspec.yaml            # Dependencies and project config
```

## Testing
- Place tests in `test/` directory mirroring `lib/` structure
- Use `flutter_test` framework
- Mock dependencies appropriately
- Test both happy paths and error cases
- Aim for meaningful test coverage
