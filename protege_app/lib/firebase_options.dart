// File generated based on google-services.json from Firebase Console.
// Project: protege-f0256

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcB4iljo9T_qWoJF4xrnWl9ygdkXAL6VU',
    appId: '1:584128862801:android:c7f3bff2a157c428d5f670',
    messagingSenderId: '584128862801',
    projectId: 'protege-f0256',
    storageBucket: 'protege-f0256.firebasestorage.app',
  );

  // TODO: Add iOS configuration from Firebase Console
  // Go to Firebase Console > Project Settings > Add iOS app
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '584128862801',
    projectId: 'protege-f0256',
    storageBucket: 'protege-f0256.firebasestorage.app',
    iosBundleId: 'com.protege.app',
  );

  // TODO: Add web configuration from Firebase Console if needed
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '584128862801',
    projectId: 'protege-f0256',
    storageBucket: 'protege-f0256.firebasestorage.app',
    authDomain: 'protege-f0256.firebaseapp.com',
  );

  // TODO: Add macOS configuration from Firebase Console if needed
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '584128862801',
    projectId: 'protege-f0256',
    storageBucket: 'protege-f0256.firebasestorage.app',
    iosBundleId: 'com.protege.app.RunnerTests',
  );
}
