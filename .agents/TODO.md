# YusaBox Development Roadmap

## Current Stage: Native VPN Implementation (COMPLETED PHASE 1)

### Phase 1: Native SingBox Integration ✅ (COMPLETED)
- [x] AAR library research and architecture design
- [x] Build SingBox AAR with JNI wrapper
- [x] Implement real traffic stats (VpnService.protect())
- [x] Add native logging system
- [x] Implement foreground service notification
- [x] Add connection timeout handling
- [x] Implement error recovery with exponential backoff
- [x] Android 12+ compatibility (new VPN permission model)

### Phase 2: Advanced VPN Features (PLANLANMIŞ)
- [ ] Kill Switch (traffic leak detection)
- [ ] Auto-connect on app start
- [ ] Auto-reconnect on network change
- [ ] Clash API HTTP server (port 9090)
- [x] Speed test (real throughput measurement)
- [x] Ping test for all servers
- [ ] QR code scanner for config import
- [ ] Config export (JSON/YAML)

### Phase 3: UI/UX Improvements (PLANLANMIŞ)
- [ ] Server search and filter
- [ ] Server favorites
- [ ] Server groups (region/protocol)
- [ ] Traffic usage graphs (fl_chart)
- [ ] Connection history log
- [ ] Quick settings tile (Android 7+)
- [ ] Dark/Light theme (PARTIALLY COMPLETE)

### Phase 4: Advanced Protocols (PLANLANMIŞ)
- [ ] VLESS Reality support
- [ ] Hysteria2 protocol
- [ ] TUIC protocol
- [ ] WireGuard protocol
- [ ] Mux (multiplexing) configuration

---

## Issues & Bugs

### Critical Issues
- None (Flutter analyze passes)

### Known Issues
- None

### Fixes Applied
- ✅ Fixed subscription/server synchronization (Commit: 6c4fe64)
- ✅ Removed hardcoded configs and added VpnSettings (Commit: 6c4fe64)
- ✅ Integrated ipinfo.io API for dynamic geo detection (Commit: 6c4fe64)
- ✅ Removed Shadowsocks support (Commit: 6c4fe64)
- ✅ Fixed server deletion and subscription refresh logic (Commit: 6c4fe64)
- ✅ Implemented native SingBox VPN service with logging (Commit: 09fb5c2)
- ✅ Implemented connection retry with exponential backoff (Commit: 09fb5c2)
- ✅ Implemented network state monitoring (Commit: 09fb5c2)
- ✅ Implemented server name tracking and reconnect (Commit: 09fb5c2)
- ✅ Enhanced Flutter status stream with logs (Commit: 09fb5c2)
- ✅ Added reconnect button in VPN view (Commit: 09fb5c2)

---

## Completed Features

### ✅ Core VPN
- [x] Flutter UI with Material 3
- [x] Riverpod state management
- [x] Hive database (servers, subscriptions)
- [x] VpnService method channel wrapper
- [x] SingBox config builder (VLESS, VMess, Trojan)
- [x] Subscription URL parser (VLESS, VMess, Trojan)
- [x] IP Info API integration (country flags, cities)
- [x] Two-language support (TR, EN)

### ✅ Settings
- [x] Dynamic DNS configuration (4 servers)
- [x] Route mode options (proxy, direct, bypass, block)
- [x] Tun inbound settings (MTU, stack, sniff)
- [x] Mixed inbound (SOCKS/HTTP proxy)
- [x] VpnSettings class with persistence

### ✅ Native Implementation (NEW!)
- [x] Android VPN service (SingBoxVpnService.kt)
- [x] Method channel handlers (MainActivity.kt)
- [x] Event channel status stream (VpnServiceManager.kt)
- [x] Native logging system with timestamps
- [x] Real traffic stats infrastructure (VpnService.protect())
- [x] Connection retry with exponential backoff (3 attempts, 3s delay)
- [x] Network state monitoring (onAvailable/onLost)
- [x] Socket protection for all connections
- [x] Reconnect functionality (ACTION_RECONNECT)
- [x] Server name tracking (EXTRA_SERVER_NAME)
- [x] Enhanced foreground notifications (dynamic content)
- [x] Connection state management (0=disconnected, 1=connecting, 2=connected, 4=error)

### ✅ Flutter Service Layer (ENHANCED!)
- [x] Start VPN with server name parameter
- [x] Stop VPN method
- [x] Reconnect method
- [x] Get logs method
- [x] Enhanced status stream (log, server info, state)
- [x] Traffic stats (upload, download, uploadSpeed, downloadSpeed, connectedTime)

---

## Research Notes

### SingBox for Android Reference
- Repo: https://github.com/SagerNet/sing-box
- Docs: https://sing-box.sagernet.org
- Language: Go
- Core APIs: box.New(), box.Start(), box.Stop()
- Config: JSON format (outbounds, inbounds, dns, route)

### NekoBox Reference
- Repo: https://github.com/Ohayo18/NekoBoxForAndroid
- Features: V2Ray, XRay, Shadowsocks
- Android: Kotlin + JNI
- Native libs: V2Ray/XRay libraries

### Flutter SingBox Plugin
- Package: flutter_sing_box (v1.0.4)
- Features: Remote profile import, Clash API, VPN service management
- Platforms: Android + iOS

---

## Tech Stack

- **Frontend**: Flutter 3+, Dart ^3.11.0
- **State**: Riverpod ^2.5.1
- **Database**: Hive ^2.2.3, Hive Flutter ^1.1.0
- **Theme**: Material 3, Dynamic Color
- **Network**: HTTP ^1.2.0
- **Platform**: Android (Native Kotlin), iOS (Planned)

