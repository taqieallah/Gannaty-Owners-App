import 'package:compound_core/compound_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

/// Whether the current platform supports Firebase Messaging.
bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Top-level background message handler — required by FCM (mobile only).
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) =>
    NotificationService.handleBackground(message);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase Messaging — mobile only (not supported on Windows/macOS)
  if (_isMobile) {
    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      adminInitialNotificationRoute = NotificationService.routeFromMessage(
        initialMessage.data,
        isAdmin: true,
      );
    }
  }

  // NotificationService.initialize is guarded internally —
  // it's a safe no-op on desktop platforms.
  await NotificationService.initialize(
    onTap: (data) {
      final route =
          NotificationService.routeFromMessage(data, isAdmin: true);
      navigateFromAdminNotification(route);
    },
  );

  runApp(const ProviderScope(child: AdminApp()));
}
