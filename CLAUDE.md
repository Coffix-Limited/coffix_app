# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run app (dev flavor)
flutter run -t lib/main_dev.dart --flavor dev

# Run app (prod flavor)
flutter run -t lib/main_prod.dart --flavor prod

# Static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file_test.dart

# Regenerate freezed/json_serializable code
dart run build_runner build --delete-conflicting-outputs

# Format code
dart format .

# Firebase Functions
npm --prefix functions ci                   # install dependencies
npm --prefix functions run build            # compile TypeScript
npm --prefix functions run serve            # run emulator locally
```

## Architecture

This is a Flutter app (iOS/Android) backed by Firebase (Firestore, Auth) and Firebase Cloud Functions (TypeScript).

### Flutter App (`lib/`)

Follows **Clean Architecture** with a **feature-first** layout:

```
lib/
├── core/           # App-wide: DI (GetIt), routing (GoRouter), theme, API client, utils
├── data/           # Repository interfaces (abstract classes only)
├── domain/         # Global use cases spanning multiple features
├── features/       # Self-contained feature modules
│   └── <feature>/
│       ├── data/        # Repository implementation (Firestore/API calls)
│       ├── domain/      # Feature-specific use cases
│       ├── logic/       # Cubit/BLoC state management
│       └── presentation/
│           ├── pages/   # Screens
│           └── widgets/ # Feature-specific widgets
├── presentation/   # Atomic Design shared UI (atoms → molecules → organisms)
├── main_dev.dart   # Dev entry point
└── main_prod.dart  # Prod entry point
```

**Key rule:** interfaces live in `lib/data/repositories/`, implementations live in `lib/features/<feature>/data/`.

### Features

`app`, `auth`, `cart`, `credit`, `home`, `layout`, `menu`, `modifier`, `order`, `payment`, `products`, `profile`, `stores`, `transaction`, `wrapper`

### State Management

BLoC/Cubit pattern throughout. All Cubits are registered as lazy singletons in `lib/core/di/service_locator.dart` via GetIt.

### Navigation

GoRouter (`lib/core/routes/app_router.dart`) with Firebase Auth state changes as `refreshListenable`. Unauthenticated users are redirected to `/auth`; authenticated users are redirected away from `/auth`.

The main shell uses `StatefulShellRoute.indexedStack` for the bottom tab navigation (Home, Credit, Menu, Stores, Cart).

### Flavors & Environment

Two flavors: `dev` and `prod`. Each has its own:
- Firebase config (`firebase_options_dev.dart`, `firebase_options_prod.dart`)
- `.env.dev` / `.env` for environment variables (API base URL, etc.)
- Android `google-services.json` under `android/app/src/{dev,prod}/`

### Firebase Functions (`functions/`)

TypeScript. Organized by domain under `functions/src/`:
`api/`, `coffixCredit/`, `otp/`, `transaction/`, `user/`, `webhook/`, `windcave/` (payment gateway integration)

### Coding Conventions

- Dart: `snake_case` files, `PascalCase` classes, `camelCase` methods/variables, 2-space indent
- Keep UI in `presentation`, state in `logic`, data access in `data`
- Run `dart format .` before PRs
- Commit subjects are short and imperative (e.g. `implement payment`, `fix cart total`)
- Secrets go in `.env`/`.env.dev`/`functions/.env` — never in source code
