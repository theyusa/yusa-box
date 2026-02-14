# YusaBox Development Roadmap

## Current Stage: Core VPN Implementation

### Phase 1: Native SingBox Integration (AŞAMADA)

- [x] AAR library research and architecture design
- [ ] Build SingBox AAR with JNI wrapper
- [ ] Implement real traffic stats (VpnService.protect())
- [ ] Add native logging system
- [ ] Implement foreground service notification
- [ ] Add connection timeout handling
- [ ] Implement error recovery with exponential backoff
- [ ] Android 12+ compatibility (new VPN permission model)

### Phase 2: Advanced VPN Features (PLANLANMIŞ)

- [ ] Kill Switch (traffic leak detection)
- [ ] Auto-connect on app start
- [ ] Auto-reconnect on network change
- [ ] Clash API HTTP server (port 9090)
- [ ] Speed test (real throughput measurement)
- [ ] Ping test for all servers
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
