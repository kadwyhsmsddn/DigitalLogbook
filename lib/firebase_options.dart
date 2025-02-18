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
    apiKey: 'AIzaSyD8hGxtEOX1AMrXA1f7XTZ__pyj5KmzHeI',
    appId: '1:508602647767:web:1d9dd4419679013bb99c92',
    messagingSenderId: '508602647767',
    projectId: 'fyp1-53e4f',
    authDomain: 'fyp1-53e4f.firebaseapp.com',
    storageBucket: 'fyp1-53e4f.appspot.com',
    measurementId: 'G-4QKSY9VC2E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCB02kFOwOB9CbqaPg9go1AQ42E16ShstU',
    appId: '1:508602647767:android:c0ad58fb04f52a2cb99c92',
    messagingSenderId: '508602647767',
    projectId: 'fyp1-53e4f',
    storageBucket: 'fyp1-53e4f.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDEK6ywQEeyXVAkkoWMQvafNCHwXsHEBaw',
    appId: '1:508602647767:ios:d033e9b347ff0a3ab99c92',
    messagingSenderId: '508602647767',
    projectId: 'fyp1-53e4f',
    storageBucket: 'fyp1-53e4f.appspot.com',
    iosBundleId: 'com.example.flutter_application_1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDEK6ywQEeyXVAkkoWMQvafNCHwXsHEBaw',
    appId: '1:508602647767:ios:d033e9b347ff0a3ab99c92',
    messagingSenderId: '508602647767',
    projectId: 'fyp1-53e4f',
    storageBucket: 'fyp1-53e4f.appspot.com',
    iosBundleId: 'com.example.flutter_application_1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD8hGxtEOX1AMrXA1f7XTZ__pyj5KmzHeI',
    appId: '1:508602647767:web:2bf54e28eef71910b99c92',
    messagingSenderId: '508602647767',
    projectId: 'fyp1-53e4f',
    authDomain: 'fyp1-53e4f.firebaseapp.com',
    storageBucket: 'fyp1-53e4f.appspot.com',
    measurementId: 'G-413WCDCWDT',
  );
}
