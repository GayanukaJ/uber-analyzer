import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const _channel = MethodChannel('uber_analyzer/permissions');

  /// Check if Notification Listener access is granted.
  /// This cannot be requested programmatically — user must go to Settings.
  static Future<bool> isNotificationListenerGranted() async {
    try {
      return await NotificationsListener.hasPermission ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open Android Settings → Notification Access
  static Future<void> openNotificationListenerSettings() async {
    await NotificationsListener.openPermissionSettings();
  }

  /// Check if overlay (draw over other apps) permission is granted
  static Future<bool> isOverlayGranted() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  /// Request overlay permission (opens system dialog/settings)
  static Future<void> requestOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  /// Check notification permission (Android 13+)
  static Future<bool> isPostNotificationGranted() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  /// Request notification permission (Android 13+)
  static Future<void> requestPostNotification() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  /// Returns true when all required permissions are granted
  static Future<bool> allGranted() async {
    final notifListener = await isNotificationListenerGranted();
    final overlay = await isOverlayGranted();
    return notifListener && overlay;
  }
}
