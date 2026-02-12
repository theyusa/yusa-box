import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vpn_models.dart';

class SubscriptionService {
  Future<List<VPNServer>> fetchServers(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final content = response.body.trim();
        // Check if content is base64 encoded
        String decodedContent = content;
        try {
          decodedContent = utf8.decode(base64.decode(content));
        } catch (e) {
          // Not base64 or failed, use raw content
        }

        final lines = decodedContent.split(RegExp(r'\r?\n'));
        final List<VPNServer> servers = [];

        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;

          if (line.startsWith('vless://')) {
            final server = _parseVless(line);
            if (server != null) servers.add(server);
          } else if (line.startsWith('vmess://')) {
            final server = _parseVmess(line);
            if (server != null) servers.add(server);
          }
          // Add other protocols as needed
        }

        return servers;
      } else {
        throw Exception('Failed to load subscription: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription: $e');
    }
  }

  VPNServer? _parseVless(String link) {
    try {
      final uri = Uri.parse(link);
      final userInfo = uri.userInfo;
      final host = uri.host;
      final port = uri.port;
      final queryParams = uri.queryParameters;
      final fragment = uri.fragment; // Name usually here

      return VPNServer(
        id: link.hashCode.toString(), // Simple ID generation
        name: fragment.isNotEmpty ? fragment : '$host:$port',
        address: host,
        port: port,
        flag: 'UNKNOWN', // Need a way to determine flag/country
        city: 'Unknown',
        protocol: 'vless',
        // config: link, // Store raw link for now
      );
    } catch (e) {
      print('Error parsing vless: $e');
      return null;
    }
  }

  VPNServer? _parseVmess(String link) {
    try {
      // Vmess is usually base64 encoded JSON
      final content = link.substring(8); // Remove vmess://
      final jsonString = utf8.decode(base64.decode(content));
      final Map<String, dynamic> data = json.decode(jsonString);

      return VPNServer(
        id: link.hashCode.toString(),
        name: data['ps'] ?? 'Vmess Server',
        address: data['add'] ?? '',
        port: int.tryParse(data['port'].toString()) ?? 443,
        flag: 'UNKNOWN',
        city: 'Unknown',
        protocol: 'vmess',
        // config: link,
      );
    } catch (e) {
      print('Error parsing vmess: $e');
      return null;
    }
  }
}
