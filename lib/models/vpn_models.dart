class VPNServer {
  final String id;
  String name;
  String address;
  int port;
  String flag;
  String city;
  String ping;
  String protocol; // vless, vmess, trojan, shadowsocks
  
  // V2Ray specific fields
  String uuid;
  String security; // tls, none
  String transport; // tcp, ws, grpc
  String? path;
  String? host;
  String? sni;
  String? alpn;
  bool allowInsecure;
  String? fingerprint;

  VPNServer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.flag,
    this.city = '',
    this.ping = '--',
    this.protocol = 'vless',
    this.uuid = '',
    this.security = 'tls',
    this.transport = 'tcp',
    this.path,
    this.host,
    this.sni,
    this.alpn,
    this.allowInsecure = false,
    this.fingerprint,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'port': port,
      'flag': flag,
      'city': city,
      'ping': ping,
      'protocol': protocol,
      'uuid': uuid,
      'security': security,
      'transport': transport,
      'path': path,
      'host': host,
      'sni': sni,
      'alpn': alpn,
      'allowInsecure': allowInsecure,
      'fingerprint': fingerprint,
    };
  }

  factory VPNServer.fromJson(Map<String, dynamic> json) {
    return VPNServer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      port: json['port'] ?? 443,
      flag: json['flag'] ?? '🌐',
      city: json['city'] ?? '',
      ping: json['ping'] ?? '--',
      protocol: json['protocol'] ?? 'vless',
      uuid: json['uuid'] ?? '',
      security: json['security'] ?? 'tls',
      transport: json['transport'] ?? 'tcp',
      path: json['path'],
      host: json['host'],
      sni: json['sni'],
      alpn: json['alpn'],
      allowInsecure: json['allowInsecure'] ?? false,
      fingerprint: json['fingerprint'],
    );
  }
}

class VPNSubscription {
  final String id;
  String name;
  String url;
  List<VPNServer> servers;

  VPNSubscription({
    required this.id,
    required this.name,
    required this.url,
    List<VPNServer>? servers,
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
          ?.map((s) => VPNServer.fromJson(s))
          .toList() ?? [],
    );
  }
}
