import 'package:flutter/services.dart';

class PingResult {
  final String serverId;
  final int? latencyMs;
  final bool? success;
  final bool isLoading;

  PingResult({
    required this.serverId,
    this.latencyMs,
    this.success,
    this.isLoading = false,
  });

  factory PingResult.fromJson(Map<String, dynamic> json) {
    return PingResult(
      serverId: json['serverId'] as String,
      latencyMs: json['latencyMs'] as int?,
      success: json['success'] as bool?,
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  bool get isSuccess => success == true;
  bool get isFailed => success == false;
  bool get isTimeout => latencyMs == -1;

  String get displayText {
    if (isLoading) {
      return '...';
    }
    if (isTimeout || isFailed) {
      return 'Zaman Aşımı';
    }
    if (latencyMs != null) {
      return '${latencyMs}ms';
    }
    return '--';
  }

  String get statusText {
    if (isLoading) return 'Pingleniyor...';
    if (isTimeout) return 'Zaman Aşımı';
    if (isFailed) return 'Hata';
    if (isSuccess) return '${latencyMs}ms';
    return '--';
  }
}

class PingService {
  static const platform = MethodChannel('com.yusabox.vpn/ping');
  static const eventChannel = EventChannel('com.yusabox.vpn/ping/status');

  Stream<PingResult> get pingStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      return PingResult.fromJson(Map<String, dynamic>.from(event));
    });
  }

  Future<bool> pingServer(String serverId, String address, int port) async {
    try {
      final result = await platform.invokeMethod('pingServer', {
        'serverId': serverId,
        'address': address,
        'port': port,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pingServers(List<Map<String, dynamic>> servers) async {
    try {
      final result = await platform.invokeMethod('pingServers', {
        'servers': servers,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<PingResult?> getPingResult(String serverId) async {
    try {
      final result = await platform.invokeMethod('getPingResult', {
        'serverId': serverId,
      });
      if (result == null) return null;
      return PingResult.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      return null;
    }
  }

  Future<bool> clearPingResults() async {
    try {
      final result = await platform.invokeMethod('clearPingResults');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
