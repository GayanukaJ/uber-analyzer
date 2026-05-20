import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';
import '../services/permission_service.dart';
import '../services/background_service.dart';
import '../theme/app_theme.dart';
import '../widgets/permission_card.dart';
import '../widgets/trip_card.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _notifGranted = false;
  bool _overlayGranted = false;
  bool _serviceRunning = false;
  TripData? _lastTrip;

  ReceivePort? _receivePort;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _setupReceivePort();
    _loadLastTrip();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping(kPortName);
    super.dispose();
  }

  // Refresh permissions when user comes back from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final notif = await PermissionService.isNotificationListenerGranted();
    final overlay = await PermissionService.isOverlayGranted();
    final running = await FlutterBackgroundService().isRunning();
    if (mounted) {
      setState(() {
        _notifGranted = notif;
        _overlayGranted = overlay;
        _serviceRunning = running;
      });
    }
  }

  void _setupReceivePort() {
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, kPortName);
    _receivePort!.listen((data) {
      if (data is Map && mounted) {
        setState(() => _lastTrip = TripData.fromMap(data));
        _saveLastTrip(data);
      }
    });
  }

  Future<void> _loadLastTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('trip_history') ?? [];
    if (history.isNotEmpty && mounted) {
      setState(() => _lastTrip = TripData.fromHistoryLine(history.first));
    }
  }

  Future<void> _saveLastTrip(Map data) async {
    // background_service.dart saves full history; nothing extra needed here
  }

  Future<void> _toggleService() async {
    final service = FlutterBackgroundService();
    if (_serviceRunning) {
      service.invoke('stopService');
      setState(() => _serviceRunning = false);
    } else {
      await initBackgroundService();
      setState(() => _serviceRunning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _notifGranted && _overlayGranted;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            const Text('Uber Analyzer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            tooltip: 'Trip History',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status banner
          _buildStatusBanner(allGranted),
          const SizedBox(height: 20),

          // Permission cards
          if (!_notifGranted) ...[
            PermissionCard(
              step: '1',
              title: 'Notification Access',
              description:
                  'Lets this app read Uber trip notifications. '
                  'Go to Settings → Notifications → Notification Access → Enable Uber Analyzer.',
              granted: _notifGranted,
              buttonLabel: 'Open Notification Settings →',
              onTap: PermissionService.openNotificationListenerSettings,
            ),
            const SizedBox(height: 12),
          ],

          if (!_overlayGranted) ...[
            PermissionCard(
              step: '2',
              title: 'Display Over Other Apps',
              description:
                  'Lets the Rs/km popup appear on top of Uber. '
                  'Go to Settings → Apps → Uber Analyzer → Display over other apps → Enable.',
              granted: _overlayGranted,
              buttonLabel: 'Open Overlay Settings →',
              onTap: PermissionService.requestOverlayPermission,
            ),
            const SizedBox(height: 12),
          ],

          if (allGranted) ...[
            // Both granted — show start/stop button
            ElevatedButton(
              onPressed: _toggleService,
              style: ElevatedButton.styleFrom(
                backgroundColor: _serviceRunning ? const Color(0xFF2A2A4A) : AppTheme.accent,
              ),
              child: Text(_serviceRunning ? 'Stop Analyzer' : 'Start Analyzer'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _serviceRunning ? AppTheme.green : AppTheme.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _serviceRunning
                        ? 'Active – Watching for trip requests'
                        : 'Stopped – Tap to start monitoring',
                    style: TextStyle(
                      color: _serviceRunning ? AppTheme.green : AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Last trip card
          if (_lastTrip != null) ...[
            const Text('LAST TRIP', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 8),
            TripCard(trip: _lastTrip!),
          ] else ...[
            _buildEmptyState(),
          ],

          const SizedBox(height: 32),

          // How it works
          _buildHowItWorks(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool allGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: allGranted ? const Color(0xFF0D2A0D) : const Color(0xFF2A1A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allGranted ? const Color(0xFF1A4A1A) : const Color(0xFF4A3A0A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allGranted ? Icons.check_circle_outline : Icons.info_outline,
            color: allGranted ? AppTheme.green : AppTheme.yellow,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              allGranted
                  ? 'Ready! The popup will appear whenever Uber sends a trip request.'
                  : 'Grant the permissions below to enable the analyzer.',
              style: TextStyle(
                color: allGranted ? AppTheme.green : AppTheme.yellow,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, color: AppTheme.textSecondary, size: 48),
          const SizedBox(height: 12),
          const Text('No trips yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Go online in the Uber Driver app.\nThe Rs/km popup will appear automatically.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      ('📲', 'Uber sends a trip notification'),
      ('🔍', 'App reads the fare + distance'),
      ('🧮', 'Calculates Rs per km'),
      ('💬', 'Shows floating popup over Uber'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HOW IT WORKS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(s.$1, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(s.$2, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        )),
      ],
    );
  }
}
