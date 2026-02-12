import 'package:flutter/material.dart';

class VPNServer {
  final String id;
  String name;
  String address;
  int port;
  String flag;
  String city;
  String ping;
  String protocol; // vmess, vless, trojan vs.

  VPNServer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.flag,
    this.city = '',
    this.ping = '--',
    this.protocol = 'vless',
  });
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

  // Helper to simulate fetching servers from the URL
  void refreshServers() {
    // Gerçek uygulamada burada HTTP isteği atılıp JSON parse edilecek.
    // Şimdilik simüle ediyoruz.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    servers = [
      VPNServer(
        id: '${id}_1_$timestamp',
        name: '$name - Server 1',
        address: '192.168.1.1',
        port: 443,
        flag: '🇺🇸',
        city: 'New York',
        ping: '${(10 + (timestamp % 50))}ms',
      ),
      VPNServer(
        id: '${id}_2_$timestamp',
        name: '$name - Server 2',
        address: '192.168.1.2',
        port: 443,
        flag: '🇩🇪',
        city: 'Frankfurt',
        ping: '${(20 + (timestamp % 50))}ms',
      ),
    ];
  }
}
