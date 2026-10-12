# Field Notes

Field Notes is an offline-first Flutter app for recording customer sites and field visit notes. It is built for field workers who may need to keep working when an internet connection is unavailable.

> This repository contains the Flutter client. The API server is a separate service and must be running and reachable for registration, sign-in, and synchronization.

## Contents

- [Features](#features)
- [Technology](#technology)
- [Project structure](#project-structure)
- [Requirements](#requirements)
- [Run the app](#run-the-app)
- [Configure the API URL](#configure-the-api-url)
- [Build an Android APK](#build-an-android-apk)
- [Offline behavior and synchronization](#offline-behavior-and-synchronization)
- [Backend API contract](#backend-api-contract)
- [Permissions](#permissions)
- [Tests and static analysis](#tests-and-static-analysis)
- [Troubleshooting](#troubleshooting)

## Features

- Register and sign in with an email address and password.
- Manage customers and their sites.
- Create, edit, search, filter, and delete field notes.
- Assign notes a status: Draft, In progress, or Completed.
- Add a description, date and time, GPS coordinates, and a photo to a note.
- Store business data locally in SQLite and queue edits for later synchronization.
- Automatically synchronize queued edits when connectivity returns, as well as periodically while signed in.
- Download server-side note photos to the device.
- Choose or take a profile photo from Settings; it is stored locally on the current device and is not synced.
- Select a default status for new notes; this preference is saved on the current device and is not synchronized.
- Use the app on Android and in a web browser.

The location feature records latitude and longitude. The current client does not use Google Maps or reverse geocoding to display a place name; the note detail page uses a stylized map preview.

## Technology

- Flutter and Dart
- Material 3 UI
- `flutter_bloc` for app and feature state
- SQLite (`sqflite`; `sqflite_common_ffi_web` for web)
- Dio for HTTP requests
- Shared Preferences and Flutter Secure Storage for local preferences and session data
- `connectivity_plus` for connectivity change notifications
- `geolocator` for GPS coordinates
- `image_picker` for camera/gallery photos

## Project structure

```text
lib/
  app.dart                         App widget, providers, and auth navigation
  main.dart                        Flutter startup and dependency setup
  core/
    config.dart                    API URL and sync interval
    di.dart                        Dependency registration
    permissions.dart               Location and camera permissions
    theme.dart                     App theme
  data/
    local/
      local_db.dart                SQLite database and local outbox
      photo_storage.dart           Local photo files/data URLs
    remote/
      api_client.dart              HTTP client and error mapping
      mappers.dart                 API JSON/entity conversions
    repositories/
      repositories_impl.dart       Repository implementations
    sync/
      connectivity_service.dart    Network connectivity events
      sync_service.dart            Push/pull/photo synchronization
    session_store.dart             Token, user, and sync cursor storage
  domain/
    entities.dart                  App data models
    repositories.dart              Repository interfaces and API exception
  presentation/
    blocs/                         Auth, notes, sites, customers, and sync state
    pages/                         App screens and forms
    widgets/                       Shared UI components
test/
  widget_test.dart                 Auth BLoC tests
android/                           Android app configuration
web/                               Flutter web host files
```

## Requirements

- Flutter SDK compatible with Dart `>=3.3.0 <4.0.0`
- Android Studio/Android SDK for Android builds
- An API server implementing the [backend API contract](#backend-api-contract)

Check the local Flutter installation:

```powershell
flutter doctor
```

Fetch packages:

```powershell
flutter pub get
```

## Run the app

Start the API server first. The default API URL is `http://localhost:8080` on web and `http://10.0.2.2:8080` on non-web targets (the latter is the Android emulator's route to the development computer).

Run on an Android emulator:

```powershell
flutter run --dart-define=API_URL=http://10.0.2.2:8080
```

Run in a browser:

```powershell
flutter run -d chrome --dart-define=API_URL=http://localhost:8080
```

For a physical Android device on the same local network as the development computer, use the computer's LAN IP address instead of `localhost` or `10.0.2.2`. The backend must accept connections from the network (not listen only on loopback), and the computer firewall must allow its API port.

## Configure the API URL

The app reads the API base URL from the Dart compile-time environment variable `API_URL`:

```powershell
flutter run --dart-define=API_URL=https://api.example.com
```

Or when building:

```powershell
flutter build apk --release --dart-define=API_URL=https://api.example.com
```

If `API_URL` is not supplied, the defaults in `lib/core/config.dart` apply:

| Target | Default URL |
| --- | --- |
| Web | `http://localhost:8080` |
| Android emulator and other non-web targets | `http://10.0.2.2:8080` |

Use a reachable HTTPS URL for testers outside your local network. A laptop's private LAN IP (for example, `192.168.x.x`) only works for devices that can reach that same network. For temporary testing, a Cloudflare Quick Tunnel can expose a local service:

1. Run the API server on the laptop at `http://localhost:8080`.
2. In another terminal, run `cloudflared tunnel --url http://localhost:8080`.
3. Copy the generated `https://...trycloudflare.com` URL.
4. Build the APK using that URL as `API_URL`.

The API server and tunnel process must stay running, and the laptop must remain online. A Quick Tunnel URL is temporary and can change after the tunnel is restarted; rebuild the APK with the new URL if that happens. Quick Tunnels are for testing, not production hosting.

## Build an Android APK

Build a release APK:

```powershell
flutter build apk --release --dart-define=API_URL=https://api.example.com
```

The output is:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Use the exact API URL that testers' devices can access. The current Android release build uses the debug signing configuration in `android/app/build.gradle.kts`; configure a proper release signing key before publishing to an app store or distributing a production build.

## Offline behavior and synchronization

- Registration and sign-in contact the API and therefore require a reachable server and internet connection.
- After sign-in, customers, sites, and notes are stored in the local SQLite database. Creating, editing, and deleting these records queues changes in an outbox, so those operations can be made while offline.
- The sync service pushes queued changes in order, pulls server changes using a timestamp cursor, and downloads server photos that are missing locally.
- Sync is triggered at sign-in/app start, when connectivity returns, after local changes (debounced), periodically every 45 seconds, and from the manual sync control.
- Session tokens are stored with secure storage. User and sync metadata are stored in Shared Preferences.
- Notes can save GPS coordinates and photos locally. Location capture requires device location services and permission; camera capture requires camera permission.
- A first-time sign-in on a new device, or signing in again after signing out, requires network access. Offline support is for working with locally available app data, not offline account verification.

## Backend API contract

The API server is not included in this Flutter repository. The client expects the following routes under the configured base URL:

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/api/auth/register` | Register; JSON body: `name`, `email`, `password` |
| `POST` | `/api/auth/login` | Sign in; JSON body: `email`, `password` |
| `PUT` | `/api/customers/{id}` | Create or update a customer |
| `DELETE` | `/api/customers/{id}` | Delete a customer |
| `PUT` | `/api/sites/{id}` | Create or update a site |
| `DELETE` | `/api/sites/{id}` | Delete a site |
| `PUT` | `/api/notes/{id}` | Create or update a note |
| `DELETE` | `/api/notes/{id}` | Delete a note |
| `POST` | `/api/notes/{id}/photo` | Upload the note photo as multipart field `file` |
| `GET` | `/api/sync/pull?since={ISO-8601 timestamp}` | Return server changes since the sync cursor |

Successful auth responses must provide `token`, `userId`, `name`, and `email`. The sync pull response must provide `serverTime` and `customers`, `sites`, and `notes` arrays. Entity JSON fields include:

- Customer: `id`, `name`, `contactInfo`, `updatedAt`, `deleted`
- Site: `id`, `customerId`, `name`, `address`, `updatedAt`, `deleted`
- Note: `id`, `siteId`, `title`, `description`, `latitude`, `longitude`, `noteDateTime`, `status`, `updatedAt`, `deleted`, and optionally `photoUrl`

Dates use ISO-8601 strings. Note status values are `DRAFT`, `IN_PROGRESS`, and `COMPLETED`. The API should associate requests with the authenticated user and accept the session token in the `Authorization` header. For errors, the client displays a JSON string field named `error` when present.

The client uses stable UUIDs for local customer/site/note IDs and performs idempotent upserts. Deletes returned by sync should include the entity fields needed for decoding plus `deleted: true`. Photo upload responses may include `photoUrl`; the server must make that photo retrievable through the API's configured origin.

**Known client issue:** although the session token is stored after sign-in, `lib/data/remote/api_client.dart` currently sets the `Authorization` header to a masked literal instead of using the stored token. Authenticated sync requests may therefore fail with `401` until that header is corrected to match the backend's expected token format.

## Permissions

Android declares:

- `INTERNET` for API calls and synchronization
- `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` for GPS tagging
- `CAMERA` for taking note photos

Location and camera permissions are requested when the related feature is used. The user can still create notes without a location if location access is unavailable.

## Tests and static analysis

Run the test suite:

```powershell
flutter test
```

Run Dart/Flutter static analysis:

```powershell
flutter analyze
```

## Troubleshooting

### “You need an internet connection to sign in or register”

This message means the client could not reach the configured API server; it does not necessarily mean Wi-Fi/mobile data is off. Check that:

1. The backend is running and implements `/api/auth/login` and `/api/auth/register`.
2. The `API_URL` is correct and reachable from the device.
3. For a physical tester's phone, the URL is public and uses HTTPS; `localhost`, `10.0.2.2`, and a laptop's private LAN IP are not generally reachable from outside the local network.
4. If using a tunnel, both the backend and tunnel are still running and the APK was built with the current tunnel URL.

### Sync stays pending

Check the API server logs and the network URL. Failed outbox operations remain queued and are retried on a later sync. The API must support authenticated upserts/deletes and the `/api/sync/pull` response described above.

### Location was not recorded

Enable device location services and grant the app location permission. GPS acquisition can also take longer or fail indoors or in a weak signal area.
#   f i e l d - n o t e  
 