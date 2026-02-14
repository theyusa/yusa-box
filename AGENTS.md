# Agent Guidelines for YusaBox VPN

This is a Flutter 3+ project with SingBox VPN core integration using Riverpod state management and Hive for local database.

## Build, Lint, and Test Commands

**IMPORTANT**: Flutter is not in system PATH. Use full path: `~/v2/flutter/bin/flutter`

```bash
# Flutter Commands
~/v2/flutter/bin/flutter analyze                    # Run static analysis (run before commits)
~/v2/flutter/bin/flutter test                       # Run all tests
~/v2/flutter/bin/flutter test test/my_test.dart     # Run single test file
~/v2/flutter/bin/flutter test --name="testName"     # Run tests matching pattern
~/v2/flutter/bin/flutter run                        # Run app on device/emulator
~/v2/flutter/bin/flutter build apk --release        # Build Android release APK
~/v2/flutter/bin/flutter clean                     # Clean build artifacts

# Dependency Management
~/v2/flutter/bin/flutter pub get                    # Install dependencies
~/v2/flutter/bin/flutter pub run build_runner build    # Generate Riverpod/Hive code
~/v2/flutter/bin/dart run flutter_launcher_icons   # Generate app icons

# Android Commands (run from android/ directory)
./gradlew assembleRelease                      # Build APK directly with Gradle
./gradlew clean                                 # Clean Gradle build
pkill -f gradle                              # Kill stuck Gradle daemon

# Android Debugging
adb logcat -c                                   # Clear logcat
adb logcat -s SingBoxVpnService:* MainActivity:* VpnServiceManager:* SingBoxWrapper:* AndroidRuntime:E DEBUG
adb shell ps | grep yusabox                  # Check if app is running
```

## Code Style Guidelines

### Imports
Group imports in order with blank lines between groups:

```dart
// Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Third-party packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

// Project-local imports (relative paths)
import 'models/vpn_models.dart';
import 'services/database_service.dart';
import 'services/vpn_service.dart';
```

**Kotlin imports:**
```kotlin
// Android Framework
import android.app.Notification
import android.net.VpnService
import android.util.Log

// AndroidX
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

// Flutter
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

// Project-local
import com.yusabox.vpn.SingBoxWrapper
```

### Formatting
- Use 2-space indentation
- 80 character max line length for Flutter code
- **Use single quotes for strings** (project convention)
- Use trailing commas in multi-line lists/function calls
- Prefer `const` constructors for immutable widgets

### Naming Conventions
- **Dart Classes**: PascalCase (`VpnServer`, `VPNSubscription`, `PingResult`)
- **Dart Functions/Methods**: camelCase (`_loadSubscriptions`, `fetchData`)
- **Dart Variables**: camelCase (`_subscriptions`, `userName`)
- **Dart Private members**: Prefix with underscore (`_privateMethod`, `_selectedServer`)
- **Dart Files**: snake_case (`database_service.dart`, `ping_service.dart`)
- **Dart Enums**: camelCase values (`SortOption { name, ping }`)

- **Kotlin Classes**: PascalCase (`SingBoxVpnService`, `VpnServiceManager`)
- **Kotlin Objects**: PascalCase (`SingBoxWrapper`, object definitions)
- **Kotlin Variables**: camelCase
- **Kotlin Constants**: UPPER_SNAKE_CASE (`ACTION_START`, `EXTRA_CONFIG`)

### Type Annotations
- Explicitly type public API members
- Use `var` for local variables when type is obvious
- Use `final` for variables that won't be reassigned
- Always specify return types for public functions
- Use `?` for nullable types (Dart and Kotlin)
- Use `!` for non-null assertions in Dart when safe

### Error Handling
**Dart:**
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

**Kotlin:**
- Use specific exception types (IllegalStateException, IllegalArgumentException, SecurityException)
- Never crash silently - always log exceptions
- Use proper error codes and messages for Flutter communication
- Validate inputs before processing
- Add extensive logging for debugging VPN issues

