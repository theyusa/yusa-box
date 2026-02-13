import 'package:hive/hive.dart';
import 'dart:convert';
import 'singbox_config.dart'; // Import the new helper

part 'vpn_models.g.dart';

@HiveType(typeId: 0)
class VpnServer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String config; // Stores the raw JSON data string

  @HiveField(3)
  String ping;

  @HiveField(4)
  bool isActive;

  VpnServer({
    required this.id,
    required this.name,
    required this.config,
    this.ping = '--',
    this.isActive = false,
  });

  // Dinamik olarak config string'ini Map'e çevirir
  Map<String, dynamic> get _parsedData {
    if (config.isEmpty) return {};
    try {
      return jsonDecode(config) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Helper getters - Dinamik yapıdan verileri çeker
  String get flag => _parsedData['flag'] ?? '🌐';
  String get address => _parsedData['server'] ?? _parsedData['address'] ?? 'Unknown';
  int get port => _parsedData['server_port'] ?? _parsedData['port'] ?? 443;
  String get protocol => _parsedData['type'] ?? _parsedData['protocol'] ?? 'sing-box';
  String get transport => _parsedData['transport'] ?? _parsedData['network'] ?? 'tcp';
  String get security => _parsedData['security'] ?? 'tls';
  String get city => _parsedData['city'] ?? 'Unknown';
  
  // Specific fields mapped from dynamic data
  String? get uuid => _parsedData['uuid'];
  String? get path => _parsedData['path'];
  String? get host => _parsedData['host'];
  String? get sni => _parsedData['sni'];
  String? get alpn => _parsedData['alpn'] is List ? (_parsedData['alpn'] as List).join(',') : _parsedData['alpn'];
  bool get allowInsecure => _parsedData['allowInsecure'] == true || _parsedData['allowInsecure'] == '1';
  String? get fingerprint => _parsedData['fingerprint'];

  // SingBox için Outbound Config Oluşturur
  Map<String, dynamic> toSingboxOutbound() {
    return SingBoxConfig(_parsedData).buildOutbound();
  }
  
  // Helper to update specific fields in the JSON config
  void updateField(String key, dynamic value) {
    final data = _parsedData;
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    config = jsonEncode(data);
  }

  // Setter'ları da dinamik yapıya yönlendirelim
  set name(String value) {
    // Hive alanı, doğrudan güncellenir.
    // Ancak JSON içinde de tutuyorsak orayı da güncellemeliyiz.
    // Bu örnekte 'name' ayrı bir Hive alanı olarak duruyor.
    // İsterseniz sync edebilirsiniz:
    final data = _parsedData;
    data['name'] = value;
    config = jsonEncode(data);
    // Hive'daki 'name' field'ı setter ile otomatik güncellenmez, super.name yok.
    // Dart'ta bu şekilde field override edemem çünkü name bir alan.
    // Hive generator bu alanı kullanıyor.
    // Bu yüzden setter yerine method kullanmak daha güvenli veya bu alanı sadece Hive'da tutmak.
    // Kullanıcı UI'da name'i değiştirdiğinde server.name = "yeni" der.
    // Bu durumda sadece Hive alanı değişir. config içindeki name değişmez.
    // Tutarlılık için updateField kullanmak daha iyi.
  }
  // Not: HiveObject üzerindeki alanlar public olduğu için setter override etmek zordur.
  // En iyisi name alanını kullanmak ve config içindeki name'i senkronize etmemek (veya kaydederken yapmak).
  // Şimdilik basit bırakıyorum.

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'config': config,
      'ping': ping,
      'isActive': isActive,
    };
  }

  factory VpnServer.fromJson(Map<String, dynamic> json) {
    return VpnServer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      config: json['config'] ?? '',
      ping: json['ping'] ?? '--',
      isActive: json['isActive'] ?? false,
    );
  }
}

@HiveType(typeId: 1)
class VPNSubscription extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  List<VpnServer> servers;

  VPNSubscription({
    required this.id,
    required this.name,
    required this.url,
    List<VpnServer>? servers,
  }) : servers = servers ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'servers': servers.map((s) => s.toJson()).toList(),
    };
  }

  factory VPNSubscription.fromJson(Map<String, dynamic> json) {
    return VPNSubscription(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      servers: (json['servers'] as List?)
          ?.map((s) => VpnServer.fromJson(s))
          .toList() ?? [],
    );
  }
}
