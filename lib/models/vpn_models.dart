
class VPNServer {
  final String id;
  String name;
  String address;
  int port;
  String flag;
  String city;
  String ping;
  String protocol; // vmess, vless, trojan vs.
  String? rawConfig;

  VPNServer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.flag,
    this.city = '',
    this.ping = '--',
    this.protocol = 'vless',
    this.rawConfig,
  });
}

class VPNSubscription {
  final String id;
  String name;
  String url;
  List<VPNServer> servers;

  VPNSubscription({
    required this.id,
    required this.name,
    required this.url,
    List<VPNServer>? servers,
  }) : servers = servers ?? [];

  // Helper to fetch servers from the URL
  Future<void> refreshServers() async {
    // This method will be implemented using SubscriptionService in the main logic or here if we import it.
    // However, to keep models clean, we might want to pass the service or move logic out.
    // For simplicity, let's keep the dummy logic here but commented out, 
    // and rely on the UI/Provider to call the service and update the list.
    // Or better, import the service here.
  }
}
