# Bhakti – Divine Music for a Better Life
> *"Spirituality for Everyone, Everywhere"* • *॥ लोकाः समस्ताः सुखिनೋ ಭವಂತು ॥*

**Bhakti** is a complete, production-ready, cross-platform devotional audio application designed for spiritual listeners of all age groups. It brings sacred stotras, sahasranamam, chalisa, bhajans, aartis, and mantras with high-fidelity audio playback, full lock-screen background controls, 5-language localization, zero-sign-in instant access, offline caching, and an in-app administrator portal for global content distribution.

---

## 🌟 Key Features

### 1. Zero-Sign-In End User Experience
- **Instant Access**: No mandatory registration, OTP, phone number, or login required.
- **Local Persistence**: Favorites, recently played listening history, active language, and playback speed are stored locally on the device with zero backend friction.

### 2. Five Supported Sacred Languages
1. **Kannada (ಕನ್ನಡ)** *(Default)*
2. **English**
3. **Hindi (हिन्दी)**
4. **Tamil (தமிழ்)**
5. **Malayalam (മലയാളം)**
- Full dynamic localization system without hardcoded strings. Switch anytime from Home or Settings.

### 3. Interactive Devotional Music Player & Background Audio
- Large high-resolution artwork and complete Sanskrit/Indic lyrics.
- **Lock-Screen & Notification Media Controls** for Android and iOS.
- **Continuous Playback**: Plays uninterrupted when phone is locked, screen off, or app backgrounded.
- **Controls**: Play/Pause, Next/Previous, Seek Backward 15s, Seek Forward 15s, Progress Slider.
- **Variable Playback Speed**: `0.75x`, `1.0x`, `1.25x`, `1.5x`, `2.0x`.
- **Sleep Timer**: `15 min`, `30 min`, `45 min`, `60 min`, or `End of song`.
- **Playback Queue**: View, drag-and-drop reorder, track deletion, and clear queue.
- **Repeat & Shuffle**: Off, Repeat All, Repeat One, and Shuffle mode.
- **Persistent Mini-Player**: Bottom docked player above navigation across all screens.

### 4. In-App Administrator Portal
- **Secure Access**: In-app admin login screen (development credentials: `sri` / `sri`).
- **Dashboard**: Real-time stats (Total Songs, Live, Drafts, Categories).
- **Add / Edit Devotional Song**:
  - Title & localized deity metadata.
  - Category and Language assignment.
  - Image cover upload with size/type validation.
  - Audio file upload (MP3/M4A) with streaming validation.
  - Full lyrics and spiritual significance description.
  - One-tap global publishing.
- **Global Content Delivery**: Once published by admin, songs immediately sync to Firebase Firestore & Cloud Storage and appear live for all Android & iOS users without requiring app store updates.

### 5. Monetization & Analytics
- **Google AdMob**: Centralized `AdService` supporting Banner, Native, and Interstitial ads.
- **Spiritual Listening Protection**: Rate-limited ads that never interrupt or disrupt devotional audio playback.
- **Firebase Analytics**: Anonymous tracking of `song_started`, `song_completed`, `song_favorited`, `language_selected`, and `search_used`.

---

## 🏛️ Project Architecture

