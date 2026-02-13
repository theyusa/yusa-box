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
  Map<String, dynamic> get parsedData {
    if (config.isEmpty) return {};
    try {
      return jsonDecode(config) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Helper getters - Dinamik yapıdan verileri çeker
  String get flag => parsedData['flag'] ?? '🌐';
  String get address => parsedData['server'] ?? parsedData['address'] ?? 'Unknown';
  int get port => parsedData['server_port'] ?? parsedData['port'] ?? 443;
  String get protocol => parsedData['type'] ?? parsedData['protocol'] ?? 'sing-box';
  String get transport => parsedData['transport'] ?? parsedData['network'] ?? 'tcp';
  String get security => parsedData['security'] ?? 'tls';
  String get city => parsedData['city'] ?? 'Unknown';

  // Specific fields mapped from dynamic data
  String? get uuid => parsedData['uuid'];
  String? get path => parsedData['path'];
  String? get host => parsedData['host'];
  String? get sni => parsedData['sni'];
  String? get alpn => parsedData['alpn'] is List ? (parsedData['alpn'] as List).join(',') : parsedData['alpn'];
  bool get allowInsecure => parsedData['allowInsecure'] == true || parsedData['allowInsecure'] == '1';
  String? get fingerprint => parsedData['fingerprint'];

  // SingBox için Outbound Config Oluşturur
  Map<String, dynamic> toSingboxOutbound() {
    return SingBoxConfig(parsedData).buildOutbound();
  }

  // Helper to update specific fields in the JSON config
  void updateField(String key, dynamic value) {
    final data = parsedData;
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    config = jsonEncode(data);
  }



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
