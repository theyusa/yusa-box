import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vpn_models.dart';

class SubscriptionService {
  
  Future<List<VPNServer>> fetchServersFromSubscription(String subscriptionUrl) async {
    try {
      final response = await http.get(Uri.parse(subscriptionUrl));
      
      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        
        if (subscriptionUrl.startsWith('vmess://') ||
            subscriptionUrl.startsWith('vless://') ||
            subscriptionUrl.startsWith('trojan://') ||
            subscriptionUrl.startsWith('ss://')) {
          final server = _parseSingleServer(subscriptionUrl);
          return [server];
        } else if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
          return _parseJsonConfig(body);
        } else {
          try {
            final decoded = base64Decode(base64.normalize(body.trim()));
            final String content = utf8.decode(decoded);
            
            if (content.trim().startsWith('{') || content.trim().startsWith('[')) {
              return _parseJsonConfig(content);
            } else if (content.contains('\n')) {
              return _parseMultiLineConfig(content);
            } else {
              final server = _parseSingleServer(content);
              return [server];
            }
          } catch (e) {
            // If base64 decode fails, treat as plain text
            if (body.contains('\n')) {
              return _parseMultiLineConfig(body);
            } else {
              final server = _parseSingleServer(body.trim());
              return [server];
            }
          }
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Subscription fetch error: ${e.toString()}');
    }
  }

  List<VPNServer> _parseJsonConfig(String jsonContent) {
    try {
      final dynamic json = jsonDecode(jsonContent);
      List<VPNServer> servers = [];

      if (json is List) {
        for (var item in json) {
          final server = _parseJsonServer(item as Map<String, dynamic>);
          servers.add(server);
        }
      } else if (json is Map) {
        final server = _parseJsonServer(json as Map<String, dynamic>);
        servers.add(server);
      }

      return servers;
    } catch (e) {
      return [];
    }
  }

  VPNServer _parseJsonServer(Map<String, dynamic> json) {
    final String type = json['type'] ?? 'vless';
    final String server = json['server'] ?? json['address'] ?? '';
    final int serverPort = json['server_port'] ?? json['port'] ?? 443;
    
    String flag = _getCountryFlag(server);
    String city = _getCity(server);
    String protocol = type.toUpperCase();

    return VPNServer(
      id: server,
      name: '$flag $city',
      address: server,
      port: serverPort,
      flag: flag,
      city: city,
      ping: '--',
      protocol: protocol,
      uuid: json['uuid'] ?? '',
      security: json['tls'] != null ? 'tls' : 'none',
      transport: json['transport'] ?? json['network'] ?? 'tcp',
      path: json['path'] ?? json['ws-opts']?['path'],
      host: json['host'] ?? json['ws-opts']?['headers']?['Host'],
      sni: json['sni'] ?? json['servername'],
      alpn: json['alpn'] is List ? json['alpn'].join(',') : json['alpn'],
      allowInsecure: json['skip-cert-verify'] ?? false,
    );
  }

  List<VPNServer> _parseMultiLineConfig(String content) {
    List<VPNServer> servers = [];
    final lines = content.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      
      final server = _parseSingleServer(line.trim());
      servers.add(server);
    }

