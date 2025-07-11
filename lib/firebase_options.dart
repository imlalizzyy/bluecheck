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
    apiKey: 'AIzaSyC_VN7arh2xt0WyImu95MLBkvaOpXOmHN0',
    appId: '1:546387859312:web:4b80eda828817df20ae1b5',
    messagingSenderId: '546387859312',
    projectId: 'bluecheck25-13d39',
    authDomain: 'bluecheck25-13d39.firebaseapp.com',
    storageBucket: 'bluecheck25-13d39.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyASq1Ov_8g4dNUd0mUxnZ-35yOQes3F6O0',
    appId: '1:546387859312:android:70129ea716dffa070ae1b5',
    messagingSenderId: '546387859312',
    projectId: 'bluecheck25-13d39',
    storageBucket: 'bluecheck25-13d39.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAkAgmf5IfOx8ji8UWtR8EeRblR5S8ltRE',
    appId: '1:546387859312:ios:09bb1c13c6573b960ae1b5',
    messagingSenderId: '546387859312',
    projectId: 'bluecheck25-13d39',
    storageBucket: 'bluecheck25-13d39.firebasestorage.app',
    iosBundleId: 'com.example.bluecheck',
  );
}