```kotlin
private fun startVpn(config: String) {
  try {
    if (!isLibraryLoaded) {
      throw IllegalStateException("SingBox library not loaded")
    }
    if (config.isEmpty()) {
      throw IllegalArgumentException("Config is empty")
    }
    
    Log.i(TAG, "Starting VPN with server: $serverName")
    // VPN logic...
  } catch (e: IllegalStateException) {
    Log.e(TAG, "IllegalStateException: ${e.message}", e)
    VpnServiceManager.updateStatus(STATE_ERROR, "Sistem hatası")
  } catch (e: Exception) {
    Log.e(TAG, "VPN connection error", e)
    e.printStackTrace()
    VpnServiceManager.updateStatus(STATE_ERROR, "Hata")
  }
}
```

## Flutter Specific Guidelines

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
- Prefer `const` constructors for widgets that don't change

### JSON Config Handling
- Store raw config as JSON string in `config` field
- Use `parsedData` getter to access as Map<String, dynamic>
- Update fields using `updateField()` method for dual field updates

### Flutter Linting
This project uses `flutter_lints` with `avoid_print` active.
Suppress: `// ignore: lint_name` or `// ignore_for_file: lint_name`

## Android Native Guidelines

### VPN Service Pattern
- Extend `VpnService` from Android framework
- Use `VpnService.Builder` to establish VPN interface
- Start foreground service before VPN connection
- Use `ServiceCompat.stopForeground()` for Android 14+ (fixes deprecation warning)
- Register network callback for connectivity changes
- Handle VPN permission request in `MainActivity`
- Implement auto-retry mechanism with max attempt limit

### Native Library Integration (SingBox)
- Use wrapper object (`SingBoxWrapper`) for JNI access
- Load library once in init block with try-catch
- Validate library loaded before any native calls
- Use external function declarations with proper types
- Handle `UnsatisfiedLinkError` for library loading failures

### MethodChannel Communication
- Define unique channel names: `com.yusabox.vpn/SERVICE_NAME`
- Use `MethodChannel` for Flutter→Native calls
- Use `EventChannel` for Native→Flutter streaming
- Always validate parameters before processing
- Use `MethodChannel.Result` for async responses
- Return proper error codes and messages for Flutter

### EventChannel Streaming
- Define stream handlers as object implementing `EventChannel.StreamHandler`
- Use `Handler(Looper.getMainLooper()).post {}` for UI thread updates
- Use object companion pattern for state management
- Clean up event sink on cancel

### Error States
```kotlin
const val STATE_DISCONNECTED = 0
const val STATE_CONNECTING = 1
const val STATE_CONNECTED = 2
const val STATE_ERROR = 4
```

### Notifications
- Create notification channel for Android 8+
- Use ongoing notifications for VPN active state
- Include pending intent to launch app on tap
- Update notification text based on connection state

## Project Structure
```
lib/
  main.dart                    # App entry point with VPNHomePage
  models/                      # Data models
    vpn_models.dart           # VpnServer, VPNSubscription
    singbox_config.dart       # SingBox config builder
    vpn_settings.dart          # VPN settings (DNS, route, etc.)
  services/                    # Business logic
    database_service.dart      # Hive operations
    vpn_service.dart         # MethodChannel wrapper
    ping_service.dart        # Ping testing
    subscription_service.dart # Subscription fetching
    speed_test_service.dart  # Speed testing
  providers/                   # Riverpod providers
    theme_provider.dart       # Theme management
  theme.dart                   # Theme configuration
  strings.dart                 # Localization strings (TR, EN)

android/
  app/
    build.gradle.kts         # App build config
    src/main/kotlin/com/yusabox/vpn/
      MainActivity.kt          # Flutter integration
      SingBoxVpnService.kt  # VPN service
      VpnServiceManager.kt     # Service state management
      SingBoxWrapper.kt       # JNI wrapper
      SpeedTestServiceManager.kt
      PingServiceManager.kt
    libs/
      libbox.aar              # SingBox native library

test/
  # Unit and widget tests
```

