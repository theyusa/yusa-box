class VpnConfig {
  final String serverAddress;
  final int serverPort;
  final String protocol;
  final String uuid;
  final String? password;
  final bool tlsEnabled;
  final String? sni;

  VpnConfig({
    required this.serverAddress,
    required this.serverPort,
    required this.protocol,
    required this.uuid,
    this.password,
    this.tlsEnabled = true,
    this.sni,
  });

  String toSingBoxConfig() {
    return '''
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "8.8.8.8"
      },
      {
        "tag": "local",
        "address": "local",
        "detour": "direct"
      }
    ],
    "rules": [],
    "strategy": "prefer_ipv4"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "inet4_address": "172.19.0.1/30",
      "auto_route": true,
      "strict_route": true,
      "stack": "system",
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "$protocol",
      "tag": "proxy",
      "server": "$serverAddress",
      "server_port": $serverPort,
      "uuid": "$uuid",
      ${password != null ? '"password": "$password",' : ''}
      ${tlsEnabled ? '''
      "tls": {
        "enabled": true,
        ${sni != null ? '"server_name": "$sni",' : ''}
        "insecure": false
      }
      ''' : ''}
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "geoip": "private",
        "outbound": "direct"
      }
    ],
    "auto_detect_interface": true
  }
}
''';
  }
}
