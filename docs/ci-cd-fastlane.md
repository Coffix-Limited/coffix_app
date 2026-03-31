# CI/CD with Fastlane — Coffix Flutter App

## Overview

This document describes the CI/CD setup for the Coffix Flutter app using **Fastlane** and **GitHub Actions**. It covers both **iOS** and **Android** for the two app flavors: `dev` and `prod`.

### Branch Strategy

| Branch | Flavor | Distribution Target |
|--------|--------|---------------------|
| `dev`  | `dev`  | TestFlight (iOS) / Firebase App Distribution (Android) |
| `main` | `prod` | App Store (iOS) / Google Play (Android) |

### App Identifiers

| Platform | Flavor | Identifier |
|----------|--------|------------|
| iOS      | dev    | `com.coffix.dev` |
| iOS      | prod   | `com.coffix.app` |
| Android  | dev    | `com.coffix.dev.app` |
| Android  | prod   | `com.coffix.app` |

---

## Prerequisites

### Local Setup

1. **Ruby** (recommended via `rbenv` or `rvm`)
2. **Bundler**: `gem install bundler`
3. **Fastlane**: installed via `Gemfile` (do not install globally)
4. **Xcode** with valid Apple Developer account
5. **Android Studio** with a generated release keystore
6. **Flutter SDK** on the CI runner

### Apple Developer Account

- App Store Connect API key (Key ID, Issuer ID, `.p8` file)
- A **private git repo** to store certificates/profiles via `match`
- App records created in App Store Connect for both `com.coffix.dev` and `com.coffix.app`

### Google Play Console

- A service account JSON key with release manager permissions
- App records created for both `com.coffix.dev.app` and `com.coffix.app`

---

## Repository Structure

Add the following to the project root:

```
coffix_app/
├── Gemfile                         # Ruby gem dependencies
├── Gemfile.lock
├── fastlane/                       # iOS Fastlane config
│   ├── Appfile
│   ├── Fastfile
│   └── Matchfile
├── android/
│   └── fastlane/                   # Android Fastlane config
│       ├── Appfile
│       └── Fastfile
└── .github/
    └── workflows/
        ├── ci-dev.yml              # Dev pipeline (push to dev)
        └── ci-prod.yml             # Prod pipeline (push to main)
```

---

## Gemfile

```ruby
# Gemfile
source "https://rubygems.org"

gem "fastlane"
gem "cocoapods"
```

Run `bundle install` to generate `Gemfile.lock`. Commit both files.

---

## iOS Fastlane Setup

### `fastlane/Appfile`

```ruby
app_identifier ["com.coffix.dev", "com.coffix.app"]
apple_id "your-apple-id@email.com"
itc_team_id "YOUR_ITC_TEAM_ID"
team_id "YOUR_TEAM_ID"
```

### `fastlane/Matchfile`

```ruby
git_url "https://github.com/your-org/certificates-repo"
storage_mode "git"
type "appstore"
app_identifier ["com.coffix.dev", "com.coffix.app"]
username "your-apple-id@email.com"
```

### `fastlane/Fastfile` (iOS)

```ruby
default_platform(:ios)

platform :ios do

  desc "Sync certificates and provisioning profiles"
  lane :sync_signing do |options|
    match(
      type: options[:type] || "appstore",
      app_identifier: options[:app_identifier],
      readonly: is_ci
    )
  end

  desc "Build and upload Dev build to TestFlight"
  lane :beta_dev do
    sync_signing(type: "appstore", app_identifier: "com.coffix.dev")

    build_app(
      workspace: "ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release-dev",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.coffix.dev" => "match AppStore com.coffix.dev"
        }
      },
      output_directory: "build/ios",
      output_name: "CoffixDev.ipa"
    )

    upload_to_testflight(
      app_identifier: "com.coffix.dev",
      skip_waiting_for_build_processing: true
    )
  end

  desc "Build and release Prod build to App Store"
  lane :release_prod do
    sync_signing(type: "appstore", app_identifier: "com.coffix.app")

    build_app(
      workspace: "ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release-prod",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.coffix.app" => "match AppStore com.coffix.app"
        }
      },
      output_directory: "build/ios",
      output_name: "Coffix.ipa"
    )

    upload_to_app_store(
      app_identifier: "com.coffix.app",
      skip_metadata: true,
      skip_screenshots: true,
      submit_for_review: false
    )
  end

end
```

