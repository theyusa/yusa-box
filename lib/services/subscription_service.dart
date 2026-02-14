import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vpn_models.dart';

class SubscriptionService {
  static const String _ipInfoApiUrl = 'https://ipinfo.io/';
  static final Map<String, _GeoInfo> _geoCache = {};

  static Future<_GeoInfo> _getGeoInfo(String address) async {
    if (_geoCache.containsKey(address)) {
      return _geoCache[address]!;
    }

    try {
      final response = await http
          .get(Uri.parse('$_ipInfoApiUrl$address/json'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geoInfo = _GeoInfo(
          country: data['country'] ?? '',
          city: data['city'] ?? 'Unknown',
        );
        _geoCache[address] = geoInfo;
        return geoInfo;
      }
    } catch (e) {
      // API hatası, varsayılan değerler döndür
    }

    final defaultInfo = _GeoInfo(country: '', city: 'Unknown');
    _geoCache[address] = defaultInfo;
    return defaultInfo;
  }

  static String _countryCodeToFlag(String countryCode) {
    if (countryCode.isEmpty) return '🌐';

    final base = 0x1F1E6;
    final letters = countryCode.toUpperCase().codeUnits;
    if (letters.length != 2) return '🌐';

    return String.fromCharCode(base + letters[0] - 0x41) +
        String.fromCharCode(base + letters[1] - 0x41);
  }

  static void clearGeoCache() {
    _geoCache.clear();
  }

  Future<List<VpnServer>> fetchServersFromSubscription(
    String subscriptionUrl,
  ) async {
    try {
      clearGeoCache();
      final response = await http.get(Uri.parse(subscriptionUrl));

      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);

        if (subscriptionUrl.startsWith('vmess://') ||
            subscriptionUrl.startsWith('vless://') ||
            subscriptionUrl.startsWith('trojan://')) {
          final server = await _parseSingleServer(subscriptionUrl);
          return [server];
        } else if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
          return await _parseJsonConfig(body);
        } else {
          try {
            final decoded = base64Decode(base64.normalize(body.trim()));
            final String content = utf8.decode(decoded);

            if (content.trim().startsWith('{') ||
                content.trim().startsWith('[')) {
              return await _parseJsonConfig(content);
            } else if (content.contains('\n')) {
              return await _parseMultiLineConfig(content);
            } else {
              final server = await _parseSingleServer(content);
              return [server];
            }
          } catch (e) {
            // If base64 decode fails, treat as plain text
            if (body.contains('\n')) {
              return await _parseMultiLineConfig(body);
            } else {
              final server = await _parseSingleServer(body.trim());
              return [server];
            }
          }
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Subscription fetch error: ${e.toString()}');
    }
  }

  Future<List<VpnServer>> _parseJsonConfig(String jsonContent) async {
    try {
      final dynamic json = jsonDecode(jsonContent);
      List<VpnServer> servers = [];

      if (json is List) {
        for (var item in json) {
          final server = await _createVpnServerFromMap(
            item as Map<String, dynamic>,
          );
          servers.add(server);
        }
      } else if (json is Map) {
        final server = await _createVpnServerFromMap(
          json as Map<String, dynamic>,
        );
        servers.add(server);
      }

      return servers;
    } catch (e) {
      return [];
    }
  }

  Future<VpnServer> _createVpnServerFromMap(Map<String, dynamic> json) async {
    final String type = json['type'] ?? 'vless';
    final String serverAddress = json['server'] ?? json['address'] ?? '';
    final int serverPort = json['server_port'] ?? json['port'] ?? 443;

    // Geo info from IP
    final geoInfo = await _getGeoInfo(serverAddress);
    final String flag = _countryCodeToFlag(geoInfo.country);
    final String city = geoInfo.city;

    final String name = json['name'] ?? '$flag $city';

    // Unique ID: address + port + protocol
    final String uniqueId = '$serverAddress:$serverPort:$type';

    // Enrich JSON with UI helpers
    json['flag'] = flag;
    json['city'] = city;
    json['name'] = name;

    // Ensure critical fields exist
    json['address'] = serverAddress;
    json['port'] = serverPort;
    json['server'] = serverAddress;
    json['server_port'] = serverPort;
    json['type'] = type;

    return VpnServer(
      id: uniqueId,
      name: name,
      config: jsonEncode(json),
      ping: '--',
    );
  }