    return servers;
  }

  VPNServer _parseSingleServer(String uriString) {
    if (uriString.startsWith('vmess://')) {
      return _parseVmess(uriString);
    } else if (uriString.startsWith('vless://')) {
      return _parseVless(uriString);
    } else if (uriString.startsWith('trojan://')) {
      return _parseTrojan(uriString);
    } else if (uriString.startsWith('ss://')) {
      return _parseShadowsocks(uriString);
    } else if (uriString.startsWith('ssr://')) {
      return _parseShadowsocksR(uriString);
    }

    return VPNServer(
      id: 'unknown',
      name: 'Unknown',
      address: '0.0.0.0',
      port: 443,
      flag: 'URL',
      city: 'Unknown',
      ping: '--',
      protocol: 'UNKNOWN',
    );
  }

  VPNServer _parseVmess(String vmessUrl) {
    try {
      final String encoded = vmessUrl.replaceFirst('vmess://', '');
      final String decoded = utf8.decode(base64Decode(base64.normalize(encoded)));
      final Map<String, dynamic> json = jsonDecode(decoded);

      final String address = json['add'] ?? json['address'] ?? '';
      final int port = json['port'] is String ? int.tryParse(json['port']) ?? 443 : json['port'] ?? 443;
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);
      final String ps = json['ps'] ?? '';

      return VPNServer(
        id: address,
        name: ps.isNotEmpty ? ps : '$flag $city',
        address: address,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: 'VMESS',
        uuid: json['id'] ?? '',
        security: json['tls'] == 'tls' ? 'tls' : 'none',
        transport: json['net'] ?? 'tcp',
        path: json['path'],
        host: json['host'],
        sni: json['sni'] ?? json['host'],
        alpn: json['alpn'],
        allowInsecure: json['verify_cert'] == false || json['allowInsecure'] == 1,
      );
    } catch (e) {
      return VPNServer(
        id: 'unknown',
        name: 'VMess Parse Error',
        address: '0.0.0.0',
        port: 443,
        flag: 'URL',
        city: 'Error',
        ping: '--',
        protocol: 'VMESS',
      );
    }
  }

  VPNServer _parseVless(String vlessUrl) {
    try {
      // vless://uuid@host:port?params#remark
      final String uri = vlessUrl.replaceFirst('vless://', '');
      
      // Split remark (fragment)
      final List<String> parts = uri.split('#');
      final String mainPart = parts[0];
      String remark = '';
      if (parts.length > 1) {
        remark = Uri.decodeComponent(parts[1]);
      }
      
      // Split UUID and the rest
      final List<String> atParts = mainPart.split('@');
      if (atParts.length < 2) {
        throw Exception('Invalid VLESS URL format');
      }
      
      final String uuid = atParts[0];
      final String rest = atParts[1];
      
      // Split address:port and query params
      final List<String> queryParts = rest.split('?');
      final String addressPort = queryParts[0];
      
      // Parse address and port
      final List<String> addrParts = addressPort.split(':');
      if (addrParts.length < 2) {
        throw Exception('Invalid address:port format');
      }
      
      final String address = addrParts[0];
      final int port = int.tryParse(addrParts[1]) ?? 443;
      
      // Parse query params
      String security = 'tls';
      String transport = 'tcp';
      String? path;
      String? host;
      String? sni;
      String? alpn;
      bool allowInsecure = false;
      String? fingerprint;
      
      if (queryParts.length > 1) {
        final params = Uri.splitQueryString(queryParts[1]);
        security = params['security'] ?? 'tls';
        transport = params['type'] ?? 'tcp';
        path = params['path']?.isNotEmpty == true ? Uri.decodeComponent(params['path']!) : null;
        host = params['host']?.isNotEmpty == true ? params['host'] : null;
        sni = params['sni']?.isNotEmpty == true ? params['sni'] : null;
        alpn = params['alpn']?.isNotEmpty == true ? Uri.decodeComponent(params['alpn']!) : null;
        allowInsecure = params['allowInsecure'] == '1';
        fingerprint = params['fp']?.isNotEmpty == true ? params['fp'] : null;
      }
      
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);

      return VPNServer(
        id: '$address:$port',
        name: remark.isNotEmpty ? remark : '$flag $city',
        address: address,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: 'VLESS',
        uuid: uuid,
        security: security,
        transport: transport,
        path: path,
        host: host,
        sni: sni,
        alpn: alpn,
        allowInsecure: allowInsecure,
        fingerprint: fingerprint,
      );
    } catch (e) {
      // ignore: avoid_print
      print('VLESS parse error: $e');
      return VPNServer(
        id: 'unknown',
        name: 'VLESS Parse Error',
        address: '0.0.0.0',
        port: 443,
        flag: 'URL',
        city: 'Error',
        ping: '--',
        protocol: 'VLESS',
      );
    }
  }

  VPNServer _parseTrojan(String trojanUrl) {
    try {
      // trojan://password@host:port?params#remark
      final String uri = trojanUrl.replaceFirst('trojan://', '');
      
      final List<String> parts = uri.split('#');
      final String mainPart = parts[0];
      String remark = '';
      if (parts.length > 1) {
        remark = Uri.decodeComponent(parts[1]);
      }
      
      final List<String> atParts = mainPart.split('@');
      if (atParts.length < 2) {
        throw Exception('Invalid Trojan URL format');
      }
      
      final String password = atParts[0];
      final String rest = atParts[1];
      
      final List<String> queryParts = rest.split('?');
      final String addressPort = queryParts[0];
      
      final List<String> addrParts = addressPort.split(':');
      if (addrParts.length < 2) {
        throw Exception('Invalid address:port format');
      }
      
      final String address = addrParts[0];
      final int port = int.tryParse(addrParts[1]) ?? 443;
      
      String? sni;
      String? alpn;
      bool allowInsecure = false;
      
      if (queryParts.length > 1) {
        final params = Uri.splitQueryString(queryParts[1]);
        sni = params['sni']?.isNotEmpty == true ? params['sni'] : null;
        alpn = params['alpn']?.isNotEmpty == true ? Uri.decodeComponent(params['alpn']!) : null;
        allowInsecure = params['allowInsecure'] == '1';
      }
      
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);

      return VPNServer(
        id: '$address:$port',
        name: remark.isNotEmpty ? remark : '$flag $city',
        address: address,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: 'TROJAN',
        uuid: password,
        security: 'tls',
        transport: 'tcp',
        sni: sni,
        alpn: alpn,
        allowInsecure: allowInsecure,
      );
    } catch (e) {
      return VPNServer(
        id: 'unknown',
        name: 'Trojan Parse Error',
        address: '0.0.0.0',
        port: 443,
        flag: 'URL',
        city: 'Error',
        ping: '--',
        protocol: 'TROJAN',
      );
    }
  }

  VPNServer _parseShadowsocks(String ssUrl) {
    try {
      final String uri = ssUrl.replaceFirst('ss://', '');
      
      String decoded;
      try {
        decoded = utf8.decode(base64Decode(base64.normalize(uri.split('@')[0])));
      } catch (e) {
        // Try full URL decode
        final List<String> parts = uri.split('#');
        final String mainPart = parts[0];
        String remark = '';
        if (parts.length > 1) {
          remark = Uri.decodeComponent(parts[1]);
        }
        
        final List<String> atParts = mainPart.split('@');
        if (atParts.length < 2) {
          throw Exception('Invalid SS URL format');
        }
        
        final String serverPart = atParts[1].split('/')[0];
        final List<String> serverInfo = serverPart.split(':');
        
        if (serverInfo.length < 2) {
          throw Exception('Invalid address:port format');
        }
        
        final String address = serverInfo[0];
        final int port = int.tryParse(serverInfo[1]) ?? 8388;
        final String flag = _getCountryFlag(address);
        final String city = _getCity(address);

        return VPNServer(
          id: '$address:$port',
          name: remark.isNotEmpty ? remark : '$flag $city',
          address: address,
          port: port,
          flag: flag,
          city: city,
          ping: '--',
          protocol: 'SS',
        );
      }
      
      final List<String> parts = decoded.split('@');
      final String serverPart = parts[1].split('/')[0];
      final List<String> serverInfo = serverPart.split(':');
      
      final String address = serverInfo[0];
      final int port = int.tryParse(serverInfo[1]) ?? 8388;
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);

      return VPNServer(
        id: '$address:$port',
        name: '$flag $city',
        address: address,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: 'SS',
      );
    } catch (e) {
      return VPNServer(
        id: 'unknown',
        name: 'SS Parse Error',
        address: '0.0.0.0',
        port: 443,
        flag: 'URL',
        city: 'Error',
        ping: '--',
        protocol: 'SS',
      );
    }
  }

  VPNServer _parseShadowsocksR(String ssrUrl) {
    try {
      final String uri = ssrUrl.replaceFirst('ssr://', '');
      
      final String decoded = utf8.decode(base64Decode(base64.normalize(uri)));
      
      final List<String> parts = decoded.split('/?');
      final String mainPart = parts[0];
      final String paramPart = parts.length > 1 ? parts[1] : '';
      
      final List<String> mainParts = mainPart.split(':');
      if (mainParts.length < 6) {
        throw Exception('Invalid SSR URL format');
      }
      
      final String address = mainParts[0];
      final int port = int.tryParse(mainParts[1]) ?? 8388;
      // SSR specific fields: protocol, method, obfs - stored for future use
      final String password = utf8.decode(base64Decode(base64.normalize(mainParts[5])));
      
      String? remark;
      if (paramPart.isNotEmpty) {
        final params = Uri.splitQueryString(paramPart);
        if (params['remarks'] != null) {
          remark = utf8.decode(base64Decode(base64.normalize(params['remarks']!)));
        }
      }
      
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);

      return VPNServer(
        id: '$address:$port',
        name: remark ?? '$flag $city',
        address: address,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: 'SSR',
        uuid: password,
      );
    } catch (e) {
      return VPNServer(
        id: 'unknown',
        name: 'SSR Parse Error',
        address: '0.0.0.0',
        port: 443,
        flag: 'URL',
        city: 'Error',
        ping: '--',
        protocol: 'SSR',
      );
    }
  }

  String _getCountryFlag(String server) {
    if (server.endsWith('.tr') || server.contains('.tr')) {
      return '🇹🇷';
    } else if (server.contains('89.35.73')) {
      return '🇹🇷'; // Turkey - TheYusa servers
    } else if (server.contains('194.62.54')) {
      return '🇳🇱'; // Netherlands - Rebecca servers
    } else if (server.endsWith('.de') || server.contains('.de')) {
      return '🇩🇪';
    } else if (server.endsWith('.nl') || server.contains('.nl')) {
      return '🇳🇱';
    } else if (server.endsWith('.us') || server.contains('.us')) {
      return '🇺🇸';
    } else if (server.endsWith('.fr') || server.contains('.fr')) {
      return '🇫🇷';
    } else if (server.endsWith('.uk') || server.contains('.uk')) {
      return '🇬🇧';
    } else if (server.endsWith('.ru') || server.contains('.ru')) {
      return '🇷🇺';
    } else if (server.endsWith('.jp') || server.contains('.jp')) {
      return '🇯🇵';
    } else if (server.endsWith('.sg') || server.contains('.sg')) {
      return '🇸🇬';
    } else if (server.endsWith('.hk') || server.contains('.hk')) {
      return '🇭🇰';
    } else {
      return '🌐';
    }
  }

  String _getCity(String server) {
    if (server.contains('theyusa') || server.contains('89.35.73')) {
      return 'Turkey';
    } else if (server.contains('rebecca') || server.contains('194.62.54')) {
      return 'Netherlands';
    } else if (server.contains('germany') || server.contains('.de')) {
      return 'Germany';
    } else if (server.contains('netherlands') || server.contains('.nl')) {
      return 'Netherlands';
    } else if (server.contains('united') || server.contains('.us')) {
      return 'United States';
    } else if (server.contains('singapore') || server.contains('.sg')) {
      return 'Singapore';
    } else if (server.contains('japan') || server.contains('.jp')) {
      return 'Japan';
    } else if (server.contains('uk') || server.contains('.uk')) {
      return 'United Kingdom';
    } else {
      return 'Unknown';
    }
  }
}
