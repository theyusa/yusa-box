class SingBoxConfig {
  final Map<String, dynamic> _data;

  SingBoxConfig(this._data);

  Map<String, dynamic> buildOutbound() {
    // 1. Temel Katman (Base)
    final Map<String, dynamic> config = {
      'type': _data['type'] ?? _data['protocol'], // protocol veya type
      'tag': _data['tag'] ?? 'proxy',
      'server': _data['server'] ?? _data['address'],
      'server_port': _data['server_port'] ?? _data['port'],
    };

    // 2. Kimlik Doğrulama (Auth)
    if (_data['uuid'] != null) config['uuid'] = _data['uuid'];
    if (_data['password'] != null) config['password'] = _data['password'];
    if (_data['method'] != null) config['method'] = _data['method']; // SS için

    // 3. TLS Katmanı
    // 'security' alanı 'tls', 'reality' veya 'none' olabilir.
    // Bazen 'tls' bool veya string gelebilir, kontrol edelim.
    final String security = _data['security']?.toString() ?? 'none';
    
    if (security == 'tls' || security == 'reality') {
      final tls = <String, dynamic>{
        'enabled': true,
        'server_name': _data['sni'] ?? _data['host'],
        'alpn': _data['alpn'] is List ? _data['alpn'] : (_data['alpn'] != null ? [_data['alpn']] : null),
      };

      if (security == 'reality') {
        tls['reality'] = {
          'enabled': true,
          'public_key': _data['pbk'] ?? _data['publicKey'], // pbk veya publicKey
          'short_id': _data['sid'] ?? _data['shortId'], // sid veya shortId
        };
      }

      if (_data['fingerprint'] != null) {
        tls['utls'] = {'enabled': true, 'fingerprint': _data['fingerprint']};
      }
      
      // allowInsecure bazen string "1" veya bool true gelebilir
      if (_data['allowInsecure'] == true || _data['allowInsecure'] == '1') {
        tls['insecure'] = true;
      }

      config['tls'] = _removeNulls(tls);
    }

    // 4. Transport Katmanı (Dinamik)
    final String? transportType = _data['transport'] ?? _data['network'];
    if (transportType != null && transportType != 'tcp') {
      final transport = <String, dynamic>{
        'type': transportType,
        'path': _data['path'],
        'headers': _data['host'] != null ? {'Host': _data['host']} : null,
      };
      
      // gRPC özel ayarı
      if (transportType == 'grpc') {
        transport['service_name'] = _data['path'] ?? _data['serviceName'];
        // gRPC'de path yerine service_name kullanılır, path'i temizleyelim karmaşa olmasın
        transport.remove('path'); 
      }

      config['transport'] = _removeNulls(transport);
    }

    return _removeNulls(config);
  }

  // Null değerleri temizleyen yardımcı fonksiyon
  Map<String, dynamic> _removeNulls(Map<String, dynamic> map) {
    // Recursive temizleme yapılabilir ama şimdilik shallow yeterli olabilir.
    // Ancak iç içe map'lerde null kalmaması için map değerlerini de kontrol etmek iyi olur.
    final keys = List<String>.from(map.keys);
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        map.remove(key);
      } else if (value is Map<String, dynamic>) {
        map[key] = _removeNulls(value);
        if ((map[key] as Map).isEmpty) map.remove(key); // Boş map'i sil
      }
    }
    return map;
  }
}
