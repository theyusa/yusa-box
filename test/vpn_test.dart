import 'package:flutter_test/flutter_test.dart';
import 'package:yusa_box/models/vpn_config.dart';
import 'package:yusa_box/models/vpn_status.dart';

void main() {
  group('VpnStatus Tests', () {
    test('VpnStatus should initialize correctly', () {
      final status = VpnStatus(
        state: VpnState.disconnected,
        message: 'Test message',
        uploadSpeed: 100,
        downloadSpeed: 200,
        connectedTime: Duration(seconds: 10),
      );

      expect(status.state, VpnState.disconnected);
      expect(status.message, 'Test message');
      expect(status.uploadSpeed, 100);
      expect(status.downloadSpeed, 200);
      expect(status.connectedTime, Duration(seconds: 10));
      expect(status.isConnected, false);
      expect(status.isDisconnected, true);
    });

    test('VpnStatus connected state', () {
      final status = VpnStatus(state: VpnState.connected);
      expect(status.isConnected, true);
      expect(status.isConnecting, false);
      expect(status.isDisconnected, false);
    });

    test('VpnStatus connecting state', () {
      final status = VpnStatus(state: VpnState.connecting);
      expect(status.isConnecting, true);
      expect(status.isConnected, false);
    });

    test('VpnStatus error state', () {
      final status = VpnStatus(
        state: VpnState.error,
        message: 'Connection failed',
      );
      expect(status.state, VpnState.error);
      expect(status.message, 'Connection failed');
    });
  });

  group('VpnConfig Tests', () {
    test('VpnConfig should initialize correctly', () {
      final config = VpnConfig(
        serverAddress: 'example.com',
        serverPort: 443,
        protocol: 'vless',
        uuid: '123e4567-e89b-12d3-a456-426614174000',
        password: 'password123',
        tlsEnabled: true,
        sni: 'sni.example.com',
      );

      expect(config.serverAddress, 'example.com');
      expect(config.serverPort, 443);
      expect(config.protocol, 'vless');
      expect(config.uuid, '123e4567-e89b-12d3-a456-426614174000');
      expect(config.password, 'password123');
      expect(config.tlsEnabled, true);
      expect(config.sni, 'sni.example.com');
    });

    test('VpnConfig toSingBoxConfig should produce valid JSON', () {
      final config = VpnConfig(
        serverAddress: 'example.com',
        serverPort: 443,
        protocol: 'vless',
        uuid: '123e4567-e89b-12d3-a456-426614174000',
        tlsEnabled: true,
      );

      final jsonConfig = config.toSingBoxConfig();
      expect(jsonConfig, contains('example.com'));
      expect(jsonConfig, contains('443'));
      expect(jsonConfig, contains('vless'));
      expect(jsonConfig, contains('123e4567-e89b-12d3-a456-426614174000'));
    });

    test('VpnConfig with TLS enabled', () {
      final config = VpnConfig(
        serverAddress: 'example.com',
        serverPort: 443,
        protocol: 'vless',
        uuid: 'test-uuid',
        tlsEnabled: true,
        sni: 'sni.example.com',
      );

      final jsonConfig = config.toSingBoxConfig();
      expect(jsonConfig, contains('tls'));
      expect(jsonConfig, contains('sni.example.com'));
    });

    test('VpnConfig with TLS disabled', () {
      final config = VpnConfig(
        serverAddress: 'example.com',
        serverPort: 443,
        protocol: 'vless',
        uuid: 'test-uuid',
        tlsEnabled: false,
      );

      final jsonConfig = config.toSingBoxConfig();
      expect(jsonConfig, isNot(contains('tls')));
    });
  });
}
