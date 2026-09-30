# LuxeStay

Flutter app for resort discovery, booking and admin operations, backed by Firebase Authentication and Cloud Firestore.

## Quick Start

```powershell
flutter pub get
flutter run -d chrome
```

AI travel plan generation calls Gemini through a Firebase callable function.
For a local demo, create a fresh Gemini API key at
https://aistudio.google.com/app/apikey, then put it in the ignored
`functions/.secret.local` file:

```dotenv
GEMINI_API_KEY=your-new-key-here
}

Start the backend emulator in one terminal:

```powershell
firebase emulators:start --only functions --project luxestay-1309f
```

Run the Flutter app in another terminal:

```powershell
flutter run -d chrome --dart-define=USE_FUNCTIONS_EMULATOR=true
```

The demo still uses the configured Firebase project for Authentication and
Firestore, so sign in with an existing account. The API key stays in the local
emulator process and is not compiled into the web app. Do not reuse the key
previously pasted into chat; revoke it and create a new one.
```

Validate changes with:

```powershell
flutter analyze
flutter test
```

The current Firebase project is `luxestay-1309f`. Firebase options are currently configured for Android and Web. Run `flutterfire configure` before enabling another platform.

## Project Areas

- `lib/screens/customer/`: customer booking experience.
- `lib/screens/admin/`: admin dashboard and management screens.
- `lib/services/`: Firebase/Auth/Firestore access.
- `lib/providers/`: app state and auth state.
- `lib/models/`: Firestore data models.
- `lib/seed_data.dart`: development-only sample data; it is not run automatically.

## Maintainer Documentation

Read [MAINTAINER_NOTES.md](MAINTAINER_NOTES.md) before changing Firebase, authentication, bookings, rooms or admin permissions. It documents the current Firestore schema, known risks, unfinished features, platform limitations and a debugging checklist.

The most important open items are Firestore Rules, the split room schema, server-side booking/price validation, and the distinction between seeded Firestore profiles and real Firebase Auth accounts.
