# LuxeStay

Flutter app for resort discovery and booking, with customer, hotel-owner and administrator workspaces backed by Firebase Authentication and Cloud Firestore.

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
- `lib/screens/owner/`: hotel-owner revenue and assigned-staff overview.
- `lib/screens/admin/`: administrator revenue overview, hotel management and
  staff assignment. Room and booking operations are owner-only.
- `lib/services/`: Firebase/Auth/Firestore access.
- `lib/providers/`: app state and auth state.
- `lib/models/`: Firestore data models.
- `lib/seed_data.dart`: sample data for the general customer/admin demo; its
  `SeedData.seed()` method is not run automatically. It writes through the app's
  Firestore client and is subject to the deployed Firestore Rules. The profiles,
  property details, ratings, reviews and bookings are synthetic examples, marked
  with `isDemo`; they are not real customer activity or audited hotel data.

### Owner test data

To populate an already registered OWNER's linked hotel with repeatable sample
rooms, bookings in four workflow states, and a staff profile, run the Admin SDK
seeder from `functions/`:

```powershell
cd functions
npm run seed:owner-demo -- <OWNER_UID>
```

The script verifies the owner profile and hotel's `ownerId`/`propertyId`
relationship before writing. It uses stable demo document IDs, so running it
again updates the same samples. The seeded staff profile is not an Auth account,
and all generated records are marked `isDemo`. Prefer a dedicated test project:
Admin SDK writes bypass Firestore Security Rules. The script can target a
Firestore Emulator by setting `GCLOUD_PROJECT` and `FIRESTORE_EMULATOR_HOST` in
the same PowerShell session, but the app currently does not connect its
Firestore client to the emulator, so emulator-seeded records will not appear in
the app until emulator connectivity is configured.

`lib/seed_data.dart` has no standalone command. Its `SeedData.seed()` method
would need to be invoked from Flutter code; the current security rules do not
allow all of its sample writes, so do not invoke it against a production
project. The OWNER seeder above is the supported way to prepare owner workflow
data.

Public registration offers only customer and hotel-owner accounts. An OWNER
first creates an account without entering hotel information, then completes the
hotel profile (name, location, address, contact phone, description and an
optional hotel image) and accepts the sample partnership terms inside the app.
The image is uploaded to Firebase Storage and its URL is saved with the hotel.
The hotel and the acceptance record are saved together and linked through
`propertyId`. The in-app agreement is a prototype, not a legally approved
contract. Deploy the Firestore authorization rules and callable functions
before using these workflows in a Firebase environment:

```powershell
firebase deploy --only firestore:rules,functions:getRevenueReport --project luxestay-1309f
```

## Maintainer Documentation

Read [MAINTAINER_NOTES.md](MAINTAINER_NOTES.md) before changing Firebase, authentication, bookings, rooms or admin permissions. It documents the current Firestore schema, known risks, unfinished features, platform limitations and a debugging checklist.

The most important open items are Firestore Rules, the split room schema, server-side booking/price validation, and the distinction between seeded Firestore profiles and real Firebase Auth accounts.
