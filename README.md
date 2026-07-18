# Fanconnact

Fantasy sports platform with live matches, predictions, leaderboards, and social features.

## Features

- Live match tracking across cricket, football, basketball, tennis, hockey, kabaddi, e-sports, baseball, volleyball, table tennis
- Real-time predictions and scoring
- User profiles with photo capture (filters, beauty mode, sports backgrounds)
- Email OTP verification
- Firebase authentication (email + Google)
- Dark/light theme
- Mobile-responsive design

## Tech Stack

- HTML + Tailwind CSS
- Firebase Auth + Firestore
- EmailJS (OTP)
- MediaPipe SelfieSegmentation (background removal)
- Cropper.js (image cropping)

## Mobile App (Flutter)

The `lib/`, `android/`, `ios/`, `windows/` folders contain a Flutter app that will
later connect to the same backend as the web version. Build the Android debug APK with:

```bash
flutter pub get
flutter build apk --debug
```

The output APK is at `build/app/outputs/flutter-apk/app-debug.apk`.
