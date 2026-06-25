import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZPvmE19PIxRzOc69lDdRZzCnBkY2ucWY',
    appId: '1:766707217406:web:d6eaad14fb1b16e8be06af',
    messagingSenderId: '766707217406',
    projectId: 'gannaty-f16cc',
    authDomain: 'gannaty-f16cc.firebaseapp.com',
    storageBucket: 'gannaty-f16cc.firebasestorage.app',
    measurementId: 'G-84SDT9Z2DC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAd_jQb1fjfUImqoEClDnhKbJB6F24HsD4',
    appId: '1:766707217406:android:a73464033bda7fd6be06af',
    messagingSenderId: '766707217406',
    projectId: 'gannaty-f16cc',
    storageBucket: 'gannaty-f16cc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtWGzv_ulDXo-v_CDy_97LeIWdygNwWW0',
    appId: '1:766707217406:ios:e6779ec58f0d226ebe06af',
    messagingSenderId: '766707217406',
    projectId: 'gannaty-f16cc',
    storageBucket: 'gannaty-f16cc.firebasestorage.app',
    iosBundleId: 'com.gannaty.client_app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDtWGzv_ulDXo-v_CDy_97LeIWdygNwWW0',
    appId: '1:766707217406:ios:e6779ec58f0d226ebe06af',
    messagingSenderId: '766707217406',
    projectId: 'gannaty-f16cc',
    storageBucket: 'gannaty-f16cc.firebasestorage.app',
    iosBundleId: 'com.gannaty.client_app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDZPvmE19PIxRzOc69lDdRZzCnBkY2ucWY',
    appId: '1:766707217406:web:e681c094fcd004a6be06af',
    messagingSenderId: '766707217406',
    projectId: 'gannaty-f16cc',
    authDomain: 'gannaty-f16cc.firebaseapp.com',
    storageBucket: 'gannaty-f16cc.firebasestorage.app',
    measurementId: 'G-37X9CZ7PZN',
  );
}
