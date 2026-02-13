import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vpn_models.dart';

class SubscriptionService {
  
  Future<List<VpnServer>> fetchServersFromSubscription(String subscriptionUrl) async {
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

  List<VpnServer> _parseJsonConfig(String jsonContent) {
    try {
      final dynamic json = jsonDecode(jsonContent);
      List<VpnServer> servers = [];

      if (json is List) {
        for (var item in json) {
          final server = _createVpnServerFromMap(item as Map<String, dynamic>);
          servers.add(server);
        }
      } else if (json is Map) {
        final server = _createVpnServerFromMap(json as Map<String, dynamic>);
        servers.add(server);
      }

      return servers;
    } catch (e) {
      return [];
    }
  }

  VpnServer _createVpnServerFromMap(Map<String, dynamic> json) {
    final String type = json['type'] ?? 'vless';
    final String serverAddress = json['server'] ?? json['address'] ?? '';
    final int serverPort = json['server_port'] ?? json['port'] ?? 443;
    final String flag = _getCountryFlag(serverAddress);
    final String city = _getCity(serverAddress);
    final String name = '$flag $city'; // Default name

    // Enrich JSON with UI helpers if missing
    json['flag'] = flag;
    json['city'] = city;
    json['name'] = json['name'] ?? name; // Preserve name if exists
    
    // Ensure critical fields exist
    json['address'] = serverAddress;
    json['port'] = serverPort;
    json['type'] = type;

    return VpnServer(
      id: serverAddress, // ID as address for now, ideally UUID
      name: json['name'],
      config: jsonEncode(json),
      ping: '--',
    );
  }

  List<VpnServer> _parseMultiLineConfig(String content) {
    List<VpnServer> servers = [];
    final lines = content.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      
      final server = _parseSingleServer(line.trim());
      servers.add(server);
    }

    return servers;
  }

  VpnServer _parseSingleServer(String uriString) {
    Map<String, dynamic> configMap = {};

    if (uriString.startsWith('vmess://')) {
      configMap = _parseVmessToMap(uriString);
    } else if (uriString.startsWith('vless://')) {
      configMap = _parseVlessToMap(uriString);
    } else if (uriString.startsWith('trojan://')) {
      configMap = _parseTrojanToMap(uriString);
    } else if (uriString.startsWith('ss://')) {
      configMap = _parseShadowsocksToMap(uriString);
    } else if (uriString.startsWith('ssr://')) {
       // SSR not fully supported in SingBoxConfig logic yet, treating as generic
       configMap = {'type': 'ssr', 'raw': uriString};
    } else {
       configMap = {'type': 'unknown', 'raw': uriString};
    }

    final String address = configMap['address'] ?? 'unknown';
    final String name = configMap['name'] ?? 'Unknown';

    return VpnServer(
      id: address,
      name: name,
      config: jsonEncode(configMap),
      ping: '--',
    );
  }

