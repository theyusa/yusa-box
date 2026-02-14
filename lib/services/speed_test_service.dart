import 'package:flutter/services.dart';

class SpeedTestResult {
  final double uploadSpeed;
  final double downloadSpeed;
  final int ping;
  final String serverName;

  SpeedTestResult({
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.ping,
    required this.serverName,
  });

  factory SpeedTestResult.fromJson(Map<String, dynamic> json) {
    return SpeedTestResult(
      uploadSpeed: (json['uploadSpeed'] as num).toDouble(),
      downloadSpeed: (json['downloadSpeed'] as num).toDouble(),
      ping: json['ping'] as int,
      serverName: json['serverName'] as String,
    );
  }

  String get uploadSpeedFormatted => _formatSpeed(uploadSpeed);
  String get downloadSpeedFormatted => _formatSpeed(downloadSpeed);

  String _formatSpeed(double speedMbps) {
    if (speedMbps < 1) {
      final speedKbps = speedMbps * 1000;
      return '${speedKbps.toStringAsFixed(0)} Kbps';
    }
    return '${speedMbps.toStringAsFixed(2)} Mbps';
  }
}

class SpeedTestService {
  static const platform = MethodChannel('com.yusabox.vpn/speedtest');
  static const eventChannel = EventChannel('com.yusabox.vpn/speedtest/status');

  Stream<Map<String, dynamic>> get statusStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }

  Future<bool> startSpeedTest(String serverAddress, String serverName) async {
    try {
      final result = await platform.invokeMethod('startSpeedTest', {
        'serverAddress': serverAddress,
        'serverName': serverName,
      });
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopSpeedTest() async {
    try {
      final result = await platform.invokeMethod('stopSpeedTest');
      return result as bool;
    } catch (e) {
      return false;
    }
  }
}