## Key Dependencies

### Flutter
- **flutter_riverpod**: State management
- **riverpod_annotation**: Code generation annotations
- **riverpod_generator**: Code generation
- **riverpod_lint**: Riverpod linting rules
- **hive/hive_flutter**: Local database (HiveBox)
- **http**: HTTP requests for subscriptions
- **shared_preferences**: Simple key-value storage
- **dynamic_color**: Material You dynamic colors
- **share_plus**: File/content sharing
- **path_provider**: File system access

### Android
- **libbox.aar**: SingBox VPN core library (JNI package: io.nekohasekai.libbox)

## Testing Guidelines

### Writing Tests
- Test files go in `test/` directory
- Test file names: `*_test.dart`
- Use `testWidgets` for widget tests
- Use `test` for unit tests
- Mock services and providers for isolated testing
- Test edge cases for VPN states (connecting, connected, error)

### Running Tests
```bash
# Run specific test
~/v2/flutter/bin/flutter test test/ping_service_test.dart

# Run tests matching pattern
~/v2/flutter/bin/flutter test --name="ping"

# Run with coverage
~/v2/flutter/bin/flutter test --coverage
```

## VPN Configuration Patterns

### Supported Protocols
- **VLESS**: With TLS, Reality, WebSocket, gRPC support
- **VMess**: With TLS, WebSocket, gRPC support
- **Trojan**: With TLS, WebSocket, gRPC support

### Config Structure
```dart
{
  "log": {"level": "trace"},
  "dns": DNS config,
  "experimental": experimental config,
  "inbounds": [tun, mixed],
  "outbounds": [proxy, direct, bypass],
  "route": routing config
}
```

### Server Selection Flow
1. User taps server in list → Sets `_selectedServer`
2. Tap "Connect" button → Calls `_generateSingboxConfig(server)`
3. Convert to SingBox JSON → Calls `VpnService.startVpn(config, serverName)`
4. MainActivity forwards to SingBoxVpnService → VPN connects
5. Status updates via EventChannel → UI updates in real-time

## Debugging VPN Issues

### Common Crash Points
1. **Library loading failure**: Check `libbox.aar` is in `android/app/libs/`
2. **Config validation error**: Verify JSON has outbounds array
3. **VPN interface failure**: Check Android VPN permission
4. **JNI crashes**: Check library version matches JNI signatures

### Debugging Steps
1. Run `adb logcat -c` to clear logs
2. Filter logs: `adb logcat -s SingBoxVpnService:* MainActivity:* VpnServiceManager:*`
3. Reproduce crash with specific server
4. Look for exceptions and error codes
5. Check log sequence for flow understanding

### Log Messages
- `[INFO]`: Normal operation messages
- `[WARN]`: Non-critical warnings
- `[ERROR]`: Error conditions
- `[NATIVE]`: Android/VPN service messages
- Prefix with timestamp for debugging

## Android Specific Notes

### Gradle Build Issues
- If Gradle daemon crashes: Run `pkill -f gradle` before build
- Use `./gradlew assembleRelease` directly for faster builds
- Check `./gradlew clean` if cache issues occur

### VPN Permissions
- `BIND_VPN_SERVICE`: Required for VPN apps
- `FOREGROUND_SERVICE`: Required for background service
- `INTERNET`: Required for network access
- `ACCESS_NETWORK_STATE`: Required for network monitoring

### Android Compatibility
- Minimum SDK: Typically 21+ (Android 5.0)
- Target SDK: Latest stable
- Use `ServiceCompat` for Android 14+ compatibility

## Important Reminders

1. **Always run `flutter analyze` before committing** - Fixes issues early
2. **Never commit secrets** - Don't commit `.env`, credentials, API keys
3. **Test VPN connection** after code changes - VPN integration is critical
4. **Log extensively** when debugging native issues - Helps identify crash points
5. **Check AAR library** version - Must match JNI signatures
6. **Validate JSON configs** - Invalid configs cause crashes
7. **Use proper error handling** - Never let exceptions crash the app silently
