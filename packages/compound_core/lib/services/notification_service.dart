import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_stub_helper.dart'
    if (dart.library.html) 'notification_web_helper.dart';

/// Whether the current platform supports Firebase Messaging.
bool get _isSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Call this as a top-level function in each app's main.dart.
/// Must be annotated with @pragma('vm:entry-point').
Future<void> _defaultBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();

  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static StreamSubscription<String>? _tokenRefreshSub;

  static const _androidChannelId = 'compound_high_importance';
  static const _androidChannelName = 'Compound Notifications';
  static const _androidChannelDesc = 'Important compound alerts';

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once in main() after Firebase.initializeApp().
  /// On desktop platforms this is a no-op (notifications not supported).
  static Future<void> initialize({
    required void Function(Map<String, dynamic> data) onTap,
  }) async {
    if (!_isSupported) return;

    _messaging = FirebaseMessaging.instance;

    // 1. Request permission (iOS, Android 13+, and web browsers)
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (_isMobile) {
      // 2. Set up local notification plugin for foreground display (mobile only)
      _localNotifications = FlutterLocalNotificationsPlugin();
      await _setupLocalNotifications();

      // 3. Suppress iOS native foreground banner — flutter_local_notifications
      //    handles foreground display via the onMessage listener below,
      //    so we disable the system-level presentation to avoid duplicates.
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    }

    // 4. Foreground messages → show notification
    FirebaseMessaging.onMessage.listen((message) {
      if (_isMobile) {
        _showLocalNotification(message);
      } else if (kIsWeb) {
        final n = message.notification;
        if (n != null) {
          showBrowserNotification(n.title ?? '', n.body ?? '');
        }
      }
    });

    // 5. Notification tapped from background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onTap(message.data);
    });

    // 6. Notification tapped from terminated state
    final initial = await _messaging!.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        onTap(initial.data);
      });
    }
  }

  // ── Token management ───────────────────────────────────────────────────────

  /// Save the admin's FCM token to /fcmTokens/{uid}.
  static Future<void> saveAdminToken(String uid) async {
    if (!_isSupported || _messaging == null) return;

    final token = await _messaging!.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('fcmTokens')
        .doc(uid)
        .set({
          'token': token,
          'role': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging!.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('fcmTokens')
          .doc(uid)
          .update({'token': newToken, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  /// Remove the admin's FCM token from Firestore (call on logout).
  static Future<void> clearAdminToken(String uid) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await FirebaseFirestore.instance.collection('fcmTokens').doc(uid).delete();
  }

  /// Save the client's FCM token to their villa document.
  static Future<void> saveClientToken(String villaId) async {
    if (!_isSupported || _messaging == null) return;

    final token = await _messaging!.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('villas')
        .doc(villaId)
        .update({'fcmToken': token});

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging!.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('villas')
          .doc(villaId)
          .update({'fcmToken': newToken});
    });
  }

  /// Remove the client's FCM token from their villa document (call on logout).
  static Future<void> clearClientToken(String villaId) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await FirebaseFirestore.instance
        .collection('villas')
        .doc(villaId)
        .update({'fcmToken': FieldValue.delete()});
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    if (!_isSupported) return;

    if (kIsWeb) {
      await showBrowserNotification(title, body);
      return;
    }

    if (_localNotifications == null) {
      await _setupLocalNotifications();
    }
    if (_localNotifications == null) return;

    await _localNotifications!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Route helper ───────────────────────────────────────────────────────────

  static String routeFromMessage(Map<String, dynamic> data, {bool isAdmin = true}) {
    final screen = data['screen'] as String? ?? '';
    final id = data['id'] as String?;

    switch (screen) {
      case 'request_detail':
        return id != null ? '/requests/$id' : '/requests';
      case 'requests':
        return '/requests';
      case 'payments':
        return '/payments';
      default:
        return isAdmin ? '/dashboard' : '/home';
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<void> _setupLocalNotifications() async {
    if (_localNotifications == null) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications!.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _androidChannelId,
              _androidChannelName,
              description: _androidChannelDesc,
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    if (_localNotifications == null) return;
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications!.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// No-op background handler — register in each app's main.dart.
  static Future<void> handleBackground(RemoteMessage message) async {
    await _defaultBackgroundHandler(message);
  }
}
