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
          final server = _parseJsonServer(item);
          servers.add(server);
        }
      } else if (json is Map) {
        final server = _parseJsonServer(json);
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

      final String server = json['add'] ?? json['address'] ?? '';
      final int port = json['port'] ?? 443;
      final String flag = _getCountryFlag(server);
      final String city = _getCity(server);

      return VPNServer(
        id: server,
        name: '$flag $city',
        address: server,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: 'VMESS',
      );
    } catch (e) {
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
  }

  VPNServer _parseVless(String vlessUrl) {
    try {
      final String uri = vlessUrl.replaceFirst('vless://', '');
      final String protocol = 'VLESS';
      
      final String uuid = uri.split('@')[0];
      final String serverPart = uri.split('@')[1].split('?')[0];
      final List<String> serverInfo = serverPart.split(':');
      
      if (serverInfo.length < 2) {
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
      
      final String server = serverInfo[0];
      final int port = int.tryParse(serverInfo[1]) ?? 443;
      final String flag = _getCountryFlag(server);
      final String city = _getCity(server);

      return VPNServer(
        id: server,
        name: '$flag $city',
        address: server,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: protocol,
      );
    } catch (e) {
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
  }

  VPNServer _parseTrojan(String trojanUrl) {
    try {
      final String uri = trojanUrl.replaceFirst('trojan://', '');
      final String protocol = 'TROJAN';
      
      final String password = uri.split('@')[0];
      final String serverPart = uri.split('@')[1].split('?')[0];
      final List<String> serverInfo = serverPart.split(':');
      
      if (serverInfo.length < 2) {
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
      
      final String server = serverInfo[0];
      final int port = int.tryParse(serverInfo[1]) ?? 443;
      final String flag = _getCountryFlag(server);
      final String city = _getCity(server);

      return VPNServer(
        id: server,
        name: '$flag $city',
        address: server,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: protocol,
      );
    } catch (e) {
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
  }

  VPNServer _parseShadowsocks(String ssUrl) {
    try {
      final String uri = ssUrl.replaceFirst('ss://', '');
      final String protocol = 'SS';
      
      final String decoded = utf8.decode(base64Decode(base64.normalize(uri)));
      final List<String> parts = decoded.split('@');
      
      if (parts.length < 2) {
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
      
      final String serverPart = parts[1].split('/')[0];
      final List<String> serverInfo = serverPart.split(':');
      
      if (serverInfo.length < 2) {
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
      
      final String server = serverInfo[0];
      final int port = int.tryParse(serverInfo[1]) ?? 8388;
      final String flag = _getCountryFlag(server);
      final String city = _getCity(server);

      return VPNServer(
        id: server,
        name: '$flag $city',
        address: server,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: protocol,
      );
    } catch (e) {
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
  }

  VPNServer _parseShadowsocksR(String ssrUrl) {
    try {
      final String uri = ssrUrl.replaceFirst('ssr://', '');
      final String protocol = 'SSR';
      
      final String decoded = utf8.decode(base64Decode(base64.normalize(uri)));
      final Map<String, String> params = Uri.splitQueryString(decoded);
      final String server = params['server'] ?? 'unknown';
      final String portStr = params['server_port'] ?? '8388';
      final int port = int.tryParse(portStr) ?? 8388;
      final String flag = _getCountryFlag(server);
      final String city = _getCity(server);

      return VPNServer(
        id: server,
        name: '$flag $city',
        address: server,
        port: port,
        flag: flag,
        city: city,
        ping: '--',
        protocol: protocol,
      );
    } catch (e) {
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
  }

  String _getCountryFlag(String server) {
    if (server.endsWith('.tr') || server.contains('.tr')) {
      return 'TR';
    } else if (server.endsWith('.de') || server.contains('.de')) {
      return 'DE';
    } else if (server.endsWith('.nl') || server.contains('.nl')) {
      return 'NL';
    } else if (server.endsWith('.us') || server.contains('.us')) {
      return 'US';
    } else if (server.endsWith('.fr') || server.contains('.fr')) {
      return 'FR';
    } else if (server.endsWith('.uk') || server.contains('.uk')) {
      return 'UK';
    } else if (server.endsWith('.ru') || server.contains('.ru')) {
      return 'RU';
    } else if (server.endsWith('.jp') || server.contains('.jp')) {
      return 'JP';
    } else if (server.endsWith('.sg') || server.contains('.sg')) {
      return 'SG';
    } else if (server.endsWith('.hk') || server.contains('.hk')) {
      return 'HK';
    } else {
      return '🌐';
    }
  }

  String _getCity(String server) {
    if (server.contains('theyusa')) {
      return 'Turkey';
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
    } else {
      return 'Unknown';
    }
  }
}