  Map<String, dynamic> _parseVmessToMap(String vmessUrl) {
    try {
      final String encoded = vmessUrl.replaceFirst('vmess://', '');
      final String decoded = utf8.decode(base64Decode(base64.normalize(encoded)));
      final Map<String, dynamic> json = jsonDecode(decoded);

      final String address = json['add'] ?? json['address'] ?? '';
      final int port = json['port'] is String ? int.tryParse(json['port']) ?? 443 : json['port'] ?? 443;
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);
      final String ps = json['ps'] ?? '';

      return {
        'type': 'vmess',
        'address': address,
        'port': port,
        'uuid': json['id'],
        'security': json['tls'] == 'tls' ? 'tls' : 'none',
        'transport': json['net'] ?? 'tcp',
        'path': json['path'],
        'host': json['host'],
        'sni': json['sni'] ?? json['host'],
        'alpn': json['alpn'],
        'allowInsecure': json['verify_cert'] == false || json['allowInsecure'] == 1,
        'name': ps.isNotEmpty ? ps : '$flag $city',
        'flag': flag,
        'city': city,
      };
    } catch (e) {
      return {'type': 'error', 'name': 'VMess Parse Error'};
    }
  }

  Map<String, dynamic> _parseVlessToMap(String vlessUrl) {
    try {
      final String uri = vlessUrl.replaceFirst('vless://', '');
      final List<String> parts = uri.split('#');
      final String mainPart = parts[0];
      String remark = '';
      if (parts.length > 1) remark = Uri.decodeComponent(parts[1]);
      
      final List<String> atParts = mainPart.split('@');
      final String uuid = atParts[0];
      final String rest = atParts[1];
      
      final List<String> queryParts = rest.split('?');
      final String addressPort = queryParts[0];
      final List<String> addrParts = addressPort.split(':');
      final String address = addrParts[0];
      final int port = int.tryParse(addrParts[1]) ?? 443;
      
      Map<String, dynamic> paramsMap = {};
      if (queryParts.length > 1) {
        final params = Uri.splitQueryString(queryParts[1]);
        paramsMap = {
            'security': params['security'] ?? 'tls',
            'transport': params['type'] ?? 'tcp',
            'path': params['path']?.isNotEmpty == true ? Uri.decodeComponent(params['path']!) : null,
            'host': params['host']?.isNotEmpty == true ? params['host'] : null,
            'sni': params['sni']?.isNotEmpty == true ? params['sni'] : null,
            'alpn': params['alpn']?.isNotEmpty == true ? Uri.decodeComponent(params['alpn']!) : null,
            'allowInsecure': params['allowInsecure'] == '1',
            'fingerprint': params['fp'],
            'pbk': params['pbk'],
            'sid': params['sid'],
            'serviceName': params['serviceName'],
        };
      }
      
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);

      return {
        'type': 'vless',
        'address': address,
        'port': port,
        'uuid': uuid,
        'name': remark.isNotEmpty ? remark : '$flag $city',
        'flag': flag,
        'city': city,
        ...paramsMap,
      };
    } catch (e) {
      return {'type': 'error', 'name': 'VLESS Parse Error'};
    }
  }

  Map<String, dynamic> _parseTrojanToMap(String trojanUrl) {
    try {
      final String uri = trojanUrl.replaceFirst('trojan://', '');
      final List<String> parts = uri.split('#');
      final String mainPart = parts[0];
      String remark = '';
      if (parts.length > 1) remark = Uri.decodeComponent(parts[1]);
      
      final List<String> atParts = mainPart.split('@');
      final String password = atParts[0];
      final String rest = atParts[1];
      
      final List<String> queryParts = rest.split('?');
      final String addressPort = queryParts[0];
      final List<String> addrParts = addressPort.split(':');
      final String address = addrParts[0];
      final int port = int.tryParse(addrParts[1]) ?? 443;
      
      Map<String, dynamic> paramsMap = {};
      if (queryParts.length > 1) {
        final params = Uri.splitQueryString(queryParts[1]);
        paramsMap = {
            'sni': params['sni'],
            'alpn': params['alpn'] != null ? Uri.decodeComponent(params['alpn']!) : null,
            'allowInsecure': params['allowInsecure'] == '1',
            'security': params['security'] ?? 'tls',
            'type': params['type'] ?? 'tcp',
        };
      }
      
      final String flag = _getCountryFlag(address);
      final String city = _getCity(address);

      return {
        'type': 'trojan',
        'address': address,
        'port': port,
        'password': password,
        'name': remark.isNotEmpty ? remark : '$flag $city',
        'flag': flag,
        'city': city,
        ...paramsMap,
      };
    } catch (e) {
      return {'type': 'error', 'name': 'Trojan Parse Error'};
    }
  }

  Map<String, dynamic> _parseShadowsocksToMap(String ssUrl) {
     try {
        final uri = ssUrl.replaceFirst('ss://', '');
        final parts = uri.split('@');
        if (parts.length != 2) throw FormatException('Invalid SS URL');
        
        final authParts = parts[0].split(':');
        final serverParts = parts[1].split(':');
        final portAndName = serverParts[1].split('#');
        
        return {
          'type': 'ss',
          'method': authParts[0],
          'password': authParts[1],
          'address': serverParts[0],
          'port': int.tryParse(portAndName[0]) ?? 8388,
          'name': Uri.decodeComponent(portAndName.length > 1 ? portAndName[1] : 'SS Server'),
        };
     } catch (e) {
        return {'type': 'error', 'name': 'SS Parse Error: ${e.toString()}'};
     }
  }

  String _getCountryFlag(String server) {
    if (server.endsWith('.tr') || server.contains('.tr')) return '🇹🇷';
    if (server.contains('89.35.73')) return '🇹🇷';
    if (server.contains('194.62.54')) return '🇳🇱';
    if (server.endsWith('.de') || server.contains('.de')) return '🇩🇪';
    if (server.endsWith('.nl') || server.contains('.nl')) return '🇳🇱';
    if (server.endsWith('.us') || server.contains('.us')) return '🇺🇸';
    if (server.endsWith('.fr') || server.contains('.fr')) return '🇫🇷';
    if (server.endsWith('.uk') || server.contains('.uk')) return '🇬🇧';
    if (server.endsWith('.ru') || server.contains('.ru')) return '🇷🇺';
    if (server.endsWith('.jp') || server.contains('.jp')) return '🇯🇵';
    if (server.endsWith('.sg') || server.contains('.sg')) return '🇸🇬';
    if (server.endsWith('.hk') || server.contains('.hk')) return '🇭🇰';
    return '🌐';
  }

  String _getCity(String server) {
    if (server.contains('theyusa') || server.contains('89.35.73')) return 'Turkey';
    if (server.contains('rebecca') || server.contains('194.62.54')) return 'Netherlands';
    if (server.contains('germany') || server.contains('.de')) return 'Germany';
    if (server.contains('netherlands') || server.contains('.nl')) return 'Netherlands';
    if (server.contains('united') || server.contains('.us')) return 'United States';
    if (server.contains('singapore') || server.contains('.sg')) return 'Singapore';
    if (server.contains('japan') || server.contains('.jp')) return 'Japan';
    if (server.contains('uk') || server.contains('.uk')) return 'United Kingdom';
    return 'Unknown';
  }
}
