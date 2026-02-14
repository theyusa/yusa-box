# TODO - YusaBox VPN Geliştirmeleri

## 🔴 KRİTİK - VPN Crash Sorunu

### Mevcut Durum
- **Sorun:** Server seçip "Bağlan" butonuna basınca uygulama kapanıyor
- **Beklenen Davranış:** VPN bağlantısı başlamalı, status güncellenmeli
- **Olası Nedenler:**
  1. Native library yükleme sorunu
  2. JNI package name uyuşmazlığı (io.nekohasekai.libbox)
  3. Config validasyon hatası
  4. Unhandled exception crash

### Yapılan Düzeltmeler
- [x] **JNI Wrapper eklendi** (`SingBoxWrapper.kt`)
- [x] **Library loading kontrolü eklendi**
- [x] **Config JSON validasyonu eklendi** (MainActivity)
- [x] **Extensive logging eklendi** (SingBoxVpnService)
- [x] **ServiceCompat ile stopForeground düzeltildi** (Android 14+)

### Test Edilmesi Gerekenler
```bash
# Test için adımlar
1. adb install -r build/app/outputs/flutter-apk/app-release.apk
2. adb logcat -c
3. adb logcat -s SingBoxVpnService:* MainActivity:* VpnServiceManager:* SingBoxWrapper:* AndroidRuntime:E DEBUG
4. Uygulamayı aç
5. Server seç
6. Bağlan butonuna bas
7. Logcat çıktısını paylaş (hata varsa)
```

## 🟠 ORTA - UI/UX İyileştirmeleri

### 1. Server Listesi İyileştirmeleri
- [ ] **Auto-connect feature:** Son bağlanan server'a otomatik bağlanma
- [ ] **Group subscription servers:** Subscription başına göre gruplandırma
- [ ] **Search bar:** Server/subscription arama
- [ ] **Sort by ping/latency:** Ping değerine göre sıralama
- [ ] **Batch actions:** Toplu silme/export

### 2. Dashboard İyileştirmeleri
- [x] **Enhanced log system:** Filtreleme, renkli görüntüleme
- [ ] **Real-time traffic graph:** Trafik grafiği animasyonlu
- [ ] **Connection quality indicator:** Signal strength gösterimi
- [ ] **Quick actions:** Reconnect, change server, stop buttons

### 3. VPN Settings
- [ ] **DNS settings UI:** DNS sunucularını ayarlama arayüzü
- [ ] **Route mode selector:** Proxy/Direct/Bypass seçimi
- [ ] **Protocol details:** Seçili server'ın detaylarını gösterme

## 🟢 DÜŞÜK - Özellikler

### 1. SingBox Core Entegrasyonu
- [x] **VLESS support:** TLS, Reality, WebSocket, gRPC
- [x] **VMess support:** TLS, WebSocket, gRPC
- [x] **Trojan support:** TLS, WebSocket, gRPC
- [ ] **Hysteria2:** Hysteria2 protocol desteği
- [ ] **TUIC:** TUIC protocol desteği

### 2. Subscription Yönetimi
- [x] **Add subscription:** Link ile abonelik ekleme
- [x] **Update subscription:** URL'den server çekme
- [x] **Edit subscription:** İsim/URL değiştirme
- [x] **Delete subscription:** Abonelik silme
- [ ] **Subscription groups:** Abonelikleri gruplama
- [ ] **Auto-refresh:** Otomatik güncelleme interval'ı

### 3. Speed Test
- [x] **Basic speed test:** Download/Upload/Ping testi
- [ ] **History:** Speed test geçmişi
- [ ] **Compare:** Sonuçları karşılaştırma
- [ ] **Batch test:** Toplu server testi

### 4. Güvenlik ve Gizlilik
- [ ] **Encrypted config:** Config şifreleme
- [ ] **Biometric auth:** Parmak izi/Yüz tanıma ile giriş
- [ ] **Auto-lock:** Uygulamayı kilitleme
- [ ] **Secure storage:** Hassas verileri güvenli saklama

## 🔵 ARAŞTIRMA - Referans Uygulamalar

### NekoBox/SingBox Referans

Araştırılacak özellikler:
1. **Config management:**
   - Config import/export
   - QR code scanner
   - Config editor

2. **Connection monitoring:**
   - Real-time latency graph
   - Packet loss rate
   - Connection quality score

3. **Advanced features:**
   - Split tunneling
   - Custom inbound rules
   - DNS leak protection
   - IPv6 support

4. **UI/UX patterns:**
   - Swipe gestures
   - Pull-to-refresh
   - Context menus
   - Bottom sheet dialogs

### Nerede Bakılacak?
```bash
# GitHub repolar
https://github.com/MatsuriDayo/Nekobox-Android
https://github.com/SagerNet/SagerNet
https://github.com/2dust/v2rayNG
https://github.com/xiaoya-pro/Sing-box-Android

# Dokümantasyonlar
https://sing-box.sagernet.org/
https://github.com/SagerNet/sing-box-rules
```

## 🟢 TEST EDİLMESİ GEREKENLER

### Unit Tests
- [ ] `subscription_service.dart`: URL parsing, config generation
- [ ] `vpn_service.dart`: MethodChannel communication
- [ ] `ping_service.dart`: Ping result handling
- [ ] `singbox_config.dart`: Config builder
- [ ] `vpn_settings.dart`: Settings serialization

### Widget Tests
- [ ] VPNHomePage: Server selection, connection flow
- [ ] Subscription dialog: Form validation
- [ ] Log viewer: Filtering, scrolling
- [ ] Settings pages: All settings widgets

### Integration Tests
- [ ] Full VPN connection flow
- [ ] Subscription add/edit/delete flow
- [ ] Ping test flow
- [ ] Speed test flow

## 🔧 TEKNİK İyileştirmeler

### Performans
- [ ] **Lazy loading:** Server listesi lazy loading
- [ ] **Caching:** Config'leri cache'leme
- [ ] **Debouncing:** Ping test debounce
- [ ] **Pagination:** Çoklu server sayfalama

### Kod Kalitesi
- [ ] **Code coverage:** Test coverage %50 üzeri
- [ ] **Lint rules:** Custom lint kuralları
- [ ] **Type safety:** Null safety tam kullanımı
- [ ] **Error boundaries:** Error widget boundaries

### Build Optimizasyonu
- [ ] **R8/ProGuard:** Kod obfuscation
- [ ] **App bundle:** AAB format desteği
- [ ] **Split APK:** ABI göre ayrı APK'lar
- [ ] **Gradle cache:** Cache yönetimi

## 📝 NOTLAR

### Crash Debugging Rehberi
Uygulama crash olduğunda:
1. `adb logcat -c` ile logları temizle
2. Filtreli log başlat: `adb logcat -s SingBoxVpnService:*`
3. Reproduce crash
4. Logcat'te exception stack trace'ini bul
5. Exception tipine göre düzelt

### Önemli Kontroller
- [ ] Flutter analyze hatasız olmalı
- [ ] Gradle build başarılı olmalı
- [ ] Native library yüklenmeli
- [ ] MethodChannel mesajları doğru olmalı

### Geliştirme Akışı
1. Yeni feature branch aç
2. Kod yaz
3. `flutter analyze` çalıştır
4. Testleri çalıştır
5. Local build test et
6. Review ve commit
7. Push edip kontrol et

---
**Son güncelleme:** 2026-02-14
**Durum:** VPN crash sorunu aktif araştırma