```
lib/
├── core/
│   ├── constants/            # Colors (Maroon, Saffron, Gold, Cream), AppConstants, Typography
│   ├── localization/         # 5-Language Dictionary & LocalizationsDelegate
│   └── theme/                # Devotional Light and Dark Themes (Accessible Material 3)
├── models/
│   ├── song_model.dart       # Song entity with JSON & Firestore serialization
│   ├── category_model.dart   # Devotional categories (Stotras, Sahasranamam, etc.)
│   └── language_model.dart   # 5 Language definitions (kn, en, hi, ta, ml)
├── services/
│   ├── audio/                # JustAudio + JustAudioBackground service engine
│   ├── firebase/             # Firestore, Storage, and Admin Auth services
│   ├── ads/                  # AdMob banner and interstitial ad service
│   ├── analytics/            # Firebase Analytics tracker
│   ├── cache/                # Media cache calculation & clearing
│   └── preferences/          # SharedPreferences local storage & password hashing
├── repositories/
│   ├── song_repository.dart  # Song querying, search, filtering, and local mapping
│   └── category_repository.dart
├── features/
│   ├── splash/               # Animated spiritual splash screen
│   ├── language/             # Accessible 5-language selection screen
│   ├── home/                 # Hero spiritual banner, recents, popular, categories
│   ├── songs/                # Devotional library, category filter, and song details
│   ├── search/               # Real-time multi-lingual search
│   ├── player/               # Full player, mini player, queue, sleep timer, speed
│   ├── favorites/            # Local zero-login favorites list with "Play All"
│   ├── settings/             # Language switcher, cache clear, legal, admin entry
│   └── admin/                # Admin login, dashboard, add/edit song, category manager
└── main.dart                 # Application entrypoint & MultiProvider setup
```

---

## 🔧 Prerequisites & Toolchain

- **Flutter SDK**: `3.47.5` or higher
- **Dart SDK**: `3.13.4` or higher
- **Android Studio** / **Xcode** (for iOS builds)
- **Java**: JDK 17 or JDK 21

---

## 🚀 Getting Started

### 1. Clone & Install Dependencies
```bash
cd "devotional app"
flutter pub get
```

### 2. Run Automated Tests
```bash
flutter test
```

### 3. Run Locally
```bash
# Run on connected device or simulator
flutter run
```

---

## ☁️ Firebase Configuration

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Create a project named `bhakti-devotional-app`.
3. Enable **Cloud Firestore**, **Firebase Storage**, and **Firebase Authentication**.

### 2. Download Client Config Files
- **Android**: Download `google-services.json` and place it in `android/app/google-services.json`.
- **iOS**: Download `GoogleService-Info.plist` and place it in `ios/Runner/GoogleService-Info.plist`.

### 3. Deploy Firestore & Storage Security Rules
Install Firebase CLI if not installed (`npm install -g firebase-tools`):
```bash
firebase login
firebase use --add <your-project-id>
firebase deploy --only firestore,storage
```

---

## 🔒 Security Rules

### Firestore Security Rules (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null;
    }

    match /songs/{songId} {
      allow read: if resource == null || resource.data.published == true || isAdmin();
      allow create, update, delete: if isAdmin();
    }

    match /categories/{categoryId} {
      allow read: if true;
      allow create, update, delete: if isAdmin();
    }

    match /admins/{adminId} {
      allow read, write: if isAdmin();
    }
  }
}
```

### Storage Security Rules (`storage.rules`)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isAdmin() {
      return request.auth != null;
    }

    match /songs/{songId}/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin() && request.resource.size < 50 * 1024 * 1024;
    }
  }
}
```

---

## 🔑 Admin Credentials & Management

### Default Development Credentials
- **Username**: `sri`
- **Password**: `sri`

### How to Change Admin Password
1. Open **Settings** > **Admin Portal**.
2. Log in with current password.
3. Open top-right menu (⋮) > Select **Change Admin Password**.
4. Enter current and new password. The new password is cryptographically hashed with SHA-256 and stored securely.

---

## 📱 Release Build Instructions

### Android Release (Google Play Store)
1. Ensure your signing key is configured in `android/key.properties`.
2. Generate an Android App Bundle (AAB):
```bash
flutter build appbundle --release
```
3. The generated file is located at `build/app/outputs/bundle/release/app-release.aab`.

### iOS Release (Apple App Store)
1. Open the iOS project in Xcode:
```bash
open ios/Runner.xcworkspace
```
2. Select your Apple Developer Team under **Signing & Capabilities**.
3. Build the production IPA:
```bash
flutter build ipa --release
```
4. Upload via Xcode Organizer or `xcrun altool`.

---

## 📜 License & Content Attribution
The Bhakti application architecture and codebase are provided for production deployment. All devotional content, stotras, recordings, and deity imagery should be verified for appropriate distribution rights prior to commercial distribution.
