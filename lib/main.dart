import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'strings.dart';
import 'providers/theme_provider.dart';
import 'models/vpn_models.dart';
import 'models/vpn_settings.dart';
import 'services/vpn_service.dart';
import 'services/subscription_service.dart';
import 'services/server_service.dart';
import 'services/speed_test_service.dart';
import 'services/ping_service.dart';

enum SortOption { name, ping }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServerService.init();

  final prefs = await SharedPreferences.getInstance();

  final language = prefs.getString('language') ?? AppStrings.tr;

  if (AppStrings.supportedLanguages.contains(language)) {
    AppStrings.setLanguage(language);
  }

  runApp(const ProviderScope(child: MyApp()));
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

        final useDynamicColor =
            themeState.isDynamicColorEnabled &&
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
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
  );
}

ColorScheme _applyTrueBlackIfEnabled(ColorScheme darkScheme, bool isEnabled) {
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
  final _vpnService = VpnService();
  final _subscriptionService = SubscriptionService();

  bool _isConnected = false;
  bool _isConnecting = false;
  int _currentIndex = 0;
  String _currentLanguage = AppStrings.tr;
  VpnSettings _vpnSettings = VpnSettings();

  // State: Dynamic Data
  List<VPNSubscription> _subscriptions = [];
  VpnServer? _selectedServer;

  // State: Filter and Sort
  String? _selectedSubId;
  SortOption _currentSort = SortOption.name;

  // State: VPN Session
  DateTime? _connectionStartTime;
  String _currentIp = '---.---.---.---';

  // State: Speed Test
  bool _isSpeedTestRunning = false;
  SpeedTestResult? _speedTestResult;

  // State: Ping
  final Map<String, PingResult> _pingResults = {};

  // State: Loading
  bool _isSubscriptionSaving = false;

  // Logs
  final List<String> _logs = [
    '[INFO] App started',
    '[INFO] SingBox service initialized',
  ];
  final ScrollController _logScrollController = ScrollController();
  bool _autoScrollLogs = true;
  String _logFilter = 'All';

  static const List<Color> _seedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadVpnSettings();
    _loadSubscriptions();
    _listenToVpnStatus();
    _listenToSpeedTestStatus();
    _listenToPingStatus();
    _pingServersOnLoad();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _listenToVpnStatus() {
    _vpnService.statusStream.listen((status) {
      final state = status['state'] as int? ?? 0;
      final message = status['message'] as String?;
      final log = status['log'] as String?;

      if (mounted) {
        setState(() {
          if (state == 1) {
            _isConnecting = true;
            _isConnected = false;
          } else if (state == 2) {
            _isConnecting = false;
            _isConnected = true;
            _connectionStartTime = DateTime.now();
            _addLog('VPN Bağlandı');
            _fetchCurrentIp();
          } else if (state == 4) {
            _isConnecting = false;
            _isConnected = false;
            _addLog('VPN Hatası: $message');
            _connectionStartTime = null;
          } else if (state == 3) {
            _isConnecting = false;
            _isConnected = false;
            _addLog('Bağlantı kesildi');
            _connectionStartTime = null;
          }
        });

        if (log != null) {
          _logs.insert(0, log);
          if (_logs.length > 100) {
            _logs.removeLast();
          }
          setState(() {});
        }
      }
    });
  }

  void _listenToSpeedTestStatus() {
    SpeedTestService().statusStream.listen((status) {
      final serverName = status['serverName'] as String? ?? '';
      final downloadSpeed =
          (status['downloadSpeed'] as num?)?.toDouble() ?? 0.0;
      final uploadSpeed = (status['uploadSpeed'] as num?)?.toDouble() ?? 0.0;
      final ping = status['ping'] as int? ?? 0;
      final complete = status['complete'] as bool? ?? false;

      if (mounted) {
        setState(() {
          if (complete) {
            _speedTestResult = SpeedTestResult(
              uploadSpeed: uploadSpeed,
              downloadSpeed: downloadSpeed,
              ping: ping,
              serverName: serverName,
            );
            _isSpeedTestRunning = false;
            _addLog(
              'Speed test tamamlandı: ${_speedTestResult!.downloadSpeedFormatted} ↓ / ${_speedTestResult!.uploadSpeedFormatted} ↑ (Ping: ${ping}ms)',
            );
          }
        });
      }
    });
  }

  void _listenToPingStatus() {
    PingService().pingStream.listen((pingResult) {
      final serverId = pingResult.serverId;

      if (mounted) {
        setState(() {
          _pingResults[serverId] = pingResult;
        });
      }
    });
  }

  Future<void> _pingServersOnLoad() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final box = ServerService.serversBox;
    final servers = box.values.toList();

    final serversToPing = servers.take(10).map((server) {
      return {'id': server.id, 'address': server.address, 'port': server.port};
    }).toList();

    if (serversToPing.isNotEmpty) {
      PingService().pingServers(serversToPing);
    }
  }

  Future<void> _pingSingleServer(VpnServer server) async {
    await PingService().pingServer(server.id, server.address, server.port);
  }

  Future<void> _pingFilteredServers() async {
    final box = ServerService.serversBox;
    final allServers = box.values.toList();

    List<VpnServer> filteredServers = [];
    if (_selectedSubId == null) {
      filteredServers = allServers;
    } else {
      final targetSub = _subscriptions.firstWhere(
        (s) => s.id == _selectedSubId,
        orElse: () => _subscriptions.first,
      );
      filteredServers = targetSub.servers;
    }

    final serversToPing = filteredServers.take(20).map((server) {
      return {'id': server.id, 'address': server.address, 'port': server.port};
    }).toList();

    if (serversToPing.isNotEmpty) {
      await PingService().pingServers(serversToPing);
    }
  }

  Future<void> _fetchCurrentIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ip = data['ip'] as String?;
        if (ip != null && mounted) {
          setState(() => _currentIp = ip);
          _addLog('IP: $ip');
        }
      }
    } catch (e) {
      _addLog('IP alınamadı: ${e.toString()}');
    }
  }

  Future<void> _loadSubscriptions() async {
    _subscriptions = ServerService.getAllSubscriptions();
    setState(() {});
  }

  Future<void> _deleteSubscription(VPNSubscription sub) async {
    final box = ServerService.subscriptionsBox;
    final index = box.values.toList().indexWhere((s) => s.id == sub.id);
    if (index != -1) {
      await ServerService.deleteSubscription(index);
      await _loadSubscriptions();
      await ServerService.clearServers();

      final subscriptions = ServerService.getAllSubscriptions();
      for (final remainingSub in subscriptions) {
        await ServerService.addServers(remainingSub.servers);
      }

      _addLog('Abonelik silindi: ${sub.name}');
    }
  }

  Future<void> _refreshSubscription(VPNSubscription sub) async {
    _addLog('Abonelik yenileniyor: ${sub.name}');
    try {
      final servers = await _subscriptionService.fetchServersFromSubscription(
        sub.url,
      );

      final box = ServerService.subscriptionsBox;
      final subscriptions = box.values.toList();
      final index = subscriptions.indexWhere((s) => s.id == sub.id);

      final updatedSub = VPNSubscription(
        id: sub.id,
        name: sub.name,
        url: sub.url,
        servers: servers,
      );

      if (index != -1) {
        await box.putAt(index, updatedSub);
      } else {
        await box.add(updatedSub);
      }

      await ServerService.clearServers();
      for (final s in ServerService.getAllSubscriptions()) {
        await ServerService.addServers(s.servers);
      }

      await _loadSubscriptions();
      _addLog('${sub.name}: ${servers.length} server güncellendi');
    } catch (e) {
      _addLog('Hata: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    }
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

  Future<void> _loadVpnSettings() async {
    final settings = await VpnSettings.load();
    if (mounted) {
      setState(() => _vpnSettings = settings);
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
  }

  void _addLog(String message) {
    final logMessage = '[INFO] $message';
    setState(() {
      _logs.insert(
        0,
        '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $logMessage',
      );
      if (_autoScrollLogs) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  Widget _buildVPNView() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isConnected
                            ? 'Güvenli Bağlantı Aktif'
                            : 'Bağlantı Yok',
                        style: TextStyle(
                          color: _isConnected
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    onPressed: _showLogPanel,
                    icon: const Icon(Icons.history_edu),
                    tooltip: 'Loglar',
                  ),
                  if (_isConnected)
                    IconButton.filledTonal(
                      onPressed: () async {
                        _addLog('Yeniden bağlanıyor...');
                        await _vpnService.reconnect();
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yeniden Bağlan',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDashboardGrid(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSessionStat(
                      'Oturum Süresi',
                      _isConnected ? _getSessionDuration() : '--:--',
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    _buildSessionStat(
                      'Veri Kullanımı',
                      _isConnected ? 'Hesaplanıyor...' : '--',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () async {
              if (_selectedServer == null && !_isConnected) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen önce bir server seçin!'),
                  ),
                );
                return;
              }

              if (_isConnected) {
                await _vpnService.stopVpn();
                _addLog('Bağlantı kesildi');
              } else {
                if (!mounted) return;
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                setState(() {
                  _isConnecting = true;
                });

                // VPN işlemini arka planda çalıştır
                Future.microtask(() async {
                  try {
                    final hasPermission = await _vpnService
                        .requestVpnPermission();
                    if (!hasPermission) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('VPN izni gerekli')),
                        );
                      }
                      if (mounted) {
                        setState(() {
                          _isConnecting = false;
                        });
                      }
                      return;
                    }

                    if (_selectedServer != null) {
                      final serverName =
                          '${_selectedServer!.flag} ${_selectedServer!.name}';
                      final config = _generateSingboxConfig(_selectedServer!);
                      _addLog('Bağlanıyor: $serverName');

                      try {
                        final success = await _vpnService
                            .startVpn(config, serverName: serverName)
                            .timeout(
                              const Duration(seconds: 30),
                              onTimeout: () {
                                if (mounted) {
                                  setState(() {
                                    _isConnecting = false;
                                  });
                                }
                                throw Exception('Bağlantı timeout oldu');
                              },
                            );

                        if (mounted) {
                          setState(() {
                            _isConnecting = false;
                          });
                        }

                        if (!success && mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('VPN bağlantısı başarısız'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isConnecting = false;
                          });
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Hata: ${e.toString()}')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        setState(() {
                          _isConnecting = false;
                        });
                      }
                    }
                  } catch (e) {
                    debugPrint('VPN bağlantı hatası: $e');
                    if (mounted) {
                      setState(() {
                        _isConnecting = false;
                      });
                    }
                  }
                });
              }
            },
            backgroundColor: _isConnected
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            foregroundColor: _isConnected
                ? Theme.of(context).colorScheme.onError
                : Theme.of(context).colorScheme.onPrimary,
            elevation: 4,
            child: Icon(_isConnected ? Icons.power_settings_new : Icons.bolt),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getSessionDuration() {
    if (_connectionStartTime == null) return '--:--';
    final duration = DateTime.now().difference(_connectionStartTime!);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Widget _buildPingIndicator(BuildContext context, VpnServer server) {
    final pingResult = _pingResults[server.id];
    final isLoading = pingResult?.isLoading ?? false;
    final latencyMs = pingResult?.latencyMs;
    final isSuccess = pingResult?.isSuccess ?? false;
    final isFailed = pingResult?.isFailed ?? false;
    final isTimeout = pingResult?.isTimeout ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    String pingText;
    Color pingColor;

    if (isLoading) {
      pingText = '...';
      pingColor = colorScheme.outline;
    } else if (isTimeout || isFailed) {
      pingText = 'Zaman Aşımı';
      pingColor = colorScheme.error;
    } else if (isSuccess && latencyMs != null) {
      pingText = '${latencyMs}ms';
      // ignore: unnecessary_non_null_assertion
      final latency = latencyMs!;
      if (latency < 100) {
        pingColor = Colors.green;
      } else if (latency < 200) {
        pingColor = Colors.orange;
      } else {
        pingColor = Colors.red;
      }
    } else {
      pingText = server.ping;
      pingColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${server.city} • ',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            pingText,
            style: TextStyle(
              color: pingColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedServerName = _selectedServer != null
        ? '${_selectedServer!.flag} ${_selectedServer!.name}'
        : 'Seçili Değil';

    final isConnected = _isConnected;
    final isConnecting = _isConnecting;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildDashboardCard(
          title: 'Durum',
          value: isConnected
              ? 'Bağlı'
              : isConnecting
              ? 'Bağlanıyor...'
              : 'Kesik',
          icon: isConnected
              ? Icons.check_circle
              : isConnecting
              ? Icons.sync
              : Icons.cancel,
          color: isConnected
              ? Colors.green
              : isConnecting
              ? Colors.orange
              : colorScheme.outline,
        ),
        _buildDashboardCard(
          title: 'Server',
          value: selectedServerName,
          icon: Icons.dns,
          color: colorScheme.primary,
        ),
        _buildDashboardCard(
          title: 'IP Adresi',
          value: isConnected
              ? _currentIp
              : _selectedServer?.address ?? '---.---.---.---',
          icon: Icons.public,
          color: isConnected ? Colors.blue : colorScheme.outline,
          isDisabled: !isConnected,
        ),
        _buildDashboardCard(
          title: 'Protokol',
          value: _selectedServer?.protocol.toUpperCase() ?? '--',
          icon: Icons.lock,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmallText = false,
    bool isDisabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final effectiveColor = isDisabled
        ? colorScheme.outline.withValues(alpha: 0.5)
        : color;

    final effectiveIconColor = isDisabled
        ? colorScheme.outline.withValues(alpha: 0.5)
        : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: effectiveIconColor, size: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallText ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: effectiveColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Server View (Dynamic) ---

  Widget _buildServerView() {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Box<VpnServer>>(
      valueListenable: ServerService.serversListenable,
      builder: (context, box, _) {
        final allServers = box.values.toList();

        for (final server in allServers) {
          final modifiedConfig = ServerService.getModifiedServerConfig(
            server.id,
          );
          if (modifiedConfig != null) {
            server.config = modifiedConfig;
          }
        }

        _subscriptions = ServerService.getAllSubscriptions();

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
                    setState(() => _currentIndex = 2);
                  },
                  child: const Text('Abonelik Ekle'),
                ),
              ],
            ),
          );
        }

        // 1. Filter Servers
        List<VpnServer> filteredServers = [];
        if (_selectedSubId == null) {
          filteredServers = allServers;
        } else {
          final targetSub = _subscriptions.firstWhere(
            (s) => s.id == _selectedSubId,
            orElse: () => _subscriptions.first,
          );
          filteredServers = targetSub.servers;
        }

        // 2. Sort Servers
        filteredServers.sort((a, b) {
          if (_currentSort == SortOption.name) {
            return a.name.compareTo(b.name);
          } else {
            int parsePing(String p) =>
                int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
            return parsePing(a.ping).compareTo(parsePing(b.ping));
          }
        });

        return Stack(
          children: [
            // Bottom Layer: Server List with top padding for header
            Padding(
              padding: const EdgeInsets.only(top: 140),
              child: filteredServers.isEmpty
                  ? Center(
                      child: Text(
                        'Bu kategoride server yok.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filteredServers.length,
                      itemBuilder: (context, index) {
                        final server = filteredServers[index];
                        final isSelected = _selectedServer?.id == server.id;

                        final parentSub = _subscriptions.firstWhere(
                          (s) => s.servers.contains(server),
                          orElse: () => _subscriptions.first,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  server.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            title: Text(
                              server.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${server.address}:${server.port}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_speedTestResult != null &&
                                    _speedTestResult!.serverName == server.name)
                                  Text(
                                    '⚡ ${_speedTestResult!.downloadSpeedFormatted} ↓ / ${_speedTestResult!.uploadSpeedFormatted} ↑ (Ping: ${_speedTestResult!.ping}ms)',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  _buildPingIndicator(context, server),
                                Text(
                                  '${server.protocol} • ${server.transport.toUpperCase()}${server.security == 'tls' ? ' • TLS' : ''}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            tileColor: isSelected
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedServer = server;
                              });
                            },
                            trailing: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showServerEditDialog(parentSub, server);
                                } else if (value == 'delete') {
                                  _deleteServer(parentSub, server);
                                } else if (value == 'copy') {
                                  _copyServerUrl(server);
                                } else if (value == 'ping') {
                                  _pingSingleServer(server);
                                } else if (value == 'speedtest') {
                                  _runSpeedTest(server);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'ping',
                                      child: Row(
                                        children: [
                                          Icon(Icons.network_check, size: 20),
                                          SizedBox(width: 8),
                                          Text('Ping Test'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Düzenle'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'speedtest',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.speed, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Speed Test'),
                                          if (_isSpeedTestRunning)
                                            const SizedBox(width: 8),
                                          if (_isSpeedTestRunning)
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'copy',
                                      child: Row(
                                        children: [
                                          Icon(Icons.content_copy, size: 20),
                                          SizedBox(width: 8),
                                          Text('Kopyala'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Sil',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Top Layer: Header with opaque background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Server Listesi',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Ping Testi',
                                icon: const Icon(Icons.network_check),
                                onPressed: () async {
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  await _pingFilteredServers();
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tüm serverlar için ping testi başlatıldı...',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              PopupMenuButton<SortOption>(
                                icon: const Icon(Icons.sort),
                                tooltip: 'Sırala',
                                initialValue: _currentSort,
                                onSelected: (SortOption item) {
                                  setState(() {
                                    _currentSort = item;
                                  });
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<SortOption>>[
                                      const PopupMenuItem<SortOption>(
                                        value: SortOption.name,
                                        child: Text('İsim (A-Z)'),
                                      ),
                                      const PopupMenuItem<SortOption>(
                                        value: SortOption.ping,
                                        child: Text('Ping (Düşük - Yüksek)'),
                                      ),
                                    ],
                              ),
                              IconButton(
                                tooltip: 'Tümünü Güncelle',
                                icon: const Icon(Icons.refresh),
                                onPressed: () async {
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  for (var sub in _subscriptions) {
                                    await _refreshSubscription(sub);
                                  }
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tüm abonelikler güncellendi',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Tümü'),
                              selected: _selectedSubId == null,
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedSubId = null;
                                });
                              },
                            ),
                          ),
                          ..._subscriptions.map((sub) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(sub.name),
                                selected: _selectedSubId == sub.id,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedSubId = selected ? sub.id : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Subscription View ---

  Widget _buildSubscriptionView() {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Box<VPNSubscription>>(
      valueListenable: ServerService.subscriptionsListenable,
      builder: (context, box, _) {
        _subscriptions = box.values.toList();

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
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
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
      },
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
              title: Text(
                sub.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${sub.servers.length} ${AppStrings.get('profile').toLowerCase()} • ${sub.url}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Quick Actions: Update, Ping
                IconButton(
                  tooltip: 'Yenile',
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await _refreshSubscription(sub);
                    await _loadSubscriptions();
                  },
                ),
                IconButton(
                  tooltip: 'Test Et',
                  icon: const Icon(Icons.network_check),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ping testi başlatılıyor...'),
                      ),
                    );

                    final serversToPing = sub.servers.take(10).map((server) {
                      return {
                        'id': server.id,
                        'address': server.address,
                        'port': server.port,
                      };
                    }).toList();

                    if (serversToPing.isNotEmpty) {
                      await PingService().pingServers(serversToPing);
                    }
                  },
                ),
                // More Actions: Edit, Delete
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showSubscriptionDialog(sub);
                    } else if (value == 'delete') {
                      _deleteSubscription(sub);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Düzenle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showSubscriptionDialog(VPNSubscription? sub) {
    final isEditing = sub != null;
    final nameController = TextEditingController(
      text: isEditing ? sub.name : '',
    );
    final urlController = TextEditingController(text: isEditing ? sub.url : '');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.add_circle_outline,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                isEditing
                    ? AppStrings.get('edit')
                    : AppStrings.get('add_subscription'),
                style: TextStyle(color: colorScheme.onSurface),
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
              if (_isSubscriptionSaving) const SizedBox(height: 16),
              if (_isSubscriptionSaving)
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Abonelik yükleniyor...'),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSubscriptionSaving
                  ? null
                  : () => Navigator.pop(context),
              child: Text(AppStrings.get('cancel')),
            ),
            ElevatedButton(
              onPressed: _isSubscriptionSaving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final name = nameController.text.trim();
                      final url = urlController.text.trim();
                      if (name.isNotEmpty && url.isNotEmpty) {
                        setState(() => _isSubscriptionSaving = true);
                        setDialogState(() => _isSubscriptionSaving = true);

                        if (isEditing) {
                          final index = _subscriptions.indexWhere(
                            (s) => s.id == sub.id,
                          );
                          if (index != -1) {
                            final updatedSub = VPNSubscription(
                              id: sub.id,
                              name: name,
                              url: url,
                              servers: sub.servers,
                            );
                            await ServerService.updateSubscription(
                              index,
                              updatedSub,
                            );
                            await _loadSubscriptions();

                            if (url != sub.url) {
                              await _refreshSubscription(updatedSub);
                            }
                          }
                        } else {
                          final newSub = VPNSubscription(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: name,
                            url: url,
                            servers: [],
                          );
                          await ServerService.addSubscription(newSub);
                          await _refreshSubscription(newSub);
                          await _loadSubscriptions();
                        }

                        setState(() => _isSubscriptionSaving = false);
                        if (mounted) {
                          navigator.pop();
                        }
                      }
                    },
              child: Text(AppStrings.get('save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteServer(
    VPNSubscription parentSub,
    VpnServer server,
  ) async {
    final box = ServerService.serversBox;
    final servers = box.values.toList();
    final index = servers.indexWhere((s) => s.id == server.id);

    if (index != -1) {
      await ServerService.removeModifiedServer(server.id);
      await box.deleteAt(index);

      final subscriptions = ServerService.getAllSubscriptions();
      for (final sub in subscriptions) {
        sub.servers.removeWhere((s) => s.id == server.id);
      }

      final subIndex = ServerService.subscriptionsBox.values
          .toList()
          .indexWhere((s) => s.id == parentSub.id);
      if (subIndex != -1) {
        await ServerService.updateSubscription(subIndex, parentSub);
      }

      if (_selectedServer?.id == server.id) {
        setState(() => _selectedServer = null);
      }

      _addLog('Server silindi: ${server.name}');
    }
  }

  Future<void> _copyServerUrl(VpnServer server) async {
    final data = server.parsedData;
    final protocol = data['type'] ?? 'vless';

    String url = '';

    if (protocol == 'vless') {
      final uuid = data['uuid'] ?? '';
      final address = data['address'] ?? data['server'] ?? '';
      final port = data['port'] ?? data['server_port'] ?? 443;
      final params = <String, dynamic>{};

      if (data['security'] != null) params['security'] = data['security'];
      if (data['type'] != null) {
        params['type'] = data['transport'] ?? data['network'];
      }
      if (data['path'] != null) params['path'] = data['path'];
      if (data['host'] != null) params['host'] = data['host'];
      if (data['sni'] != null) params['sni'] = data['sni'];
      if (data['alpn'] != null) params['alpn'] = data['alpn'];
      if (data['allowInsecure'] == true) params['allowInsecure'] = '1';
      if (data['fingerprint'] != null) params['fp'] = data['fingerprint'];
      if (data['pbk'] != null) params['pbk'] = data['pbk'];
      if (data['sid'] != null) params['sid'] = data['sid'];
      if (data['serviceName'] != null) {
        params['serviceName'] = data['serviceName'];
      }

      final queryString = params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
          )
          .join('&');

      url =
          'vless://$uuid@$address:$port${queryString.isNotEmpty ? '?$queryString' : ''}';
    } else if (protocol == 'vmess') {
      final vmessConfig = {
        'v': '2',
        'ps': server.name,
        'add': data['address'] ?? data['server'] ?? '',
        'port': data['port'] ?? data['server_port'] ?? 443,
        'id': data['uuid'] ?? '',
        'aid': '0',
        'net': data['transport'] ?? data['network'] ?? 'tcp',
        'type': 'none',
        'host': data['host'] ?? '',
        'path': data['path'] ?? '',
        'tls': data['security'] == 'tls' ? 'tls' : '',
        'sni': data['sni'] ?? data['host'] ?? '',
      };

      final jsonStr = jsonEncode(vmessConfig);
      url = 'vmess://${base64Encode(utf8.encode(jsonStr))}';
    } else if (protocol == 'trojan') {
      final password = data['password'] ?? '';
      final address = data['address'] ?? data['server'] ?? '';
      final port = data['port'] ?? data['server_port'] ?? 443;

      url = 'trojan://$password@$address:$port';
    }

    if (url.isNotEmpty && mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Server URL kopyalandı')));
      }
    }
  }

  void _showServerEditDialog(VPNSubscription sub, VpnServer server) {
    // Controllers
    final nameController = TextEditingController(text: server.name);
    final addressController = TextEditingController(text: server.address);
    final portController = TextEditingController(text: server.port.toString());
    final uuidController = TextEditingController(text: server.uuid ?? '');
    final sniController = TextEditingController(text: server.sni ?? '');
    final alpnController = TextEditingController(text: server.alpn ?? '');
    final fingerprintController = TextEditingController(
      text: server.fingerprint ?? '',
    );
    final hostController = TextEditingController(text: server.host ?? '');
    final pathController = TextEditingController(text: server.path ?? '');

    // State variables
    String selectedProtocol = server.protocol.toUpperCase();
    String selectedSecurity = server.security;
    String selectedTransport = server.transport;
    bool allowInsecure = server.allowInsecure;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Server Düzenle'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  server.name = nameController.text;

                  server.updateField('name', nameController.text);
                  server.updateField('address', addressController.text);
                  server.updateField('server', addressController.text);
                  server.updateField(
                    'port',
                    int.tryParse(portController.text) ?? 443,
                  );
                  server.updateField(
                    'server_port',
                    int.tryParse(portController.text) ?? 443,
                  );
                  server.updateField('uuid', uuidController.text);
                  server.updateField(
                    'protocol',
                    selectedProtocol.toLowerCase(),
                  );
                  server.updateField('type', selectedProtocol.toLowerCase());
                  server.updateField('security', selectedSecurity);
                  server.updateField('transport', selectedTransport);
                  server.updateField('network', selectedTransport);
                  server.updateField('allowInsecure', allowInsecure);

                  server.updateField(
                    'sni',
                    sniController.text.isNotEmpty ? sniController.text : null,
                  );
                  server.updateField(
                    'alpn',
                    alpnController.text.isNotEmpty
                        ? alpnController.text.split(',')
                        : null,
                  );
                  server.updateField(
                    'fingerprint',
                    fingerprintController.text.isNotEmpty
                        ? fingerprintController.text
                        : null,
                  );
                  server.updateField(
                    'host',
                    hostController.text.isNotEmpty ? hostController.text : null,
                  );
                  server.updateField(
                    'path',
                    pathController.text.isNotEmpty ? pathController.text : null,
                  );

                  final serversBox = ServerService.serversBox;
                  final serverKey = server.key;
                  final existingServer = serversBox.get(serverKey);

                  if (existingServer != null) {
                    existingServer.name = nameController.text;
                    existingServer.config = server.config;
                    await existingServer.save();
                  }

                  await ServerService.saveModifiedServer(server);
                  await server.save();

                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Server güncellendi ve kaydedildi'),
                    ),
                  );
                },
                child: Text(AppStrings.get('save')),
              ),
            ],
          ),
          body: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSettingsSection('Temel Bilgiler', [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'İsim',
                          prefixIcon: Icon(Icons.label),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: addressController,
                              decoration: const InputDecoration(
                                labelText: 'Adres',
                                prefixIcon: Icon(Icons.dns),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                prefixIcon: Icon(Icons.settings_ethernet),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildSettingsSection('Protokol', [
                      DropdownButtonFormField<String>(
                        initialValue:
                            [
                              'VLESS',
                              'VMESS',
                              'TROJAN',
                            ].contains(selectedProtocol)
                            ? selectedProtocol
                            : 'VLESS',
                        decoration: const InputDecoration(
                          labelText: 'Protokol',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        items: ['VLESS', 'VMESS', 'TROJAN']
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedProtocol = v!),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: uuidController,
                        decoration: const InputDecoration(
                          labelText: 'UUID / Password',
                          prefixIcon: Icon(Icons.password),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildSettingsSection('Güvenlik (TLS)', [
                      DropdownButtonFormField<String>(
                        initialValue: selectedSecurity,
                        decoration: const InputDecoration(
                          labelText: 'TLS Modu',
                          prefixIcon: Icon(Icons.security),
                        ),
                        items: ['none', 'tls', 'reality']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedSecurity = v!),
                      ),
                      SwitchListTile(
                        title: const Text('Güvensiz Bağlantıya İzin Ver'),
                        value: allowInsecure,
                        onChanged: (v) =>
                            setDialogState(() => allowInsecure = v),
                      ),
                      if (selectedSecurity != 'none') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: sniController,
                          decoration: const InputDecoration(
                            labelText: 'SNI',
                            prefixIcon: Icon(Icons.domain),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: fingerprintController,
                          decoration: const InputDecoration(
                            labelText: 'Fingerprint',
                            prefixIcon: Icon(Icons.fingerprint),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: alpnController,
                          decoration: const InputDecoration(
                            labelText: 'ALPN (virgülle ayır)',
                            prefixIcon: Icon(Icons.layers),
                          ),
                        ),
                      ],
                    ]),

                    const SizedBox(height: 24),
                    _buildSettingsSection('Transport', [
                      DropdownButtonFormField<String>(
                        initialValue: selectedTransport,
                        decoration: const InputDecoration(
                          labelText: 'Transport',
                          prefixIcon: Icon(Icons.swap_calls),
                        ),
                        items: ['tcp', 'ws', 'grpc', 'http']
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedTransport = v!),
                      ),
                      if (selectedTransport != 'tcp') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: pathController,
                          decoration: const InputDecoration(
                            labelText: 'Path / Service Name',
                            prefixIcon: Icon(Icons.folder),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: hostController,
                          decoration: const InputDecoration(
                            labelText: 'Host',
                            prefixIcon: Icon(Icons.computer),
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
              );
            },
          ),
        ),
      ),
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
              trailing: Text(
                AppStrings.getLanguageName(_currentLanguage),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).toggleDynamicColor(),
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
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).toggleTrueBlack(),
              ),
            ),
            _buildSettingsTile(
              Icons.accessibility,
              'Yüksek Kontrast',
              themeState.contrastLevel > 0 ? 'Açık' : 'Kapalı',
              () => ref.read(themeProvider.notifier).toggleContrastMode(),
              trailing: Switch(
                value: themeState.contrastLevel > 0,
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).toggleContrastMode(),
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
            _buildSettingsTile(Icons.public, 'Proxy Modu', 'Tüm Trafik', () {}),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('V2Ray Ayarları', [
            _buildSettingsTile(
              Icons.route,
              'Yönlendirme Modu',
              'Tüm Trafik',
              () {},
            ),
            _buildSettingsTile(Icons.dns, 'DNS Ayarları', 'Özel', () {}),
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
            _buildSettingsTile(Icons.dns, 'DNS Modu', 'Özel', () {}),
            _buildSettingsTile(
              Icons.security,
              'Tun Modu',
              'Açık',
              () {},
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            _buildSettingsTile(Icons.speed, 'MTU Ayarı', '1400', () {}),
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
          _buildSettingsSection('Log Ayarları', [
            _buildSettingsTile(Icons.bug_report, 'Log Seviyesi', 'Info', () {}),
            _buildSettingsTile(
              Icons.save_alt,
              'Logları Kaydet',
              'Kapalı',
              () {},
              trailing: Switch(value: false, onChanged: (_) {}),
            ),
            _buildSettingsTile(
              Icons.history,
              'Log Panelini Aç',
              '',
              _showLogPanel,
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
            _buildSettingsTile(Icons.code, 'GitHub', 'github.com', () {}),
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
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
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
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
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

  String _generateSingboxConfig(VpnServer server) {
    final outbound = server.toSingboxOutbound();

    final configMap = {
      "log": {"level": "trace"},
      "dns": _vpnSettings.buildSingboxDnsConfig(),
      "experimental": _vpnSettings.buildSingboxExperimentalConfig(),
      "inbounds": [
        _vpnSettings.buildSingboxInboundConfig(),
        _vpnSettings.buildSingboxMixedInboundConfig(),
      ],
      "outbounds": [
        outbound,
        {"type": "direct", "tag": "direct"},
        {"type": "direct", "tag": "bypass"},
      ],
      "route": _vpnSettings.buildSingboxRouteConfig(),
    };

    return jsonEncode(configMap);
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
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

    return ListTile(
      leading: Icon(icon, size: 22, color: colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: trailing,
      onTap: onTap,
      dense: true, // Kompakt mod
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  void _showLogPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Uygulama Logları',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () => _showLogFilterDialog(),
                        ),
                        IconButton(
                          icon: Icon(
                            _autoScrollLogs
                                ? Icons.auto_fix_high
                                : Icons.vertical_align_bottom,
                          ),
                          onPressed: () {
                            setState(() => _autoScrollLogs = !_autoScrollLogs);
                            if (_autoScrollLogs) {
                              _scrollToBottom();
                            }
                          },
                          tooltip: _autoScrollLogs
                              ? 'Otomatik kaydır'
                              : 'Son kaydır',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareLogs(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _logs.clear()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: _logScrollController,
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: log));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Log kopyalandı'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: _getLogColor(log),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareLogs() async {
    final logContent = _logs.join('\n');
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')[0];
    final filename = 'yusabox_logs_$timestamp.log';

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(logContent);

      if (mounted) {
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'YusaBox Logları');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log paylaşılırken hata: ${e.toString()}')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showLogFilterDialog() {
    final filters = ['All', 'INFO', 'WARN', 'ERROR'];
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Filtresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: filters
              .map(
                (filter) => ListTile(
                  title: Text(filter),
                  trailing: _logFilter == filter
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() => _logFilter = filter);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('[ERROR]')) return Colors.red;
    if (log.contains('[WARN]')) return Colors.orange;
    if (log.contains('[INFO]')) return Colors.blue;
    if (log.contains('[NATIVE]')) return Colors.purple;
    return Theme.of(context).colorScheme.onSurface;
  }

  List<String> get _filteredLogs {
    if (_logFilter == 'All') return _logs;
    return _logs.where((log) => log.contains('[$_logFilter]')).toList();
  }

  Future<void> _runSpeedTest(VpnServer server) async {
    if (_isSpeedTestRunning) {
      await SpeedTestService().stopSpeedTest();
      setState(() {
        _isSpeedTestRunning = false;
      });
      return;
    }

    setState(() {
      _isSpeedTestRunning = true;
      _speedTestResult = null;
    });

    _addLog('Speed test başlatılıyor: ${server.name}');

    final success = await SpeedTestService().startSpeedTest(
      server.address,
      server.name,
    );

    if (!success && mounted) {
      setState(() {
        _isSpeedTestRunning = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Speed test başlatılamadı')));
    }
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
          _buildServerView(),
          _buildSubscriptionView(),
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
          NavigationDestination(icon: const Icon(Icons.dns), label: 'Server'),
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
}
