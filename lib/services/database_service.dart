import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/vpn_models.dart';

class DatabaseService {
  static const String _subscriptionsBoxName = 'subscriptions';
  static const String _serversBoxName = 'servers';
  static const String _settingsBoxName = 'settings';

  static late Box<dynamic> _subscriptionsBox;
  static late Box<dynamic> _serversBox;
  static late Box<dynamic> _settingsBox;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[Database] Already initialized, skipping');
      return;
    }

    debugPrint('[Database] Initializing Hive...');
    await Hive.initFlutter();
    _subscriptionsBox = await Hive.openBox<dynamic>(_subscriptionsBoxName);
    _serversBox = await Hive.openBox<dynamic>(_serversBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _isInitialized = true;
    debugPrint('[Database] Initialized successfully');
    debugPrint('[Database] Subscriptions box length: ${_subscriptionsBox.length}');
    debugPrint('[Database] Servers box length: ${_serversBox.length}');

    await _subscriptionsBox.flush();
    await _serversBox.flush();
    await _settingsBox.flush();
    debugPrint('[Database] All boxes flushed to disk');
  }

  // Subscriptions
  static Future<void> saveSubscriptions(List<VPNSubscription> subscriptions) async {
    debugPrint('[Database] Saving ${subscriptions.length} subscriptions...');
    await _subscriptionsBox.clear();
    for (var i = 0; i < subscriptions.length; i++) {
      await _subscriptionsBox.put(i.toString(), subscriptions[i].toJson());
    }
    debugPrint('[Database] Saved! Box length: ${_subscriptionsBox.length}');
    await _subscriptionsBox.flush();
    debugPrint('[Database] Flushed to disk');
  }

  static List<VPNSubscription> loadSubscriptions() {
    debugPrint('[Database] Loading subscriptions...');
    final subscriptions = <VPNSubscription>[];
    for (var i = 0; i < _subscriptionsBox.length; i++) {
      final data = _subscriptionsBox.get(i.toString());
      if (data != null) {
        subscriptions.add(VPNSubscription.fromJson(data as Map<String, dynamic>));
      }
    }
    debugPrint('[Database] Loaded ${subscriptions.length} subscriptions');
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
        servers.add(VPNServer.fromJson(data as Map<String, dynamic>));
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
