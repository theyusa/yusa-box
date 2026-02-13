import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/vpn_models.dart';

class ServerService {
  static const String _serversBoxName = 'serversBox';
  static const String _subscriptionsBoxName = 'subscriptionsBox';
  static const String _modifiedServersBoxName = 'modifiedServersBox';
  
  static Box<VpnServer> get serversBox => Hive.box<VpnServer>(_serversBoxName);
  static Box<VPNSubscription> get subscriptionsBox => Hive.box<VPNSubscription>(_subscriptionsBoxName);
  static Box<String> get modifiedServersBox => Hive.box<String>(_modifiedServersBoxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VpnServerAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VPNSubscriptionAdapter());
    }

    await Hive.openBox<VpnServer>(_serversBoxName);
    await Hive.openBox<VPNSubscription>(_subscriptionsBoxName);
    await Hive.openBox<String>(_modifiedServersBoxName);
  }

  // --- Servers (Flat List) ---

  static ValueListenable<Box<VpnServer>> get serversListenable => serversBox.listenable();

  static List<VpnServer> getAllServers() => serversBox.values.toList();

  static Future<void> addServer(VpnServer server) async {
    await serversBox.add(server);
  }

  static Future<void> addServers(List<VpnServer> servers) async {
    await serversBox.addAll(servers);
  }

  static Future<void> updateServer(int index, VpnServer server) async {
    await serversBox.putAt(index, server);
  }

  static Future<void> deleteServer(int index) async {
    await serversBox.deleteAt(index);
  }

  static Future<void> clearServers() async {
    await serversBox.clear();
  }

  // --- Subscriptions ---

  static ValueListenable<Box<VPNSubscription>> get subscriptionsListenable => subscriptionsBox.listenable();
  
  static List<VPNSubscription> getAllSubscriptions() => subscriptionsBox.values.toList();

  static Future<void> addSubscription(VPNSubscription subscription) async {
    await subscriptionsBox.add(subscription);
  }
  
  static Future<void> updateSubscription(int index, VPNSubscription subscription) async {
    await subscriptionsBox.putAt(index, subscription);
  }

  static Future<void> deleteSubscription(int index) async {
    await subscriptionsBox.deleteAt(index);
  }

  // --- Modified Servers (User Edited) ---

  static Future<void> saveModifiedServer(VpnServer server) async {
    await modifiedServersBox.put(server.id, server.config);
  }

  static String? getModifiedServerConfig(String serverId) {
    return modifiedServersBox.get(serverId);
  }

  static List<String> getAllModifiedServerIds() {
    return modifiedServersBox.keys.toList().cast<String>();
  }

  static Future<void> removeModifiedServer(String serverId) async {
    await modifiedServersBox.delete(serverId);
  }

  static Future<void> clearModifiedServers() async {
    await modifiedServersBox.clear();
  }

  static bool isServerModified(String serverId) {
    return modifiedServersBox.containsKey(serverId);
  }

  static Future<void> applyModificationsToServers(List<VpnServer> servers) async {
    for (final server in servers) {
      if (modifiedServersBox.containsKey(server.id)) {
        server.config = modifiedServersBox.get(server.id)!;
      }
    }
  }
}
