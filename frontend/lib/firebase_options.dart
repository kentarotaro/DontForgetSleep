// File generated/maintained manually for local Firebase initialization.
// Update these values if the Firebase project configuration changes.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbaha8_Cvi39eQcU1kSAPSYpL-KNZsNPg',
    appId: '1:224581222595:web:5d64209500d719bafb2276',
    messagingSenderId: '224581222595',
    projectId: 'dontforgetsleep-b146c',
    authDomain: 'dontforgetsleep-b146c.firebaseapp.com',
    storageBucket: 'dontforgetsleep-b146c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbaha8_Cvi39eQcU1kSAPSYpL-KNZsNPg',
    appId: '1:224581222595:android:5d64209500d719bafb2276',
    messagingSenderId: '224581222595',
    projectId: 'dontforgetsleep-b146c',
    storageBucket: 'dontforgetsleep-b146c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBdT219ggSKEPCEMi7MYuXi_MruLWUzfCc',
    appId: '1:224581222595:ios:6bfc8a6f1fe988bcfb2276',
    messagingSenderId: '224581222595',
    projectId: 'dontforgetsleep-b146c',
    storageBucket: 'dontforgetsleep-b146c.firebasestorage.app',
    iosBundleId: 'com.example.dontForgetSleep',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = android;
  static const FirebaseOptions linux = android;
}