---

## Version History

### v1.0.2 (Current) - Native VPN Implementation ✅
- ✅ Implemented native SingBox VPN service with full features (Commit: 09fb5c2)
- ✅ Implemented connection retry with exponential backoff (3 attempts, 3s delay)
- ✅ Implemented network state monitoring (auto-reconnect on network restore)
- ✅ Implemented socket protection for all connections
- ✅ Added server name tracking and display
- ✅ Enhanced Flutter status stream with logs and connection info
- ✅ Added reconnect button in VPN view
- ✅ Updated TODO.md with comprehensive roadmap
- ✅ All Flutter analyze issues resolved (0 errors)

### v1.0.1
- Fixed subscription/server sync
- Removed hardcoded configs and added VpnSettings
- Integrated ipinfo.io API
- Removed Shadowsocks support
- Fixed server deletion and subscription refresh logic

### v1.0.0
- Initial commit
- Basic UI structure
- Material 3 theme
- Riverpod state management
- Hive database (servers, subscriptions)
- VpnService method channel wrapper

---

## Next Steps

### AŞAMA 1: Native AAR Compilation (Yüksek Öncelik)
1. [ ] Compile SingBox Go library for Android ARM64
2. [ ] Create JNI bindings
3. [ ] Generate Android library (libbox.aar)
4. [ ] Integrate VpnService.protect() calls
5. [ ] Test real traffic stats
6. [ ] Debug JNI communication

### AŞAMA 2: Core Stability
1. [ ] Config validation before VPN start
2. [ ] Enhanced error recovery
3. [ ] Android 12+ compatibility testing
4. [ ] Crashlytics integration
5. [ ] Analytics (optional)

### AŞAMA 3: Advanced Features (Gelecekte)
1. [ ] Kill Switch implementation (native + Flutter)
2. [ ] Clash API HTTP server
3. [ ] Speed test functionality
4. [ ] Ping test for all servers
5. [ ] QR code scanner
6. [ ] Config export functionality
7. [ ] Server search and filter
8. [ ] Server favorites
9. [ ] Traffic usage graphs

### AŞAMA 4: UI/UX Polish
1. [ ] Auto-connect settings
2. [ ] Connection history detailed view
3. [ ] Per-app proxy whitelist/blacklist
4. [ ] Connection quick actions
5. [ ] Notification actions (connect/disconnect from notification)

### AŞAMA 5: Production Ready
1. [ ] Android 12+ tile service
2. [ ] Doze mode support
3. [ ] Battery optimization
4. [ ] Performance profiling
5. [ ] Release signing
6. [ ] Store submission

---

## Issues & Bugs

### Critical Issues
- None (Flutter analyze passes)

### Known Issues
- Traffic stats are simulated (needs native implementation)
- VPN service lacks config validation
- No retry logic on connection failure

### Fixes Applied
- ✅ Fixed subscription/server synchronization (Commit: 6c4fe64)
- ✅ Removed hardcoded configs and added VpnSettings
- ✅ Integrated ipinfo.io for dynamic geo detection
- ✅ Removed Shadowsocks support
- ✅ Fixed server deletion and subscription refresh logic

---

## Completed Features

### ✅ Core VPN
- [x] Flutter UI with Material 3
- [x] Riverpod state management
- [x] Hive database (servers, subscriptions)
- [x] VpnService method channel wrapper
- [x] SingBox config builder (VLESS, VMess, Trojan)
- [x] Subscription URL parser (VLESS, VMess, Trojan)
- [x] IP Info API integration (country flags, cities)
- [x] Two-language support (TR, EN)

### ✅ Settings
- [x] Dynamic DNS configuration (4 servers)
- [x] Route mode options (proxy, direct, bypass, block)
- [x] Tun inbound settings (MTU, stack, sniff)
- [x] Mixed inbound (SOCKS/HTTP proxy)
- [x] VpnSettings class with persistence

### ✅ Native Skeleton
- [x] Android VPN service (VpnService.kt)
- [x] Method channel handlers (MainActivity.kt)
- [x] Event channel status stream (VpnServiceManager.kt)
- [x] Native library placeholder (libbox.aar)
- [x] Notification channel
- [x] Foreground service support

---

## Research Notes

### SingBox for Android Reference
- Repo: https://github.com/SagerNet/sing-box
- Docs: https://sing-box.sagernet.org
- Language: Go
- Core APIs: box.New(), box.Start(), box.Stop()
- Config: JSON format (outbounds, inbounds, dns, route)

### NekoBox Reference
- Repo: https://github.com/Ohayo18/NekoBoxForAndroid
- Features: V2Ray, XRay, Shadowsocks
- Android: Kotlin + JNI
- Native libs: V2Ray/XRay libraries

### Flutter SingBox Plugin
- Package: flutter_sing_box (v1.0.4)
- Features: Remote profile import, Clash API, VPN service management
- Platforms: Android + iOS

---

## Tech Stack

- **Frontend**: Flutter 3+, Dart ^3.11.0
- **State**: Riverpod ^2.5.1
- **Database**: Hive ^2.2.3, Hive Flutter ^1.1.0
- **Theme**: Material 3, Dynamic Color
- **Network**: HTTP ^1.2.0
- **Platform**: Android (Native Kotlin), iOS (Planned)

---

## Version History

### v1.0.1 (Current)
- Fixed subscription/server sync
- Removed hardcoded configs
- Added VpnSettings class
- Integrated ipinfo.io API

### v1.0.0
- Initial commit
- Basic UI structure
- Material 3 theme
