import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtqBmGmjsxLhDDEQBmJh7J1fEjXL_nFlw',
    appId: '1:324857038552:android:fea84fbf9409b181e9f9ad',
    messagingSenderId: '324857038552',
    projectId: 'shine-app-final',
    storageBucket: 'shine-app-final.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAVrHkkYOnlSymKGfM5ymqRASPOxUuz_C0',
    appId: '1:324857038552:ios:75ea643f9f1f8823e9f9ad',
    messagingSenderId: '324857038552',
    projectId: 'shine-app-final',
    storageBucket: 'shine-app-final.firebasestorage.app',
    iosBundleId: 'com.shinepara.shineparaApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATnV_STI6tYLDt-Hja_B26zZMKF2OgXMU',
    appId: '1:324857038552:web:dcd5aea922aa801ce9f9ad',
    messagingSenderId: '324857038552',
    projectId: 'shine-app-final',
    authDomain: 'shine-app-final.firebaseapp.com',
    storageBucket: 'shine-app-final.firebasestorage.app',
    measurementId: 'G-MLXWPF7GE1',
  );
}
