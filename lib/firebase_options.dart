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
    apiKey: 'AIzaSyDJOR_aejoPehKpmZyp7RkY0bPcB7CM5NE',
    appId: '1:130875652767:web:77ad13d46cc5166c4880aa',
    messagingSenderId: '130875652767',
    projectId: 'ai-connectcar',
    authDomain: 'ai-connectcar.firebaseapp.com',
    storageBucket: 'ai-connectcar.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAON0TK6X2Cda0S6YyH4hrKY_V66dBvzd8',
    appId: '1:130875652767:android:52906add7219c66c4880aa',
    messagingSenderId: '130875652767',
    projectId: 'ai-connectcar',
    storageBucket: 'ai-connectcar.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMN-BtyIlx4jg7xo9K-PwXKV5aCw4CVpE',
    appId: '1:130875652767:ios:cb6452ab3e2221b74880aa',
    messagingSenderId: '130875652767',
    projectId: 'ai-connectcar',
    storageBucket: 'ai-connectcar.appspot.com',
    iosBundleId: 'com.konkukbulls.aiconnectcar',
  );
}
