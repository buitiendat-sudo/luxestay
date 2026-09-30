# LuxeStay

Flutter app for resort discovery, booking and admin operations, backed by Firebase Authentication and Cloud Firestore.

## Quick Start

```powershell
flutter pub get
flutter run -d chrome
```

AI travel plan generation calls Gemini through a Firebase callable function.
The API key stays in Cloud Functions Secret Manager and is never included in
the Flutter app.

Create a Gemini API key at https://aistudio.google.com/app/apikey, then set it
as a Firebase Functions secret and deploy the function:

```powershell
firebase functions:secrets:set GEMINI_API_KEY --project luxestay-1309f
firebase deploy --only functions:generateTravelPlan --project luxestay-1309f
}

The callable function requires an authenticated user and valid Firebase App
Check token. Cloud Functions deployment requires the Firebase project to use
the Blaze plan.
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
