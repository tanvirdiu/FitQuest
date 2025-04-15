import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Since we're primarily facing issues with Android, let's use a single configuration
    // regardless of platform to ensure consistency
    return const FirebaseOptions(
      apiKey: "AIzaSyC_yQd6F_caB9ftEf-KP6gtJwsFd5_lwjU",
      appId: "1:856731486198:android:402988a39e120021fca9d7",
      messagingSenderId: "856731486198",
      projectId: "fitnessquest-bf9ca",
      storageBucket: "fitnessquest-bf9ca.firebasestorage.app",
      authDomain: "fitnessquest-bf9ca.firebaseapp.com",
    );
  }
}
