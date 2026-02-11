import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'strings.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;
  final language = prefs.getString('language') ?? AppStrings.tr;

  if (AppStrings.supportedLanguages.contains(language)) {
    AppStrings.setLanguage(language);
  }

  runApp(MyApp(
    isDarkMode: isDarkMode,
    language: language,
  ));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final String language;

  const MyApp({
    super.key,
    required this.isDarkMode,
    required this.language,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.get('app_title'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
  int _currentIndex = 0;
  bool _isDarkMode = false;
  String _currentLanguage = AppStrings.tr;

  final List<Map<String, dynamic>> _servers = [
    {'flag': '🇺🇸', 'name': 'United States', 'city': 'New York', 'ping': '24ms'},
    {'flag': '🇬🇧', 'name': 'United Kingdom', 'city': 'London', 'ping': '32ms'},
    {'flag': '🇩🇪', 'name': 'Germany', 'city': 'Frankfurt', 'ping': '28ms'},
    {'flag': '🇳🇱', 'name': 'Netherlands', 'city': 'Amsterdam', 'ping': '30ms'},
    {'flag': '🇯🇵', 'name': 'Japan', 'city': 'Tokyo', 'ping': '85ms'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _currentLanguage = prefs.getString('language') ?? AppStrings.tr;
      AppStrings.setLanguage(_currentLanguage);
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('language', _currentLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.get('app_title'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('app_title')),
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.vpn_lock),
              label: AppStrings.get('vpn'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.workspace_premium),
              label: AppStrings.get('subscription'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings),
              label: AppStrings.get('settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVPNView() {
    final selectedServer =
        _isConnected ? '${_servers[0]['flag']} ${_servers[0]['name']}' : AppStrings.get('not_connected');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildConnectionCard(selectedServer),
          const SizedBox(height: 30),
          _buildServerSelector(),
          const SizedBox(height: 20),
          _buildConnectionStats(),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(String selectedServer) {
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
            color: (_isConnected ? Colors.green : Colors.grey).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _isConnected ? Icons.security_rounded : Icons.security_outlined,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            _isConnected ? AppStrings.get('connected') : AppStrings.get('not_connected'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            selectedServer,
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
                _isConnected ? AppStrings.get('disconnect') : AppStrings.get('connect'),
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
            Text(
              AppStrings.get('select_server'),
              style: const TextStyle(
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
                  onTap: () {},
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
                _buildStatItem(
                    AppStrings.get('download'),
                    _isConnected ? '12.5 MB/s' : '0 MB/s',
                    Icons.download),
                _buildStatItem(AppStrings.get('upload'), _isConnected ? '5.2 MB/s' : '0 MB/s', Icons.upload),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(AppStrings.get('ping'), _isConnected ? '24 ms' : '--', Icons.speed),
                _buildStatItem(AppStrings.get('time'), _isConnected ? '02:15:30' : '--:--:--', Icons.timer),
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

  Widget _buildSubscriptionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('v2ray_subs'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddSubscriptionDialog(),
                icon: const Icon(Icons.add),
                label: Text(AppStrings.get('add_subscription')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._buildSubscriptionList(),
        ],
      ),
    );
  }

  List<Widget> _buildSubscriptionList() {
    final subscriptions = [
      {
        'name': 'My Subscription 1',
        'url': 'https://example.com/sub',
        'active': true,
        'profile_count': 12,
      },
      {
        'name': 'My Subscription 2',
        'url': 'https://example.com/sub2',
        'active': false,
        'profile_count': 5,
      },
    ];

    if (subscriptions.isEmpty) {
      return [
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(AppStrings.get('no_subscriptions'),
                  style: TextStyle(color: Colors.grey.shade600)),
              Text(AppStrings.get('add_first_subscription'),
                  style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        )
      ];
    }

    return subscriptions.map((sub) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: sub['active'] == true ? Colors.green : Colors.grey,
            child: const Icon(Icons.cloud, color: Colors.white),
          ),
          title: Text(sub['name'] as String),
          subtitle: Text('${sub['profile_count']} ${AppStrings.get('profile').toLowerCase()}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.speed),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showSubscriptionMenu(sub),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showAddSubscriptionDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.get('add_subscription'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppStrings.get('subscription_name'),
                prefixIcon: const Icon(Icons.bookmark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppStrings.get('subscription_url'),
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppStrings.get('save')),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionMenu(Map<String, dynamic> subscription) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                child: Text(
                  subscription['name'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Divider(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(AppStrings.get('edit')),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(AppStrings.get('test_connection')),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  AppStrings.get('delete'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(subscription);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(AppStrings.get('warning')),
        content: Text(AppStrings.get('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppStrings.get('delete')),
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
          _buildSettingsSection(AppStrings.get('general'), [
            _buildSettingsTile(
              Icons.language,
              AppStrings.get('language'),
              AppStrings.getLanguageName(_currentLanguage),
              () => _showLanguageDialog(),
              trailing: Text(AppStrings.getLanguageName(_currentLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            _buildSettingsTile(
              Icons.dark_mode,
              AppStrings.get('dark_mode'),
              _isDarkMode ? 'On' : 'Off',
              () {},
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  _savePreferences();
                },
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection(AppStrings.get('connection'), [
            _buildSettingsTile(
              Icons.vpn_lock,
              AppStrings.get('auto_connect'),
              'Off',
              () {},
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            _buildSettingsTile(
              Icons.network_check,
              AppStrings.get('kill_switch'),
              'On',
              () {},
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection(AppStrings.get('v2ray_config'), [
            _buildSettingsTile(
              Icons.dns,
              AppStrings.get('dns_servers'),
              '',
              () {},
            ),
            _buildSettingsTile(
              Icons.route,
              AppStrings.get('routing_rules'),
              '',
              () {},
            ),
            _buildSettingsTile(
              Icons.block,
              AppStrings.get('block_ads'),
              'Off',
              () {},
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection(AppStrings.get('singbox_config'), [
            _buildSettingsTile(
              Icons.speed,
              AppStrings.get('tcp_fast_open'),
              'On',
              () {},
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            _buildSettingsTile(
              Icons.call_merge,
              AppStrings.get('multiplex'),
              'Off',
              () {},
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            _buildSettingsTile(
              Icons.visibility,
              AppStrings.get('sniffing'),
              'On',
              () {},
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            _buildSettingsTile(
              Icons.swap_horiz,
              AppStrings.get('udp_relay'),
              'On',
              () {},
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            _buildSettingsTile(
              Icons.timer,
              AppStrings.get('connection_timeout'),
              '30s',
              () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection(AppStrings.get('about'), [
            _buildSettingsTile(
              Icons.info,
              AppStrings.get('version'),
              '1.0.1',
              () {},
            ),
            _buildSettingsTile(
              Icons.description,
              AppStrings.get('privacy_policy'),
              '',
              () {},
            ),
            _buildSettingsTile(
              Icons.article,
              AppStrings.get('terms_of_service'),
              '',
              () {},
            ),
          ]),
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              Icons.language_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(AppStrings.get('language')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppStrings.supportedLanguages.map((lang) {
            return ListTile(
              title: Text(AppStrings.getLanguageName(lang)),
              trailing: _currentLanguage == lang
                  ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                setState(() {
                  _currentLanguage = lang;
                  AppStrings.setLanguage(_currentLanguage);
                });
                _savePreferences();
                Navigator.pop(context);
              },
            );
          }),
        ),
      ),
    );
  }
}
