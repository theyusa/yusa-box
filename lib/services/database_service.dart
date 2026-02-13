import 'package:hive_flutter/hive_flutter.dart';
import '../models/vpn_models.dart';

class DatabaseService {
  static const String _subscriptionsBoxName = 'subscriptions';
  static const String _serversBoxName = 'servers';
  static const String _settingsBoxName = 'settings';

  static late Box<Map> _subscriptionsBox;
  static late Box<Map> _serversBox;
  static late Box<dynamic> _settingsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _subscriptionsBox = await Hive.openBox<Map>(_subscriptionsBoxName);
    _serversBox = await Hive.openBox<Map>(_serversBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  // Subscriptions
  static Future<void> saveSubscriptions(List<VPNSubscription> subscriptions) async {
    await _subscriptionsBox.clear();
    for (var i = 0; i < subscriptions.length; i++) {
      await _subscriptionsBox.put(i.toString(), subscriptions[i].toJson());
    }
  }

  static List<VPNSubscription> loadSubscriptions() {
    final subscriptions = <VPNSubscription>[];
    for (var i = 0; i < _subscriptionsBox.length; i++) {
      final data = _subscriptionsBox.get(i.toString());
      if (data != null) {
        subscriptions.add(VPNSubscription.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return subscriptions;
  }

  // Individual Server Operations
  static Future<void> saveServer(VPNServer server) async {
    await _serversBox.put(server.id, server.toJson());
  }

  static Future<void> deleteServer(String serverId) async {
    await _serversBox.delete(serverId);
  }

  static List<VPNServer> loadAllServers() {
    final servers = <VPNServer>[];
    for (final key in _serversBox.keys) {
      final data = _serversBox.get(key);
      if (data != null) {
        servers.add(VPNServer.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return servers;
  }

  // Settings
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static T? loadSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> clearAll() async {
    await _subscriptionsBox.clear();
    await _serversBox.clear();
    await _settingsBox.clear();
  }
}
