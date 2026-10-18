import 'package:firebase_core/firebase_core.dart';

/// Firebase client options for the registered Nexora Android app.
/// These are client-side identifiers; protect data with Firebase Security Rules.
class DefaultFirebaseOptions {
  static const currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyAAyzHr_mH-OddP-o5U2YFBgvOrSlzHVk0',
    appId: '1:1052275102189:android:c879b38e7da1b21cd017e4',
    messagingSenderId: '1052275102189',
    projectId: 'nexora-finance-manager',
    storageBucket: 'nexora-finance-manager.firebasestorage.app',
  );
}
