import 'package:flutter/material.dart';
import '../../services/vpn_service.dart';
import '../../models/vpn_config.dart';
import '../../models/vpn_status.dart';
import '../widgets/connect_button.dart';
import '../widgets/status_indicator.dart';
import '../widgets/speed_display.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VpnService _vpnService = VpnService();
  VpnStatus _currentStatus = VpnStatus(state: VpnState.disconnected);

  @override
  void initState() {
    super.initState();
    _listenToVpnStatus();
  }

  void _listenToVpnStatus() {
    _vpnService.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
      });
    });
  }

  Future<void> _toggleVpn() async {
    if (_currentStatus.isConnected) {
      await _vpnService.stopVpn();
    } else {
      final hasPermission = await _vpnService.requestVpnPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('VPN izni gerekli')),
        );
        return;
      }

      final config = VpnConfig(
        serverAddress: 'your-server.com',
        serverPort: 443,
        protocol: 'vless',
        uuid: 'your-uuid-here',
        tlsEnabled: true,
        sni: 'your-sni.com',
      );

      final success = await _vpnService.startVpn(config);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('VPN bağlantısı başarısız')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('VPN Bağlantısı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusIndicator(status: _currentStatus),
            SizedBox(height: 40),
            ConnectButton(
              isConnected: _currentStatus.isConnected,
              isConnecting: _currentStatus.isConnecting,
              onPressed: _toggleVpn,
            ),
            SizedBox(height: 40),
            if (_currentStatus.isConnected)
              SpeedDisplay(
                uploadSpeed: _currentStatus.uploadSpeed,
                downloadSpeed: _currentStatus.downloadSpeed,
                connectedTime: _currentStatus.connectedTime,
              ),
          ],
        ),
      ),
    );
  }
}
