import 'package:flutter/services.dart';

class VpnService {
  static const platform = MethodChannel('com.yusabox.vpn/service');
  static const eventChannel = EventChannel('com.yusabox.vpn/status');

  Stream<Map<String, dynamic>> get statusStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }

  Future<bool> requestVpnPermission() async {
    try {
      final result = await platform.invokeMethod('requestPermission');
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startVpn(String config, {String? serverName}) async {
    try {
      final result = await platform.invokeMethod('startVpn', {
        'config': config,
        if (serverName != null) 'serverName': serverName,
      });
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopVpn() async {
    try {
      final result = await platform.invokeMethod('stopVpn');
      return result as bool;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> reconnect() async {
    try {
      final result = await platform.invokeMethod('reconnect');
      return result as bool;
    } catch (e) {
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

  Future<String> getStats() async {
    try {
      final result = await platform.invokeMethod('getStats');
      return result as String;
    } catch (e) {
      return 'Hata: ${e.toString()}';
    }
  }
  
  Future<List<String>> getLogs() async {
    try {
      final result = await platform.invokeMethod('getLogs');
      return List<String>.from(result);
    } catch (e) {
      return <String>[];
    }
  }
}
