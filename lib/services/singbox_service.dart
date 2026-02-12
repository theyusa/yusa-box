import 'package:flutter/services.dart';

class SingboxService {
  static const MethodChannel _channel = MethodChannel('com.yusabox.vpn/singbox');

  Future<void> start(String configContent) async {
    try {
      await _channel.invokeMethod('start', {'config': configContent});
    } on PlatformException catch (e) {
      throw Exception('Failed to start Singbox: ${e.message}');
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop Singbox: ${e.message}');
    }
  }

  Future<String> getStats() async {
    try {
      final String result = await _channel.invokeMethod('getStats');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to get stats: ${e.message}');
    }
  }
}
