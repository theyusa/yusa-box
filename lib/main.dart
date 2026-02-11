import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YusaBox VPN',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VPNHomePage(),
    );
  }
}

class VPNHomePage extends StatefulWidget {
  const VPNHomePage({super.key});

  @override
  State<VPNHomePage> createState() => _VPNHomePageState();
}

class _VPNHomePageState extends State<VPNHomePage> {
  bool _isConnected = false;
  String _selectedServer = '🇺🇸 United States - New York';
  int _currentIndex = 0;
  String _selectedProtocol = 'WireGuard';

  final List<Map<String, dynamic>> _servers = [
    {'flag': '🇺🇸', 'name': 'United States', 'city': 'New York', 'ping': '24ms'},
    {'flag': '🇬🇧', 'name': 'United Kingdom', 'city': 'London', 'ping': '32ms'},
    {'flag': '🇩🇪', 'name': 'Germany', 'city': 'Frankfurt', 'ping': '28ms'},
    {'flag': '🇳🇱', 'name': 'Netherlands', 'city': 'Amsterdam', 'ping': '30ms'},
    {'flag': '🇯🇵', 'name': 'Japan', 'city': 'Tokyo', 'ping': '85ms'},
  ];

  final List<String> _protocols = ['WireGuard', 'OpenVPN', 'IKEv2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('YusaBox VPN'),
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildVPNView(),
          _buildSubscriptionView(),
          _buildSettingsView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.vpn_lock),
            label: 'VPN',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium),
            label: 'Subscription',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildVPNView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildConnectionCard(),
          const SizedBox(height: 30),
          _buildServerSelector(),
          const SizedBox(height: 20),
          _buildConnectionStats(),
          const SizedBox(height: 20),
          _buildProtocolSelector(),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.grey.shade800, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _isConnected ? Icons.shield_check_rounded : Icons.shield_outline_rounded,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            _isConnected ? 'Connected' : 'Not Connected',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedServer,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isConnected = !_isConnected;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _isConnected ? Colors.red : Colors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isConnected ? 'Disconnect' : 'Connect',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Server',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._servers.map((server) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    server['flag'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(server['name']),
                  subtitle: Text('${server['city']} • ${server['ping']}'),
                  trailing: _selectedServer.contains(server['name'])
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedServer = '${server['flag']} ${server['name']} - ${server['city']}';
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Download', _isConnected ? '12.5 MB/s' : '0 MB/s', Icons.download),
                _buildStatItem('Upload', _isConnected ? '5.2 MB/s' : '0 MB/s', Icons.upload),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Ping', _isConnected ? '24 ms' : '--', Icons.speed),
                _buildStatItem('Time', _isConnected ? '02:15:30' : '--:--:--', Icons.timer),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Protocol',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: _protocols
                  .map((protocol) => ButtonSegment(
                        value: protocol,
                        label: Text(protocol),
                      ))
                  .toList(),
              selected: {_selectedProtocol},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedProtocol = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Upgrade to premium for unlimited access',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 30),
          _buildPlanCard('Free', '0', '/month', [
            '5 servers',
            'Limited bandwidth',
            'Best effort speed',
            'No ads',
          ], false),
          const SizedBox(height: 16),
          _buildPlanCard('Premium', '9.99', '/month', [
            '100+ servers',
            'Unlimited bandwidth',
            'Max speed (10 Gbps)',
            'No ads',
            '24/7 support',
            '5 devices',
          ], true),
          const SizedBox(height: 16),
          _buildPlanCard('Family', '19.99', '/month', [
            'Everything in Premium',
            'Unlimited devices',
            'Family dashboard',
            'Priority support',
          ], false),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String plan,
    String price,
    String period,
    List<String> features,
    bool highlighted,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? Colors.blue.shade50 : Colors.white,
        border: Border.all(
          color: highlighted ? Colors.blue : Colors.grey.shade300,
          width: highlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: highlighted ? Colors.blue : Colors.black87,
                ),
              ),
              if (highlighted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$$price',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: highlighted ? Colors.blue : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                period,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: highlighted ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(feature),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: highlighted ? Colors.blue : Colors.grey.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(highlighted ? 'Get Premium' : 'Select Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingsSection('General', [
            _buildSettingsTile(
              Icons.language,
              'Language',
              'English',
              () {},
            ),
            _buildSettingsTile(
              Icons.dark_mode,
              'Dark Mode',
              'Off',
              () {},
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Connection', [
            _buildSettingsTile(
              Icons.vpn_lock,
              'Auto-connect on startup',
              'Off',
              () {},
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            _buildSettingsTile(
              Icons.network_check,
              'Kill Switch',
              'On',
              () {},
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Account', [
            _buildSettingsTile(
              Icons.email,
              'Email',
              'user@example.com',
              () {},
            ),
            _buildSettingsTile(
              Icons.password,
              'Change Password',
              '',
              () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('About', [
            _buildSettingsTile(
              Icons.info,
              'Version',
              '1.0.0',
              () {},
            ),
            _buildSettingsTile(
              Icons.description,
              'Privacy Policy',
              '',
              () {},
            ),
            _buildSettingsTile(
              Icons.article,
              'Terms of Service',
              '',
              () {},
            ),
          ]),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
      onTap: onTap,
    );
  }
}
