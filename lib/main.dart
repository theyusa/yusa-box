import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'strings.dart';
import 'providers/theme_provider.dart';
import 'models/vpn_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final language = prefs.getString('language') ?? AppStrings.tr;

  if (AppStrings.supportedLanguages.contains(language)) {
    AppStrings.setLanguage(language);
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeMode = themeState.themeMode.toThemeMode();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        final useDynamicColor = themeState.isDynamicColorEnabled &&
            lightDynamic != null &&
            darkDynamic != null;

        if (useDynamicColor) {
          final lightHarmonized = lightDynamic.harmonized();
          final darkHarmonized = darkDynamic.harmonized();

          lightScheme = ColorScheme.fromSeed(
            seedColor: lightHarmonized.primary,
            brightness: Brightness.light,
            contrastLevel: themeState.contrastLevel,
          );

          darkScheme = ColorScheme.fromSeed(
            seedColor: darkHarmonized.primary,
            brightness: Brightness.dark,
            contrastLevel: themeState.contrastLevel,
          );
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.light,
            contrastLevel: themeState.contrastLevel,
          );

          darkScheme = ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.dark,
            contrastLevel: themeState.contrastLevel,
          );
        }

        final darkSchemeModified = _applyTrueBlackIfEnabled(
          darkScheme,
          themeState.isTrueBlackEnabled,
        );

        return MaterialApp(
          title: AppStrings.get('app_title'),
          theme: _buildLightTheme(lightScheme),
          darkTheme: _buildDarkTheme(darkSchemeModified),
          themeMode: themeMode,
          home: const VPNHomePage(),
        );
      },
    );
  }
}

ThemeData _buildLightTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
    ),
  );
}

ThemeData _buildDarkTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
    ),
  );
}

ColorScheme _applyTrueBlackIfEnabled(
  ColorScheme darkScheme,
  bool isEnabled,
) {
  if (!isEnabled) {
    return darkScheme;
  }

  const black = Color(0xFF000000);
  const darkGray = Color(0xFF0A0A0A);
  const lightGray = Color(0xFF141414);

  return darkScheme.copyWith(
    surface: black,
    surfaceContainer: darkGray,
    surfaceContainerLow: darkGray,
    surfaceContainerLowest: black,
    surfaceContainerHigh: lightGray,
    surfaceContainerHighest: lightGray,
  );
}

class VPNHomePage extends ConsumerStatefulWidget {
  const VPNHomePage({super.key});

  @override
  ConsumerState<VPNHomePage> createState() => _VPNHomePageState();
}

class _VPNHomePageState extends ConsumerState<VPNHomePage> {
  bool _isConnected = false;
  int _currentIndex = 0;
  String _currentLanguage = AppStrings.tr;
  
  // State: Dynamic Data
  List<VPNSubscription> _subscriptions = [];
  VPNServer? _selectedServer; // Selected Server Object

  final Set<String> _expandedSections = {};

