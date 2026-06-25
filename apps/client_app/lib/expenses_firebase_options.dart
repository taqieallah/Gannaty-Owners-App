import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// FirebaseOptions for the `gannaty-expenses` project.
/// This is used as a secondary Firebase app so the client can read
/// owner account data written by I:\Rebrand (the admin ERP).
class ExpensesFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCIEDer7G8TUCqUG2x6figZw5ex_FyW6Js',
    appId: '1:920822721681:android:d7bfe5f9dc03f3d9bcb10f',
    messagingSenderId: '920822721681',
    projectId: 'gannaty-expenses',
    storageBucket: 'gannaty-expenses.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCIEDer7G8TUCqUG2x6figZw5ex_FyW6Js',
    appId: '1:920822721681:ios:d7bfe5f9dc03f3d9bcb10f',
    messagingSenderId: '920822721681',
    projectId: 'gannaty-expenses',
    storageBucket: 'gannaty-expenses.firebasestorage.app',
    iosBundleId: 'com.gannaty.client_app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCIEDer7G8TUCqUG2x6figZw5ex_FyW6Js',
    appId: '1:920822721681:macos:d7bfe5f9dc03f3d9bcb10f',
    messagingSenderId: '920822721681',
    projectId: 'gannaty-expenses',
    storageBucket: 'gannaty-expenses.firebasestorage.app',
    iosBundleId: 'com.gannaty.client_app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCIEDer7G8TUCqUG2x6figZw5ex_FyW6Js',
    appId: '1:920822721681:web:5f0f2d2f0c9bcb10f12345',
    messagingSenderId: '920822721681',
    projectId: 'gannaty-expenses',
    authDomain: 'gannaty-expenses.firebaseapp.com',
    storageBucket: 'gannaty-expenses.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCIEDer7G8TUCqUG2x6figZw5ex_FyW6Js',
    appId: '1:920822721681:web:5f0f2d2f0c9bcb10f12345',
    messagingSenderId: '920822721681',
    projectId: 'gannaty-expenses',
    authDomain: 'gannaty-expenses.firebaseapp.com',
    storageBucket: 'gannaty-expenses.firebasestorage.app',
  );
}