---

## Android Fastlane Setup

### Android Signing — Required Fix

> **Current issue:** `android/app/build.gradle.kts` uses `signingConfigs.getByName("debug")` for release builds. This must be fixed before CI can sign production APKs/AABs.

Update `android/app/build.gradle.kts` to read signing from environment variables:

```kotlin
android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH") ?: "keystore.jks")
            storePassword = System.getenv("ANDROID_STORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            isShrinkResources = false
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

The keystore file is **never committed** to the repository. On CI it is decoded from a base64-encoded GitHub Secret.

### `android/fastlane/Appfile`

```ruby
json_key_file ENV["GOOGLE_PLAY_JSON_KEY_PATH"]
package_name "com.coffix.app"
```

### `android/fastlane/Fastfile`

```ruby
default_platform(:android)

platform :android do

  desc "Read version from pubspec.yaml"
  private_lane :get_version do
    pubspec = File.read("../../pubspec.yaml")
    version_line = pubspec.match(/^version:\s*(.+)/)
    raise "Version not found in pubspec.yaml" unless version_line
    parts = version_line[1].strip.split("+")
    { name: parts[0], code: parts[1].to_i }
  end

  desc "Decode keystore from base64 env var"
  private_lane :setup_keystore do
    keystore_path = "/tmp/release.keystore"
    File.open(keystore_path, "wb") do |f|
      f.write(Base64.decode64(ENV["ANDROID_KEYSTORE_BASE64"]))
    end
    ENV["ANDROID_KEYSTORE_PATH"] = keystore_path
    keystore_path
  end

  desc "Build and distribute Dev AAB to Firebase App Distribution"
  lane :beta_dev do
    setup_keystore

    version = get_version
    UI.message "Building dev v#{version[:name]}+#{version[:code]}"

    gradle(
      task: "bundle",
      flavor: "dev",
      build_type: "Release",
      project_dir: "android/",
      properties: {
        "android.injected.version.code" => version[:code],
        "android.injected.version.name" => version[:name]
      }
    )

    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_DEV"],
      firebase_cli_token: ENV["FIREBASE_TOKEN"],
      groups: "internal-testers",
      release_notes: "Dev build #{version[:name]}+#{version[:code]}"
    )
  end

  desc "Build and release Prod AAB to Google Play (internal track)"
  lane :release_prod do
    setup_keystore

    version = get_version
    UI.message "Building prod v#{version[:name]}+#{version[:code]}"

    gradle(
      task: "bundle",
      flavor: "prod",
      build_type: "Release",
      project_dir: "android/",
      properties: {
        "android.injected.version.code" => version[:code],
        "android.injected.version.name" => version[:name]
      }
    )

    upload_to_play_store(
      package_name: "com.coffix.app",
      track: "internal",
      aab: "android/app/build/outputs/bundle/prodRelease/app-prod-release.aab",
      json_key: ENV["GOOGLE_PLAY_JSON_KEY_PATH"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

end
```

---

## GitHub Actions Workflows

### `.github/workflows/ci-dev.yml`

```yaml
name: CI — Dev

on:
  push:
    branches:
      - dev

jobs:
  build-ios-dev:
    name: Build & Upload iOS Dev
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Install Ruby dependencies
        run: bundle install

      - name: Install pods
        run: cd ios && pod install

      - name: Set up App Store Connect API key
        run: |
          echo "${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}" > /tmp/api_key.p8

      - name: Run Fastlane beta_dev
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
          APP_STORE_CONNECT_API_KEY_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_KEY_ID }}
          APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_KEY_FILEPATH: /tmp/api_key.p8
        run: bundle exec fastlane ios beta_dev

  build-android-dev:
    name: Build & Upload Android Dev
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Install Ruby dependencies
        run: bundle install

      - name: Set up Google Play key
        run: echo "${{ secrets.GOOGLE_PLAY_JSON_KEY }}" > /tmp/play_key.json

      - name: Run Fastlane beta_dev
        env:
          ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          ANDROID_STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
          ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          FIREBASE_APP_ID_DEV: ${{ secrets.FIREBASE_APP_ID_DEV }}
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
          GOOGLE_PLAY_JSON_KEY_PATH: /tmp/play_key.json
        run: bundle exec fastlane android beta_dev
