 <div align="center">

# 📝 Field Notes

### Offline-First Field Visit & Customer Site Management App

A Flutter application for managing customers, sites, and field visit notes — even without an internet connection.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Material 3](https://img.shields.io/badge/Material%203-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white)

</div>

---

## 📌 Overview

**Field Notes** is an offline-first Flutter application designed for field workers who need to manage customer information, customer sites, and field visit notes.

The application stores business data locally using SQLite and synchronizes pending changes with a separate backend API when connectivity becomes available.

> **Note:** This repository contains the Flutter client only. A separate backend API is required for registration, sign-in, and data synchronization.

## ✨ Features

- 🔐 **Authentication** — Register and sign in using email and password.
- 👥 **Customer Management** — Create, edit, search, and delete customers.
- 📍 **Site Management** — Manage customer sites and addresses.
- 📝 **Field Notes** — Create, update, search, filter, and delete visit notes.
- 🚦 **Status Tracking** — Draft, In Progress, and Completed statuses.
- 📷 **Photo Attachments** — Add photos using the camera or gallery.
- 🧭 **GPS Location** — Record latitude and longitude for field visits.
- 💾 **Offline Storage** — Save customer, site, and note data locally.
- 🔄 **Automatic Synchronization** — Queue changes while offline and sync when connectivity returns.
- ⬇️ **Photo Synchronization** — Download server-side note photos to the device.
- ⚙️ **Local Preferences** — Set a profile photo and default status for new notes.
- 📱 **Cross-Platform Support** — Run on Android and in a web browser.

## 🧰 Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application framework |
| Dart | Programming language |
| Material 3 | User interface design |
| `flutter_bloc` | State management |
| SQLite (`sqflite`) | Local database |
| `sqflite_common_ffi_web` | SQLite support for web |
| Dio | HTTP client |
| Shared Preferences | Local preferences and sync metadata |
| Flutter Secure Storage | Session token storage |
| `connectivity_plus` | Network connectivity monitoring |
| `geolocator` | GPS location |
| `image_picker` | Camera and gallery access |

## 🗂️ Project Structure

```text
field_notes/
│
├── lib/
│   ├── app.dart
│   │
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── config.dart
│   │   ├── di.dart
│   │   ├── permissions.dart
│   │   └── theme.dart
│   │
│   ├── data/
│   │   ├── local/
│   │   │   ├── local_db.dart
│   │   │   └── photo_storage.dart
│   │   │
│   │   ├── remote/
│   │   │   ├── api_client.dart
│   │   │   └── mappers.dart
│   │   │
│   │   ├── repositories/
│   │   │   └── repositories_impl.dart
│   │   │
│   │   ├── sync/
│   │   │   ├── connectivity_service.dart
│   │   │   └── sync_service.dart
│   │   │
│   │   └── session_store.dart
│   │
│   ├── domain/
│   │   ├── entities.dart
│   │   └── repositories.dart
│   │
│   └── presentation/
│       ├── blocs/
│       ├── pages/
│       └── widgets/
│
├── test/
│   └── widget_test.dart
│
├── android/
│
├── web/
│
├── pubspec.yaml
│
└── README.md
```

### 📂 Directory Overview

| Directory / File | Description |
|---|---|
| `lib/app.dart` | App widget, providers, and authentication navigation |
| `lib/main.dart` | Application startup and dependency setup |
| `lib/core/` | Configuration, dependency injection, permissions, and theme |
| `lib/data/local/` | SQLite database and local photo storage |
| `lib/data/remote/` | API client and data mapping |
| `lib/data/repositories/` | Repository implementations |
| `lib/data/sync/` | Connectivity monitoring and data synchronization |
| `lib/data/session_store.dart` | Session token, user, and sync cursor storage |
| `lib/domain/` | Domain entities and repository interfaces |
| `lib/presentation/blocs/` | Authentication, notes, sites, customers, and sync state |
| `lib/presentation/pages/` | Application screens and forms |
| `lib/presentation/widgets/` | Reusable UI components |
| `test/` | Application tests |
| `android/` | Android-specific configuration |
| `web/` | Web platform files |

---

<div align="center">

**Built with Flutter 💙**

</div>
