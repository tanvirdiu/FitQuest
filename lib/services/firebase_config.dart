import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static FirebaseOptions? _cachedOptions;

  static FirebaseOptions get platformOptions {
    if (_cachedOptions != null) return _cachedOptions!;

    // These are the values from your google-services.json
    _cachedOptions = const FirebaseOptions(
      apiKey: "AIzaSyC_yQd6F_caB9ftEf-KP6gtJwsFd5_lwjU",
      appId: "1:856731486198:android:402988a39e120021fca9d7",
      messagingSenderId: "856731486198",
      projectId: "fitnessquest-bf9ca",
      storageBucket: "fitnessquest-bf9ca.firebasestorage.app",
      authDomain: "fitnessquest-bf9ca.firebaseapp.com",
    );

    return _cachedOptions!;
  }

  static Future<void> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: platformOptions,
        );
        print("Firebase manually initialized with explicit options");
      } else {
        print("Firebase already initialized");
      }
    } catch (e) {
      print("Firebase initialization error: $e");
      // As a fallback, try with default options
      try {
        await Firebase.initializeApp();
        print("Firebase initialized with default options");
      } catch (fallbackError) {
        print("Firebase fallback initialization error: $fallbackError");
      }
    }
  }
}