```

### `.github/workflows/ci-prod.yml`

```yaml
name: CI — Prod

on:
  push:
    branches:
      - main

jobs:
  build-ios-prod:
    name: Build & Upload iOS Prod
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Install Ruby dependencies
        run: bundle install

      - name: Install pods
        run: cd ios && pod install

      - name: Set up App Store Connect API key
        run: echo "${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}" > /tmp/api_key.p8

      - name: Run Fastlane release_prod
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
          APP_STORE_CONNECT_API_KEY_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_KEY_ID }}
          APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_KEY_FILEPATH: /tmp/api_key.p8
        run: bundle exec fastlane ios release_prod

  build-android-prod:
    name: Build & Upload Android Prod
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Install Ruby dependencies
        run: bundle install

      - name: Set up Google Play key
        run: echo "${{ secrets.GOOGLE_PLAY_JSON_KEY }}" > /tmp/play_key.json

      - name: Run Fastlane release_prod
        env:
          ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          ANDROID_STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
          ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          GOOGLE_PLAY_JSON_KEY_PATH: /tmp/play_key.json
        run: bundle exec fastlane android release_prod
```

---

## GitHub Secrets Reference

Configure these in **Settings → Secrets and variables → Actions** on the GitHub repository.

### iOS

| Secret | Description |
|--------|-------------|
| `MATCH_PASSWORD` | Password to encrypt/decrypt the match certificates git repo |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:token` for access to the certs repo |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | Key ID from App Store Connect API key |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID from App Store Connect |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Contents of the `.p8` private key file |

### Android

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release keystore: `base64 -i release.keystore` |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias within the keystore |
| `ANDROID_KEY_PASSWORD` | Key password |
| `GOOGLE_PLAY_JSON_KEY` | Contents of the Google Play service account JSON file |
| `FIREBASE_APP_ID_DEV` | Firebase App ID for the dev app (from Firebase Console) |
| `FIREBASE_TOKEN` | Firebase CLI token: `firebase login:ci` |

---

## Version Management

Version is sourced from `pubspec.yaml`:

```yaml
version: 1.0.0+20   # name: 1.0.0 | code: 20
```

- The Fastlane `get_version` private lane reads this file and passes it to the build.
- To bump the version before a release, update `pubspec.yaml` manually (or via a script) and commit.
- `versionCode` auto-increments with each commit by convention — increment the number after `+` before each Play Store / TestFlight upload.

---

## Local Testing

Run lanes locally before pushing to CI:

```bash
# Install dependencies
bundle install

# iOS — dev build (TestFlight)
bundle exec fastlane ios beta_dev

# iOS — prod build (App Store)
bundle exec fastlane ios release_prod

# Android — dev build (Firebase App Distribution)
bundle exec fastlane android beta_dev

# Android — prod build (Google Play internal)
bundle exec fastlane android release_prod
```

For Android, export signing env vars before running locally:

```bash
export ANDROID_KEYSTORE_BASE64=$(base64 -i /path/to/release.keystore)
export ANDROID_STORE_PASSWORD=yourpassword
export ANDROID_KEY_ALIAS=youralias
export ANDROID_KEY_PASSWORD=yourkeypassword
export FIREBASE_APP_ID_DEV=1:xxxx:android:xxxx
export FIREBASE_TOKEN=your-firebase-token
```

---

## Checklist Before First Run

- [ ] Create App Store Connect app entries for `com.coffix.dev` and `com.coffix.app`
- [ ] Create Google Play app entries for `com.coffix.dev.app` and `com.coffix.app`
- [ ] Generate release keystore and encode to base64 for secrets
- [ ] Create a private git repo for `match` certificates and run `bundle exec fastlane match init`
- [ ] Run `bundle exec fastlane match appstore` locally to generate initial certificates
- [ ] Update `android/app/build.gradle.kts` with the release signing config (see Android Signing section)
- [ ] Add all GitHub Secrets listed above
- [ ] Test each lane locally before enabling the GitHub Actions workflows
- [ ] Create the `dev` branch in the repository if it doesn't exist
