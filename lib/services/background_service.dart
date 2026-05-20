import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// UBER PACKAGE NAME — change if needed for your region/device
// To find the exact name: install "Package Name Viewer" from Play Store
// ─────────────────────────────────────────────────────────────
const String kUberPackage = 'com.ubercab.driver';
// Alternative: 'com.ubercab' for the rider app

// Port name for IsolateNameServer (lets main isolate receive events)
const String kPortName = 'uber_analyzer_port';

// ─────────────────────────────────────────────────────────────
// INITIALIZE BACKGROUND SERVICE
// Called once from main() at app startup
// ─────────────────────────────────────────────────────────────
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'uber_analyzer_channel',
      initialNotificationTitle: 'Uber Analyzer',
      initialNotificationContent: 'Watching for trip requests...',
      foregroundServiceNotificationId: 2001,
    ),
    iosConfiguration: IosConfiguration(), // Not needed for Android
  );

  await service.startService();
}

// ─────────────────────────────────────────────────────────────
// BACKGROUND SERVICE ENTRY POINT
// Runs in a separate isolate — sets up notification listener
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> onServiceStart(ServiceInstance service) async {
  // Start the notification listener plugin
  await NotificationsListener.initialize(callbackHandle: _onNotification);

  // Register a port so the main UI can also receive events
  final receivePort = ReceivePort();
  IsolateNameServer.registerPortWithName(receivePort.sendPort, kPortName);

  // Handle stop signal from the UI
  service.on('stopService').listen((_) => service.stopSelf());

  // Keep service alive
  Timer.periodic(const Duration(hours: 1), (_) {
    service.invoke('heartbeat');
  });
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION CALLBACK
// Called by flutter_notification_listener for every notification
// Must be a top-level function (not a lambda), annotated with pragma
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void _onNotification(NotificationEventV2 event) {
  // Filter: only process Uber Driver notifications
  final package = event.packageName ?? '';
  if (!package.contains('ubercab')) return;

  debugPrint('[UberAnalyzer] Notification from: $package');
  debugPrint('[UberAnalyzer] Title: ${event.title}');
  debugPrint('[UberAnalyzer] Text: ${event.text}');
  debugPrint('[UberAnalyzer] BigText: ${event.bigText}');

  // Combine all text for parsing
  final allText = [
    event.title ?? '',
    event.text ?? '',
    event.bigText ?? '',
    event.subText ?? '',
  ].join(' ');

  final price = _extractPrice(allText);
  final distance = _extractDistance(allText);

  debugPrint('[UberAnalyzer] Parsed -> price: $price | distance: $distance km');

  // Only proceed if we got useful data
  if (price <= 0 && distance <= 0) return;

  final data = {
    'price': price,
    'distanceKm': distance,
    'title': event.title ?? 'Trip Request',
    'rawText': allText,
    'perKm': (price > 0 && distance > 0) ? price / distance : 0.0,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };

  // Send to main UI via IsolateNameServer
  final sendPort = IsolateNameServer.lookupPortByName(kPortName);
  sendPort?.send(data);

  // Show the overlay popup
  _showOverlay(data);

  // Save to history
  _saveToHistory(data);
}

// ─────────────────────────────────────────────────────────────
// SHOW FLOATING OVERLAY
// ─────────────────────────────────────────────────────────────
Future<void> _showOverlay(Map<String, dynamic> data) async {
  // Check if overlay permission is granted
  final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
  if (!hasPermission) return;

  // Close any existing overlay
  final isActive = await FlutterOverlayWindow.isActive();
  if (isActive) {
    await FlutterOverlayWindow.closeOverlay();
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // Open the overlay window
  // overlayMain() in main.dart is the entry point for the overlay UI
  await FlutterOverlayWindow.showOverlay(
    height: 320,
    width: 320,
    alignment: OverlayAlignment.centerRight,
    flag: OverlayFlag.defaultFlag,
    enableDrag: true,
    positionGravity: PositionGravity.auto,
    startPosition: const OverlayPosition(0, 150),
  );

  // Small delay for the overlay to initialize, then send data
  await Future.delayed(const Duration(milliseconds: 400));
  FlutterOverlayWindow.shareData(data);

  // Auto-close after 30 seconds (matches Uber's notification timeout)
  Future.delayed(const Duration(seconds: 30), () async {
    final stillActive = await FlutterOverlayWindow.isActive();
    if (stillActive) FlutterOverlayWindow.closeOverlay();
  });
}

// ─────────────────────────────────────────────────────────────
// SAVE TRIP TO HISTORY (SharedPreferences)
// ─────────────────────────────────────────────────────────────
Future<void> _saveToHistory(Map<String, dynamic> data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('trip_history') ?? [];

    // Build a simple CSV line: timestamp,price,distanceKm,perKm
    final line =
        '${data['timestamp']},${data['price']},${data['distanceKm']},${data['perKm']}';

    history.insert(0, line); // newest first
    if (history.length > 100) history.removeLast(); // cap at 100 entries

    await prefs.setStringList('trip_history', history);
  } catch (e) {
    debugPrint('[UberAnalyzer] Failed to save history: $e');
  }
}

// ─────────────────────────────────────────────────────────────
// PARSE PRICE from notification text
// Handles: Rs. 450, LKR 450, රු. 450, ₹450, Rs450
// ─────────────────────────────────────────────────────────────
double _extractPrice(String text) {
  // Pattern 1: currency symbol/code before number
  final p1 = RegExp(
    r'(?:Rs\.?|LKR|රු\.?|₹|\$|€|£)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  final m1 = p1.firstMatch(text);
  if (m1 != null) {
    return double.tryParse(m1.group(1)!.replaceAll(',', '')) ?? 0;
  }

  // Pattern 2: number before currency
  final p2 = RegExp(
    r'([\d,]+(?:\.\d{1,2})?)\s*(?:Rs\.?|LKR|රු\.?|₹)',
    caseSensitive: false,
  );
  final m2 = p2.firstMatch(text);
  if (m2 != null) {
    return double.tryParse(m2.group(1)!.replaceAll(',', '')) ?? 0;
  }

  // Pattern 3: keyword before number (fare, price, amount, total)
  final p3 = RegExp(
    r'(?:fare|price|amount|trip|total)[:\s]+(?:Rs\.?|LKR|රු\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  final m3 = p3.firstMatch(text);
  if (m3 != null) {
    return double.tryParse(m3.group(1)!.replaceAll(',', '')) ?? 0;
  }

  return 0.0;
}

// ─────────────────────────────────────────────────────────────
// PARSE DISTANCE from notification text
// Handles: 12.5 km, 12.5km, 12 KM, 12.5 kilometers
// ─────────────────────────────────────────────────────────────
double _extractDistance(String text) {
  final p = RegExp(
    r'([\d.]+)\s*(?:km|kilometer|kilometres?)',
    caseSensitive: false,
  );
  final m = p.firstMatch(text);
  if (m != null) {
    return double.tryParse(m.group(1)!) ?? 0;
  }
  return 0.0;
}
