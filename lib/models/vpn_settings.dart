import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class VpnSettings {
  // DNS Settings
  List<DnsServer> dnsServers;
  String primaryDnsTag;
  bool independentCache;
  DnsStrategy dnsStrategy;
  
  // Route Settings
  RouteMode routeMode;
  bool autoDetectInterface;
  
  // Tun Settings
  List<String> tunInetAddress;
  int mtu;
  TunStack stack;
  bool sniff;
  bool sniffOverrideDestination;
  bool endpointIndependentNat;
  
  // Inbound Settings
  int mixedPort;
  String mixedListen;
  
  // Experimental
  bool enableClashApi;
  String clashController;
  String clashUi;
  
  VpnSettings({
    List<DnsServer>? dnsServers,
    this.primaryDnsTag = 'dns-remote',
    this.independentCache = true,
    this.dnsStrategy = DnsStrategy.preferIpV4,
    this.routeMode = RouteMode.proxy,
    this.autoDetectInterface = true,
    this.tunInetAddress = const ['172.19.0.1/28'],
    this.mtu = 9000,
    this.stack = TunStack.gvisor,
    this.sniff = true,
    this.sniffOverrideDestination = false,
    this.endpointIndependentNat = true,
    this.mixedPort = 2080,
    this.mixedListen = '127.0.0.1',
    this.enableClashApi = false,
    this.clashController = '127.0.0.1:9090',
    this.clashUi = '',
  }) : dnsServers = dnsServers ?? _defaultDnsServers;

  static final List<DnsServer> _defaultDnsServers = [
    DnsServer(tag: 'dns-block', address: 'rcode://success'),
    DnsServer(tag: 'dns-local', address: 'local', detour: 'direct'),
    DnsServer(
      tag: 'dns-direct',
      address: 'https://1.1.1.1/dns-query',
      addressResolver: 'dns-local',
      detour: 'direct',
      strategy: 'preferIpV4',
    ),
    DnsServer(
      tag: 'dns-remote',
      address: 'https://1.1.1.1/dns-query',
      addressResolver: 'dns-direct',
      strategy: 'preferIpV4',
    ),
  ];

  Map<String, dynamic> toJson() {
    return {
      'dnsServers': dnsServers.map((d) => d.toJson()).toList(),
      'primaryDnsTag': primaryDnsTag,
      'independentCache': independentCache,
      'dnsStrategy': dnsStrategy.name,
      'routeMode': routeMode.name,
      'autoDetectInterface': autoDetectInterface,
      'tunInetAddress': tunInetAddress,
      'mtu': mtu,
      'stack': stack.name,
      'sniff': sniff,
      'sniffOverrideDestination': sniffOverrideDestination,
      'endpointIndependentNat': endpointIndependentNat,
      'mixedPort': mixedPort,
      'mixedListen': mixedListen,
      'enableClashApi': enableClashApi,
      'clashController': clashController,
      'clashUi': clashUi,
    };
  }

  factory VpnSettings.fromJson(Map<String, dynamic> json) {
    return VpnSettings(
      dnsServers: (json['dnsServers'] as List?)
          ?.map((d) => DnsServer.fromJson(d))
          .toList() ?? _defaultDnsServers,
      primaryDnsTag: json['primaryDnsTag'] ?? 'dns-remote',
      independentCache: json['independentCache'] ?? true,
      dnsStrategy: DnsStrategy.values.firstWhere(
        (e) => e.name == json['dnsStrategy'],
        orElse: () => DnsStrategy.ipv4Only,
      ),
      routeMode: RouteMode.values.firstWhere(
        (e) => e.name == json['routeMode'],
        orElse: () => RouteMode.proxy,
      ),
      autoDetectInterface: json['autoDetectInterface'] ?? true,
      tunInetAddress: json['tunInetAddress'] != null
          ? List<String>.from(json['tunInetAddress'])
          : const ['172.19.0.1/28'],
      mtu: json['mtu'] ?? 9000,
      stack: TunStack.values.firstWhere(
        (e) => e.name == json['stack'],
        orElse: () => TunStack.gvisor,
      ),
      sniff: json['sniff'] ?? true,
      sniffOverrideDestination: json['sniffOverrideDestination'] ?? false,
      endpointIndependentNat: json['endpointIndependentNat'] ?? true,
      mixedPort: json['mixedPort'] ?? 2080,
      mixedListen: json['mixedListen'] ?? '127.0.0.1',
      enableClashApi: json['enableClashApi'] ?? false,
      clashController: json['clashController'] ?? '127.0.0.1:9090',
      clashUi: json['clashUi'] ?? '',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vpn_settings', jsonEncode(toJson()));
  }

  static Future<VpnSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('vpn_settings');
    
    if (jsonStr != null) {
      try {
        return VpnSettings.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        return VpnSettings();
      }
    }
    
    return VpnSettings();
  }

  Map<String, dynamic> buildSingboxDnsConfig() {
    return {
      'final': primaryDnsTag,
      'independent_cache': independentCache,
      'servers': dnsServers.map((d) => d.toSingboxFormat()).toList(),
    };
  }

  Map<String, dynamic> buildSingboxInboundConfig() {
    return {
      'type': 'tun',
      'tag': 'tun-in',
      'domain_strategy': '',
      'endpoint_independent_nat': endpointIndependentNat,
      'inet4_address': tunInetAddress,
      'mtu': mtu,
      'sniff': sniff,
      'sniff_override_destination': sniffOverrideDestination,
      'stack': stack.name,
    };
  }

  Map<String, dynamic> buildSingboxMixedInboundConfig() {
    return {
      'type': 'mixed',
      'tag': 'mixed-in',
      'domain_strategy': '',
      'listen': mixedListen,
      'listen_port': mixedPort,
      'sniff': sniff,
      'sniff_override_destination': sniffOverrideDestination,
    };
  }

  Map<String, dynamic> buildSingboxRouteConfig() {
    return {
      'auto_detect_interface': autoDetectInterface,
      'rule_set': [],
      'rules': [
        {'action': 'hijack-dns', 'port': [53]},
        {'action': 'hijack-dns', 'protocol': ['dns']},
        {'ip_is_private': true, 'outbound': 'bypass'},
        {
          'action': 'reject',
          'ip_cidr': ['224.0.0.0/3', 'ff00::/8'],
          'source_ip_cidr': ['224.0.0.0/3', 'ff00::/8'],
        },
      ],
    };
  }

  Map<String, dynamic> buildSingboxExperimentalConfig() {
    if (!enableClashApi) return {};
    
    return {
      'clash_api': {
        'external_controller': clashController,
        if (clashUi.isNotEmpty) 'external_ui': clashUi,
      },
    };
  }
}

