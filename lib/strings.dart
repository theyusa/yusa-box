import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStrings {
  const AppStrings._();

  static const String tr = 'tr';
  static const String en = 'en';

  static final Map<String, Map<String, String>> _strings = {
    tr: {
      'app_title': 'YusaBox',
      'vpn': 'VPN',
      'subscription': 'Abonelik',
      'settings': 'Ayarlar',
      'connected': 'Bağlı',
      'not_connected': 'Bağlı Değil',
      'connect': 'Bağlan',
      'disconnect': 'Bağlantıyı Kes',
      'select_server': 'Sunucu Seç',
      'download': 'İndirme',
      'upload': 'Yükleme',
      'ping': 'Ping',
      'time': 'Süre',
      'protocol': 'Protokol',
      'general': 'Genel',
      'language': 'Dil',
      'dark_mode': 'Karanlık Mod',
      'connection': 'Bağlantı',
      'auto_connect': 'Başlangıçta otomatik bağlan',
      'kill_switch': 'Kill Switch',
      'account': 'Hesap',
      'email': 'E-posta',
      'change_password': 'Şifre Değiştir',
      'about': 'Hakkında',
      'version': 'Sürüm',
      'privacy_policy': 'Gizlilik Politikası',
      'terms_of_service': 'Hizmet Şartları',
      'sign_out': 'Çıkış Yap',
      'v2ray_subs': 'V2Ray Abonelikler',
      'add_subscription': 'Abonelik Ekle',
      'edit_subscription': 'Düzenle',
      'delete_subscription': 'Sil',
      'test_connection': 'Bağlantıyı Test Et',
      'subscription_url': 'Abonelik URL',
      'subscription_name': 'Abonelik Adı',
      'remark': 'Açıklama',
      'address': 'Adres',
      'port': 'Port',
      'type': 'Tip',
      'active': 'Aktif',
      'inactive': 'Pasif',
      'profile': 'Profil',
      'profile_name': 'Profil Adı',
      'save': 'Kaydet',
      'v2ray_config': 'V2Ray Ayarları',
      'singbox_config': 'Singbox Ayarları',
      'log_level': 'Log Seviyesi',
      'dns_servers': 'DNS Sunucuları',
      'routing_rules': 'Yönlendirme Kuralları',
      'bypass_ips': 'Bypass IP\'ler',
      'block_ads': 'Reklamları Engelelle',
      'mtu': 'MTU',
      'tcp_fast_open': 'TCP Fast Open',
      'multiplex': 'Çoklu Bağlantı',
      'sniffing': 'Trafiği Dinle',
      'mux_concurrency': 'Mux Eşzamanlılık',
      'remote_dns': 'Uzak DNS',
      'local_dns': 'Yerel DNS',
      'enable_fake_ip': 'Fake IP Kullan',
      'udp_relay': 'UDP Aktarımı',
      'tcp_only': 'Sadece TCP',
      'scramble_packet': 'Paket Karıştırma',
      'connection_timeout': 'Bağlantı Zaman Aşımı',
      'cancel': 'İptal',
      'delete': 'Sil',
      'edit': 'Düzenle',
      'close': 'Kapat',
      'ok': 'Tamam',
      'confirm': 'Onayla',
      'warning': 'Uyarı',
      'error': 'Hata',
      'success': 'Başarılı',
      'loading': 'Yükleniyor...',
      'no_subscriptions': 'Henüz abonelik yok',
      'add_first_subscription': 'İlk aboneliğinizi ekleyin',
      'delete_confirm': 'Bu aboneliği silmek istediğinizden emin misiniz?',
      'subscription_saved': 'Abonelik kaydedildi',
      'subscription_deleted': 'Abonelik silindi',
      'test_failed': 'Test başarısız',
      'test_successful': 'Test başarılı',
      'select_protocol': 'Protokol Seç',
      'vmess': 'VMess',
      'vless': 'VLESS',
      'trojan': 'Trojan',
      'shadowsocks': 'Shadowsocks',
    },
    en: {
      'app_title': 'YusaBox',
      'vpn': 'VPN',
      'subscription': 'Subscription',
      'settings': 'Settings',
      'connected': 'Connected',
      'not_connected': 'Not Connected',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'select_server': 'Select Server',
      'download': 'Download',
      'upload': 'Upload',
      'ping': 'Ping',
      'time': 'Time',
      'protocol': 'Protocol',
      'general': 'General',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'connection': 'Connection',
      'auto_connect': 'Auto-connect on startup',
      'kill_switch': 'Kill Switch',
      'account': 'Account',
      'email': 'Email',
      'change_password': 'Change Password',
      'about': 'About',
      'version': 'Version',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'sign_out': 'Sign Out',
      'v2ray_subs': 'V2Ray Subscriptions',
      'add_subscription': 'Add Subscription',
      'edit_subscription': 'Edit',
      'delete_subscription': 'Delete',
      'test_connection': 'Test Connection',
      'subscription_url': 'Subscription URL',
      'subscription_name': 'Subscription Name',
      'remark': 'Remark',
      'address': 'Address',
      'port': 'Port',
      'type': 'Type',
      'active': 'Active',
      'inactive': 'Inactive',
      'profile': 'Profile',
      'profile_name': 'Profile Name',
      'save': 'Save',
      'v2ray_config': 'V2Ray Settings',
      'singbox_config': 'Singbox Settings',
      'log_level': 'Log Level',
      'dns_servers': 'DNS Servers',
      'routing_rules': 'Routing Rules',
      'bypass_ips': 'Bypass IPs',
      'block_ads': 'Block Ads',
      'mtu': 'MTU',
      'tcp_fast_open': 'TCP Fast Open',
      'multiplex': 'Multiplex',
      'sniffing': 'Sniffing',
      'mux_concurrency': 'Mux Concurrency',
      'remote_dns': 'Remote DNS',
      'local_dns': 'Local DNS',
      'enable_fake_ip': 'Enable Fake IP',
      'udp_relay': 'UDP Relay',
      'tcp_only': 'TCP Only',
      'scramble_packet': 'Scramble Packet',
      'connection_timeout': 'Connection Timeout',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'ok': 'OK',
      'confirm': 'Confirm',
      'warning': 'Warning',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'no_subscriptions': 'No subscriptions yet',
      'add_first_subscription': 'Add your first subscription',
      'delete_confirm': 'Are you sure you want to delete this subscription?',
      'subscription_saved': 'Subscription saved',
      'subscription_deleted': 'Subscription deleted',
      'test_failed': 'Test failed',
      'test_successful': 'Test successful',
      'select_protocol': 'Select Protocol',
      'vmess': 'VMess',
      'vless': 'VLESS',
      'trojan': 'Trojan',
      'shadowsocks': 'Shadowsocks',
    },
  };

  static String get(String key, [String? language]) {
    final lang = language ?? _currentLanguage;
    return _strings[lang]?[key] ?? _strings[en]![key] ?? key;
  }

  static String _currentLanguage = tr;

  static String get currentLanguage => _currentLanguage;

  static void setLanguage(String language) {
    if (_strings.containsKey(language)) {
      _currentLanguage = language;
    }
  }

  static List<String> get supportedLanguages => _strings.keys.toList();

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case tr:
        return 'Türkçe';
      case en:
        return 'English';
      default:
        return languageCode;
    }
  }
}
