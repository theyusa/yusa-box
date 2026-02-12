import 'package:flutter/services.dart';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';

class VpnService {
  static const platform = MethodChannel('com.yusabox.vpn/service');
  static const eventChannel = EventChannel('com.yusabox.vpn/status');

  Stream<VpnStatus> get statusStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      final data = Map<String, dynamic>.from(event);
      return VpnStatus(
        state: VpnState.values[data['state'] ?? 0],
        message: data['message'],
        uploadSpeed: data['uploadSpeed'] ?? 0,
        downloadSpeed: data['downloadSpeed'] ?? 0,
        connectedTime: data['connectedTime'] != null
            ? Duration(seconds: data['connectedTime'])
            : null,
      );
    });
  }

  Future<bool> startVpn(VpnConfig config) async {
    try {
      final result = await platform.invokeMethod('startVpn', {
        'config': config.toSingBoxConfig(),
      });
      return result as bool;
    } on PlatformException catch (e) {
      print('VPN başlatma hatası: ${e.message}');
      return false;
    }
  }

  Future<bool> stopVpn() async {
    try {
      final result = await platform.invokeMethod('stopVpn');
      return result as bool;
    } on PlatformException catch (e) {
      print('VPN durdurma hatası: ${e.message}');
      return false;
    }
  }

  Future<bool> requestVpnPermission() async {
    try {
      final result = await platform.invokeMethod('requestPermission');
      return result as bool;
    } on PlatformException catch (e) {
      print('VPN izin hatası: ${e.message}');
      return false;
    }
  }

  Future<Map<String, int>> getTrafficStats() async {
    try {
      final result = await platform.invokeMethod('getTrafficStats');
      return Map<String, int>.from(result);
    } catch (e) {
      return {'upload': 0, 'download': 0};
    }
  }
}
