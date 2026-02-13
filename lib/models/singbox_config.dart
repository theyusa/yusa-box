class SingBoxConfig {
  final Map<String, dynamic> _data;

  SingBoxConfig(this._data);

  Map<String, dynamic> buildOutbound() {
    final protocol = _data['type']?.toString().toLowerCase() ?? 'vless';

    switch (protocol) {
      case 'vless':
        return _buildVlessOutbound();
      case 'vmess':
        return _buildVmessOutbound();
      case 'trojan':
        return _buildTrojanOutbound();
      default:
        return _buildVlessOutbound();
    }
  }

  Map<String, dynamic> _buildVlessOutbound() {
    final Map<String, dynamic> config = {
      'type': 'vless',
      'tag': 'proxy',
      'server': _data['server'] ?? _data['address'] ?? '127.0.0.1',
      'server_port': _data['server_port'] ?? _data['port'] ?? 443,
    };

    if (_data['uuid'] != null) config['uuid'] = _data['uuid'];

    if (_data['flow'] != null) config['flow'] = _data['flow'];

    if (_data['network'] != null) {
      final network = _data['network']?.toString();
      config['network'] = network == 'tcp' || network == 'udp' ? network : null;
    }

    if (_data['packet_encoding'] != null) config['packet_encoding'] = _data['packet_encoding'];

    final tls = _buildTLSConfig();
    if (tls.isNotEmpty) config['tls'] = tls;

    final multiplex = _buildMultiplexConfig();
    if (multiplex.isNotEmpty) config['multiplex'] = multiplex;

    final transport = _buildTransportConfig();
    if (transport.isNotEmpty) config['transport'] = transport;

    return _removeNulls(config);
  }

  Map<String, dynamic> _buildVmessOutbound() {
    final Map<String, dynamic> config = {
      'type': 'vmess',
      'tag': 'proxy',
      'server': _data['server'] ?? _data['address'] ?? '127.0.0.1',
      'server_port': _data['server_port'] ?? _data['port'] ?? 443,
    };

    if (_data['uuid'] != null) config['uuid'] = _data['uuid'];

    if (_data['security'] != null) config['security'] = _data['security'];

    if (_data['alter_id'] != null) config['alter_id'] = _data['alter_id'];

    if (_data['global_padding'] != null) config['global_padding'] = _data['global_padding'];

    if (_data['authenticated_length'] != null) config['authenticated_length'] = _data['authenticated_length'];

    if (_data['network'] != null) {
      final network = _data['network']?.toString();
      config['network'] = network == 'tcp' || network == 'udp' ? network : null;
    }

    if (_data['packet_encoding'] != null) config['packet_encoding'] = _data['packet_encoding'];

    final tls = _buildTLSConfig();
    if (tls.isNotEmpty) config['tls'] = tls;

    final multiplex = _buildMultiplexConfig();
    if (multiplex.isNotEmpty) config['multiplex'] = multiplex;

    final transport = _buildTransportConfig();
    if (transport.isNotEmpty) config['transport'] = transport;

    return _removeNulls(config);
  }

  Map<String, dynamic> _buildTrojanOutbound() {
    final Map<String, dynamic> config = {
      'type': 'trojan',
      'tag': 'proxy',
      'server': _data['server'] ?? _data['address'] ?? '127.0.0.1',
      'server_port': _data['server_port'] ?? _data['port'] ?? 443,
    };

    if (_data['password'] != null) config['password'] = _data['password'];

    if (_data['network'] != null) {
      final network = _data['network']?.toString();
      config['network'] = network == 'tcp' || network == 'udp' ? network : null;
    }

    final tls = _buildTLSConfig();
    if (tls.isNotEmpty) config['tls'] = tls;

    final multiplex = _buildMultiplexConfig();
    if (multiplex.isNotEmpty) config['multiplex'] = multiplex;

    final transport = _buildTransportConfig();
    if (transport.isNotEmpty) config['transport'] = transport;

    return _removeNulls(config);
  }

  Map<String, dynamic> _buildTLSConfig() {
    final security = _data['security']?.toString().toLowerCase() ?? 'none';
    if (security == 'none') return {};

    final Map<String, dynamic> tls = {};

    if (security == 'reality') {
      tls['enabled'] = true;
      tls['reality'] = {
        'enabled': true,
        'public_key': _data['pbk'] ?? _data['public_key'],
        'short_id': _data['sid'] ?? _data['short_id'],
      };
    } else {
      tls['enabled'] = true;
      tls['server_name'] = _data['sni'] ?? _data['host'];
    }

    if (_data['alpn'] != null) {
      tls['alpn'] = _data['alpn'] is List ? _data['alpn'] : [_data['alpn']];
    }

    if (_data['fingerprint'] != null) {
      tls['utls'] = {
        'enabled': true,
        'fingerprint': _data['fingerprint'],
      };
    }

    if (_data['allowInsecure'] == true || _data['allowInsecure'] == '1') {
      tls['insecure'] = true;
    }

    return _removeNulls(tls);
  }

  Map<String, dynamic> _buildMultiplexConfig() {
    final Map<String, dynamic> multiplex = {};
    return _removeNulls(multiplex);
  }

  Map<String, dynamic> _buildTransportConfig() {
    final transportType = _data['transport'] ?? _data['network'] ?? 'tcp';
    if (transportType == 'tcp') return {};

    final Map<String, dynamic> transport = {
      'type': transportType.toString(),
    };

    if (_data['path'] != null && transportType != 'grpc') {
      transport['path'] = _data['path'];
    }

    if (_data['host'] != null) {
      transport['headers'] = {
        'Host': _data['host'],
      };
    }

    if (transportType == 'grpc') {
      transport['service_name'] = _data['path'] ?? _data['service_name'];
      transport.remove('path');
    }

    return _removeNulls(transport);
  }

  Map<String, dynamic> _removeNulls(Map<String, dynamic> map) {
    final keys = List<String>.from(map.keys);
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        map.remove(key);
      } else if (value is Map<String, dynamic>) {
        map[key] = _removeNulls(value);
        if ((map[key] as Map).isEmpty) map.remove(key);
      } else if (value is List && value.isEmpty) {
        map.remove(key);
      }
    }
    return map;
  }
}
