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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyB2rv9dpZizF30XoJrHEtUV24Zx5aYZsrI',
    appId: '1:424378457785:web:96f56ac22f8abd5f730568',
    messagingSenderId: '424378457785',
    projectId: 'nutritrack-af35a',
    authDomain: 'nutritrack-af35a.firebaseapp.com',
    storageBucket: 'nutritrack-af35a.firebasestorage.app',
    measurementId: 'G-STE13G7RJQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKw2M2mR8ogAaYRs5GNYOpmfsv0Qbwuxg',
    appId: '1:424378457785:android:3f7c063ddf20927d730568',
    messagingSenderId: '424378457785',
    projectId: 'nutritrack-af35a',
    storageBucket: 'nutritrack-af35a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDCbGjcfLa456dSu7v8hbSFFM99_ZrPrW0',
    appId: '1:424378457785:ios:749b717f255fae13730568',
    messagingSenderId: '424378457785',
    projectId: 'nutritrack-af35a',
    storageBucket: 'nutritrack-af35a.firebasestorage.app',
    iosBundleId: 'com.example.nutritrackV2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDCbGjcfLa456dSu7v8hbSFFM99_ZrPrW0',
    appId: '1:424378457785:ios:749b717f255fae13730568',
    messagingSenderId: '424378457785',
    projectId: 'nutritrack-af35a',
    storageBucket: 'nutritrack-af35a.firebasestorage.app',
    iosBundleId: 'com.example.nutritrackV2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB2rv9dpZizF30XoJrHEtUV24Zx5aYZsrI',
    appId: '1:424378457785:web:d31be0e92ced8d18730568',
    messagingSenderId: '424378457785',
    projectId: 'nutritrack-af35a',
    authDomain: 'nutritrack-af35a.firebaseapp.com',
    storageBucket: 'nutritrack-af35a.firebasestorage.app',
    measurementId: 'G-2FXQ5TB9LN',
  );
}