class DnsServer {
  final String tag;
  final String address;
  final String? detour;
  final String? addressResolver;
  final String? strategy;
  
  DnsServer({
    required this.tag,
    required this.address,
    this.detour,
    this.addressResolver,
    this.strategy,
  });
  
  Map<String, dynamic> toJson() {
    final map = {
      'tag': tag,
      'address': address,
    };
    if (detour != null) map['detour'] = detour!;
    if (addressResolver != null) map['address_resolver'] = addressResolver!;
    if (strategy != null) map['strategy'] = strategy!;
    return map;
  }
  
  factory DnsServer.fromJson(Map<String, dynamic> json) {
    return DnsServer(
      tag: json['tag'],
      address: json['address'],
      detour: json['detour'],
      addressResolver: json['address_resolver'],
      strategy: json['strategy'],
    );
  }
  
  Map<String, dynamic> toSingboxFormat() {
    final map = {
      'tag': tag,
      'address': address,
    };
    if (detour != null) map['detour'] = detour!;
    if (addressResolver != null) map['address_resolver'] = addressResolver!;
    if (strategy != null) map['strategy'] = strategy!;
    return map;
  }
}

enum DnsStrategy {
  preferIpV4,
  preferIpV6,
  ipv4Only,
  ipv6Only;
}

enum TunStack {
  system,
  gvisor,
  mixed;
}

enum RouteMode {
  proxy,
  direct,
  bypass,
  block;
  
  String get singboxValue {
    switch (this) {
      case RouteMode.proxy:
        return 'proxy';
      case RouteMode.direct:
        return 'direct';
      case RouteMode.bypass:
        return 'bypass';
      case RouteMode.block:
        return 'block';
    }
  }
}