  Future<List<VpnServer>> _parseMultiLineConfig(String content) async {
    List<VpnServer> servers = [];
    final lines = content.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      final server = await _parseSingleServer(line.trim());
      servers.add(server);
    }

    return servers;
  }

  Future<VpnServer> _parseSingleServer(String uriString) async {
    Map<String, dynamic> configMap = {};

    if (uriString.startsWith('vmess://')) {
      configMap = await _parseVmessToMap(uriString);
    } else if (uriString.startsWith('vless://')) {
      configMap = await _parseVlessToMap(uriString);
    } else if (uriString.startsWith('trojan://')) {
      configMap = await _parseTrojanToMap(uriString);
    } else {
      configMap = {'type': 'unknown', 'raw': uriString};
    }

    final String address = configMap['address'] ?? 'unknown';
    final String port = configMap['port']?.toString() ?? '443';
    final String type = configMap['type'] ?? 'unknown';
    final String name = configMap['name'] ?? 'Unknown';

    // Unique ID: address + port + protocol
    final String uniqueId = '$address:$port:$type';

    return VpnServer(
      id: uniqueId,
      name: name,
      config: jsonEncode(configMap),
      ping: '--',
    );
  }

  Future<Map<String, dynamic>> _parseVmessToMap(String vmessUrl) async {
    try {
      final String encoded = vmessUrl.replaceFirst('vmess://', '');
      final String decoded = utf8.decode(
        base64Decode(base64.normalize(encoded)),
      );
      final Map<String, dynamic> json = jsonDecode(decoded);

      final String address = json['add'] ?? json['address'] ?? '';
      final int port = json['port'] is String
          ? int.tryParse(json['port']) ?? 443
          : json['port'] ?? 443;
      final ps = json['ps'] ?? '';

      final geoInfo = await _getGeoInfo(address);
      final String flag = _countryCodeToFlag(geoInfo.country);
      final String city = geoInfo.city;

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
        'allowInsecure':
            json['verify_cert'] == false || json['allowInsecure'] == 1,
        'name': ps.isNotEmpty ? ps : '$flag $city',
        'flag': flag,
        'city': city,
      };
    } catch (e) {
      return {'type': 'error', 'name': 'VMess Parse Error'};
    }
  }

  Future<Map<String, dynamic>> _parseVlessToMap(String vlessUrl) async {
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
          'path': params['path']?.isNotEmpty == true
              ? Uri.decodeComponent(params['path']!)
              : null,
          'host': params['host']?.isNotEmpty == true ? params['host'] : null,
          'sni': params['sni']?.isNotEmpty == true ? params['sni'] : null,
          'alpn': params['alpn']?.isNotEmpty == true
              ? Uri.decodeComponent(params['alpn']!)
              : null,
          'allowInsecure': params['allowInsecure'] == '1',
          'fingerprint': params['fp'],
          'pbk': params['pbk'],
          'sid': params['sid'],
          'serviceName': params['serviceName'],
        };
      }

      final geoInfo = await _getGeoInfo(address);
      final String flag = _countryCodeToFlag(geoInfo.country);
      final String city = geoInfo.city;

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

  Future<Map<String, dynamic>> _parseTrojanToMap(String trojanUrl) async {
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
          'alpn': params['alpn'] != null
              ? Uri.decodeComponent(params['alpn']!)
              : null,
          'allowInsecure': params['allowInsecure'] == '1',
          'security': params['security'] ?? 'tls',
          'type': params['type'] ?? 'tcp',
        };
      }

      final geoInfo = await _getGeoInfo(address);
      final String flag = _countryCodeToFlag(geoInfo.country);
      final String city = geoInfo.city;

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
}

class _GeoInfo {
  final String country;
  final String city;

  _GeoInfo({required this.country, required this.city});
}
