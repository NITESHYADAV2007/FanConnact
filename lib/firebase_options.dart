// Firebase configuration for the Fanconnact app.
// Reuses the existing web Firebase project "fanconnact" so the app shares the
// same users, Firestore data, and auth as the web app.
//
// NOTE: For full native (Android/iOS) support you must also add the platform
// config files from the Firebase console:
//   - android/app/google-services.json
//   - ios/Runner/GoogleService-Info.plist
// The web/web config below lets the app run on Android via the web client id
// for Google sign-in and uses the same project id for Firestore/Auth.

class DefaultFirebaseOptions {
  static const String apiKey = 'AIzaSyCU8fjtDxBa6gyw2GDYwbU9znnXXaZDV_Q';
  static const String authDomain = 'fanconnact.firebaseapp.com';
  static const String projectId = 'fanconnact';
  static const String storageBucket = 'fanconnact.firebasestorage.app';
  static const String messagingSenderId = '1067605173307';
  static const String appId = '1:1067605173307:web:01c942ec550c4c889ba81e';
  static const String measurementId = 'G-Q02NEK5HMW';

  // Web client id (used for Google sign-in on Android).
  static const String webClientId =
      '1067605173307-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com';
}