  static const List<Color> _seedColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple, Colors.indigo,
    Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green,
    Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange,
    Colors.deepOrange, Colors.brown, Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadDummyData();
  }

  void _loadDummyData() {
    // Initial Dummy Subscription
    final initialSub = VPNSubscription(
      id: 'sub1',
      name: 'Varsayılan Abonelik',
      url: 'https://example.com/sub/vless',
    );
    initialSub.refreshServers(); // Load initial dummy servers
    setState(() {
      _subscriptions = [initialSub];
      if (initialSub.servers.isNotEmpty) {
        _selectedServer = initialSub.servers.first;
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? AppStrings.tr;

    if (mounted) {
      setState(() {
        _currentLanguage = language;
        AppStrings.setLanguage(language);
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
  }

  void _toggleSection(String section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('app_title')),
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildVPNView(),
          _buildServerView(), // Now dynamically linked
          _buildSubscriptionView(), // Now manages the data
          _buildSettingsView(themeState),
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
            icon: const Icon(Icons.dns),
            label: 'Server',
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
    );
  }

  // --- VPN View ---

  Widget _buildVPNView() {
    final selectedServerName = _selectedServer != null 
        ? '${_selectedServer!.flag} ${_selectedServer!.name}' 
        : AppStrings.get('not_connected');
    
    final displayServer = _isConnected ? selectedServerName : AppStrings.get('not_connected');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildConnectionCard(displayServer),
          const SizedBox(height: 30),
          _buildConnectionStats(),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(String serverName) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [colorScheme.primary.withValues(alpha: 0.9), colorScheme.primary]
              : [colorScheme.primary.withValues(alpha: 0.7), colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
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
            color: colorScheme.onPrimary,
          ),
          const SizedBox(height: 20),
          Text(
            _isConnected ? AppStrings.get('connected') : AppStrings.get('not_connected'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            serverName,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedServer == null && !_isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen önce bir server seçin!')),
                  );
                  return;
                }
                setState(() {
                  _isConnected = !_isConnected;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
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

  Widget _buildConnectionStats() {
    // ... (Keep existing stats logic)
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(AppStrings.get('download'),
                    _isConnected ? '12.5 MB/s' : '0 MB/s', Icons.download),
                _buildStatItem(
                    AppStrings.get('upload'), _isConnected ? '5.2 MB/s' : '0 MB/s', Icons.upload),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(AppStrings.get('ping'), _isConnected ? (_selectedServer?.ping ?? '--') : '--', Icons.speed),
                _buildStatItem(AppStrings.get('time'), _isConnected ? '02:15:30' : '--:--:--', Icons.timer),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  // --- Server View (Dynamic) ---

  Widget _buildServerView() {
    final colorScheme = Theme.of(context).colorScheme;

    // Flatten logic: List all servers from all subscriptions
    // Alternatively, group by subscription. Grouping is better for context.
    
    if (_subscriptions.isEmpty) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns_outlined, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Server bulunamadı.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentIndex = 2); // Go to Subscription tab
              },
              child: const Text('Abonelik Ekle'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Server Listesi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {}, // Maybe sort or filter later
                icon: const Icon(Icons.sort),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: _subscriptions.length,
            itemBuilder: (context, subIndex) {
              final sub = _subscriptions[subIndex];
              if (sub.servers.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      sub.name,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...sub.servers.map((server) {
                    final isSelected = _selectedServer?.id == server.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(server.flag, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        title: Text(
                          server.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${server.city} • ${server.ping}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        tileColor: isSelected 
                            ? colorScheme.primaryContainer.withValues(alpha: 0.3) 
                            : colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() {
                            _selectedServer = server;
                          });
                        },
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showServerEditDialog(sub, server);
                            } else if (value == 'delete') {
                              _deleteServer(sub, server);
                            } else if (value == 'copy') {
                              // Copy logic (URL to clipboard)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Server URL kopyalandı')),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Düzenle')],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'copy',
                              child: Row(
                                children: [Icon(Icons.content_copy, size: 20), SizedBox(width: 8), Text('Kopyala')],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Sil', style: TextStyle(color: Colors.red))],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Subscription View ---

  Widget _buildSubscriptionView() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('v2ray_subs'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _showSubscriptionDialog(null),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_subscriptions.isEmpty)
             Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('no_subscriptions'),
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ..._subscriptions.map((sub) => _buildSubscriptionCard(sub)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(VPNSubscription sub) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Icon(Icons.cloud, color: colorScheme.onPrimary),
              ),
              title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${sub.servers.length} ${AppStrings.get('profile').toLowerCase()} • ${sub.url}', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Quick Actions: Update, Ping
                IconButton(
                  tooltip: 'Yenile',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Refresh logic
                    setState(() {
                      sub.refreshServers();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${sub.name} güncellendi')),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Test Et',
                  icon: const Icon(Icons.network_check), // Ping/Test icon
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ping testi başlatıldı...')),
                    );
                  },
                ),
                // More Actions: Edit, Delete
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showSubscriptionDialog(sub);
                    } else if (value == 'delete') {
                      _showDeleteSubscriptionDialog(sub);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Düzenle')],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Sil', style: TextStyle(color: Colors.red))],
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showSubscriptionDialog(VPNSubscription? sub) {
    final isEditing = sub != null;
    final nameController = TextEditingController(text: isEditing ? sub.name : '');
    final urlController = TextEditingController(text: isEditing ? sub.url : '');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit : Icons.add_circle_outline, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(isEditing ? AppStrings.get('edit') : AppStrings.get('add_subscription'), style: TextStyle(color: colorScheme.onSurface)),
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
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppStrings.get('subscription_url'),
                prefixIcon: const Icon(Icons.link),
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
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              if (name.isNotEmpty && url.isNotEmpty) {
                setState(() {
                  if (isEditing) {
                    sub.name = name;
                    sub.url = url;
                  } else {
                    final newSub = VPNSubscription(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      url: url,
                    );
                    newSub.refreshServers(); // Load initial dummy servers
                    _subscriptions.add(newSub);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(AppStrings.get('save')),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubscriptionDialog(VPNSubscription sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('warning')),
        content: const Text('Bu aboneliği ve tüm serverlarını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _subscriptions.remove(sub);
                // If the selected server belonged to this sub, clear selection
                if (_selectedServer != null && sub.servers.any((s) => s.id == _selectedServer!.id)) {
                  _selectedServer = null;
                  _isConnected = false; // Disconnect safely
                }
              });
              Navigator.pop(context);
            },
            child: Text(AppStrings.get('delete')),
          ),
        ],
      ),
    );
  }

  void _showServerEditDialog(VPNSubscription sub, VPNServer server) {
    final nameController = TextEditingController(text: server.name);
    final addressController = TextEditingController(text: server.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Server Adı', prefixIcon: Icon(Icons.dns)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Adres', prefixIcon: Icon(Icons.language)),
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
              setState(() {
                server.name = nameController.text;
                server.address = addressController.text;
              });
              Navigator.pop(context);
            },
            child: Text(AppStrings.get('save')),
          ),
        ],
      ),
    );
  }

  void _deleteServer(VPNSubscription sub, VPNServer server) {
     setState(() {
      sub.servers.remove(server);
      if (_selectedServer?.id == server.id) {
        _selectedServer = null;
        _isConnected = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server silindi')),
    );
  }

  // --- Settings View ---

  Widget _buildSettingsView(ThemeState themeState) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingsSection('Kişiselleştirme', [
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
              'Tema Modu',
              themeState.themeMode.displayName,
              () => _showThemeModeDialog(),
              trailing: Icon(
                _getThemeModeIcon(themeState.themeMode),
                color: colorScheme.onSurface,
              ),
            ),
            _buildSettingsTile(
              Icons.palette,
              'Dinamik Renk',
              themeState.isDynamicColorEnabled ? 'Açık' : 'Kapalı',
              () => ref.read(themeProvider.notifier).toggleDynamicColor(),
              trailing: Switch(
                value: themeState.isDynamicColorEnabled,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleDynamicColor(),
                ),
              ),
            if (!themeState.isDynamicColorEnabled)
              _buildSettingsTile(
                Icons.color_lens,
                'Tohum Rengi',
                '',
                () => _showSeedColorDialog(themeState),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeState.seedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            _buildSettingsTile(
              Icons.contrast,
              'True Black (OLED)',
              themeState.isTrueBlackEnabled ? 'Açık' : 'Kapalı',
              () => ref.read(themeProvider.notifier).toggleTrueBlack(),
              trailing: Switch(
                value: themeState.isTrueBlackEnabled,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTrueBlack(),
                ),
              ),
            _buildSettingsTile(
              Icons.accessibility,
              'Yüksek Kontrast',
              themeState.contrastLevel > 0 ? 'Açık' : 'Kapalı',
              () => ref.read(themeProvider.notifier).toggleContrastMode(),
              trailing: Switch(
                value: themeState.contrastLevel > 0,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleContrastMode(),
                ),
              ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('VPN Ayarları', [
            _buildSettingsTile(
              Icons.vpn_lock,
              AppStrings.get('auto_connect'),
              'Kapalı',
              () {},
              trailing: Switch(value: false, onChanged: (_) {}),
            ),
            _buildSettingsTile(
              Icons.network_check,
              AppStrings.get('kill_switch'),
              'Açık',
              () {},
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            _buildSettingsTile(
              Icons.speed,
              'Kill Switch Bekleme Süresi',
              '5s',
              () {},
            ),
            _buildSettingsTile(
              Icons.settings_suggest,
              'MTU Ayarı',
              '1400',
              () {},
            ),
            _buildSettingsTile(
              Icons.public,
              'Proxy Modu',
              'Tüm Trafik',
              () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('V2Ray Ayarları', [
            _buildSettingsTile(
              Icons.route,
              'Yönlendirme Modu',
              'Tüm Trafik',
              () {},
            ),
            _buildSettingsTile(
              Icons.dns,
              'DNS Ayarları',
              'Özel',
              () {},
            ),
            _buildSettingsTile(
              Icons.security,
              'TLS Ayarları',
              'Otomatik',
              () {},
            ),
            _buildSettingsTile(
              Icons.bolt,
              'TCP Fast Open',
              'Kapalı',
              () {},
              trailing: Switch(value: false, onChanged: (_) {}),
            ),
            _buildSettingsTile(
              Icons.speed,
              'Mux Ayarı',
              'Kapalı',
              () {},
              trailing: Switch(value: false, onChanged: (_) {}),
            ),
            _buildSettingsTile(
              Icons.format_list_numbered,
              'Sniffing',
              'Açık',
              () {},
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('SingBox Ayarları', [
            _buildSettingsTile(
              Icons.route,
              'Yönlendirme Modu',
              'Tüm Trafik',
              () {},
            ),
            _buildSettingsTile(
              Icons.dns,
              'DNS Modu',
              'Özel',
              () {},
            ),
            _buildSettingsTile(
              Icons.security,
              'Tun Modu',
              'Açık',
              () {},
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            _buildSettingsTile(
              Icons.speed,
              'MTU Ayarı',
              '1400',
              () {},
            ),
            _buildSettingsTile(
              Icons.stacked_line_chart,
              'Bypass LAN',
              'Açık',
              () {},
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            _buildSettingsTile(
              Icons.wifi_tethering,
              'Hotspot Paylaşımı',
              'Kapalı',
              () {},
              trailing: Switch(value: false, onChanged: (_) {}),
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
              Icons.code,
              'GitHub',
              'github.com',
              () {},
            ),
          ]),
        ],
      ),
    );
  }

  IconData _getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  void _showThemeModeDialog() {
    final themeState = ref.read(themeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tema Modu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return ListTile(
                  title: Text(mode.displayName),
                  leading: Icon(_getThemeModeIcon(mode)),
                  trailing: themeState.themeMode == mode
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(context);
                  },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSeedColorDialog(ThemeState themeState) {
    final selectedColor = themeState.seedColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tohum Rengi Seç'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _seedColors.length,
            itemBuilder: (context, index) {
              final color = _seedColors[index];
              return GestureDetector(
                onTap: () {
                  ref.read(themeProvider.notifier).setSeedColor(color);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.language_outlined, color: Theme.of(context).colorScheme.primary),
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
                  AppStrings.setLanguage(lang);
                });
                _savePreferences();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    final isExpanded = _expandedSections.contains(title);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(title),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                        child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                  ),
                  Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: colorScheme.onSurfaceVariant,
                          ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
        tileColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
