// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDt7kKSL2r3NAuQY6tUJK9tthxr-qB-TKM',
    appId: '1:388953744470:web:4a916b03514e0a156447f7',
    messagingSenderId: '388953744470',
    projectId: 'barajacoffee-38e0c',
    authDomain: 'barajacoffee-38e0c.firebaseapp.com',
    storageBucket: 'barajacoffee-38e0c.firebasestorage.app',
    measurementId: 'G-C1YDMK042Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8DVJHZkWtfx05wl3FFCes_ly2anYaA5s',
    appId: '1:388953744470:android:401a07a9f35c8a9e6447f7',
    messagingSenderId: '388953744470',
    projectId: 'barajacoffee-38e0c',
    storageBucket: 'barajacoffee-38e0c.firebasestorage.app',
  );

}