# CI Workflow (`ci.yml`) — Coffix Flutter App

## Purpose

`ci.yml` is the **pull request / branch quality gate**. It runs on every push to `dev` or `main` (and on PRs targeting those branches) to catch regressions before code is merged or deployed. It does **not** build release artifacts — that is handled by the deploy workflows.

---

## Trigger Strategy

```yaml
on:
  push:
    branches: [dev, main]
  pull_request:
    branches: [dev, main]
```

Run on every push and every PR targeting `dev` or `main`. No path filters — the whole Flutter app must stay green at all times.

---

## Job Overview

| Job | Runner | What it does |
|-----|--------|--------------|
| `analyze` | `ubuntu-latest` | `flutter analyze` — static analysis via `flutter_lints` |
| `test` | `ubuntu-latest` | `flutter test` — all unit + widget tests |
| `build-check-android` | `ubuntu-latest` | `flutter build apk --debug` — verifies Android compiles |
| `build-check-ios` | `macos-14` | `flutter build ios --no-codesign` — verifies iOS compiles |
| `functions-typecheck` | `ubuntu-latest` | `tsc --noEmit` on Firebase Functions — TypeScript contracts |

> **iOS build check** must run on a macOS runner — Xcode toolchain is required even for `--no-codesign`.

---

## Full `ci.yml`

```yaml
name: CI

on:
  push:
    branches: [dev, main]
  pull_request:
    branches: [dev, main]

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze:
    name: Flutter Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --fatal-infos

  test:
    name: Flutter Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
        continue-on-error: true  # non-blocking; coverage uploads are best-effort

  build-check-android:
    name: Android Build Check
    runs-on: ubuntu-latest
    needs: [analyze, test]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Write dev .env
        run: echo "BASE_URL=https://placeholder.dev" > .env.dev

      - name: Build APK (debug, dev flavor)
        run: flutter build apk --debug --flavor dev -t lib/main_dev.dart

  build-check-ios:
    name: iOS Build Check
    runs-on: macos-14
    needs: [analyze, test]
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Install CocoaPods dependencies
        run: cd ios && pod install

      - name: Write dev .env
        run: echo "BASE_URL=https://placeholder.dev" > .env.dev

      - name: Build iOS (no-codesign, dev flavor)
        run: flutter build ios --no-codesign --flavor dev -t lib/main_dev.dart

  functions-typecheck:
    name: Functions TypeScript Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: npm
          cache-dependency-path: functions/package-lock.json

      - name: Install dependencies
        run: npm ci --prefix functions

      - name: Type-check
        run: npx --prefix functions tsc --noEmit
```

---

## Key Decisions Explained

### `cancel-in-progress: true`
Cancels an older run on the same branch when a new commit is pushed. Keeps queue short and saves runner minutes.

### `needs: [analyze, test]`
Build checks only run if static analysis and tests pass. Avoids wasting macOS runner time (expensive) on broken code.

### `--fatal-infos` on analyze
Treats Flutter info-level hints as errors. Keeps the codebase lint-clean over time.

### `--no-codesign` on iOS
Allows the iOS build to compile without a real Apple certificate. Catches Xcode/plugin/native errors without needing secrets on every PR.

### `.env.dev` placeholder
The app reads environment variables at build time via `flutter_dotenv`. CI injects a minimal placeholder so the build resolves the file without exposing real secrets.

---

## GitHub Secrets Required for CI

CI itself requires **no secrets** for analyze/test/iOS no-codesign jobs. If you later add integration tests against real Firebase, add:

| Secret | Used by |
|--------|---------|
| `GOOGLE_SERVICES_JSON_DEV` | Android build (if release flavor is tested) |
| `CODECOV_TOKEN` | Coverage upload (optional) |

All deploy secrets (`MATCH_PASSWORD`, `ANDROID_KEYSTORE_BASE64`, etc.) live only in the deploy workflows — see `docs/ci-cd-fastlane.md`.

---

## Relationship to Other Workflows

```
PR / push
    │
    ▼
ci.yml  ──────────────────────────────── quality gate (this file)
    │
    ▼ (merge to dev)
deploy-functions.yml  ─────────────────── deploy Firebase Functions to dev
ci-dev.yml (fastlane)  ────────────────── build + upload iOS/Android dev builds
    │
    ▼ (merge to main)
deploy-functions.yml  ─────────────────── deploy Firebase Functions to prod
ci-prod.yml (fastlane)  ───────────────── build + upload iOS/Android prod builds
```

See `docs/ci-cd-fastlane.md` for the deploy workflows and `docs/ci-cd-firebase-functions.md` for the Functions deploy details.

---

## Checklist Before Enabling

- [ ] Confirm `flutter-version` matches the version in `.tool-versions` or your local SDK
- [ ] Verify `lib/main_dev.dart` and `--flavor dev` build locally with `flutter build apk --debug --flavor dev -t lib/main_dev.dart`
- [ ] Confirm `flutter test` passes locally with no skipped tests hiding failures
- [ ] Confirm `npm ci --prefix functions && npx --prefix functions tsc --noEmit` passes locally
- [ ] Add `ci.yml` to `.github/workflows/` and push to a feature branch to observe the first run
- [ ] Set branch protection on `dev` and `main` requiring this workflow to pass before merge
