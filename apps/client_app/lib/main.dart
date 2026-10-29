import 'package:compound_core/compound_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Push messages that arrive while the app is closed carry a `notification`
/// block, which the OS shows by itself; FCM still needs a background handler
/// registered to deliver them.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase backend (replaces the two Firebase apps). Owner accounts and
  // compound data are read from the shared Supabase project.
  await SupaConfig.initialize();
  await _initPush();
  runApp(const ProviderScope(child: ClientApp()));
}

/// Firebase is used only for push (FCM): the device token is saved on the
/// owner's record at login so the server can notify this phone. Without it
/// owners only saw alerts while the app was open. A failure here (e.g. iOS
/// before APNs is set up) leaves the app working without push.
Future<void> _initPush() async {
  if (kIsWeb ||
      !(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  } catch (e) {
    debugPrint('push disabled: $e');
  }
}
