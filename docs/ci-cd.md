# CI/CD Overview — Coffix

This document is the high-level map. For per-workflow detail, see the linked reference docs.

---

## Branch → Environment

| Branch | Environment | Firebase Project |
|--------|-------------|-----------------|
| `dev`  | dev         | `coffix-app-dev`  |
| `main` | prod        | `coffix-app-prod` |

All automation is branch-driven. Push to `dev` → dev environment. Push to `main` → prod environment.

---

## Workflow Files

Five workflow files live under `.github/workflows/`. Each has a single responsibility.

```
.github/workflows/
├── ci.yml                       # Quality gate — runs on every push/PR
├── deploy-dev-functions.yml     # Functions deploy → coffix-app-dev (push to dev)
├── deploy-prod-functions.yml    # Functions deploy → coffix-app-prod (push to main)
├── deploy-dev.yml               # App distribution — dev (planned)
└── deploy-prod.yml              # App distribution — prod (planned)
```

> `deploy-functions.yml` has been removed. Functions deployment is now split by environment.

### `ci.yml` — CI Quality Gate

**Triggers:** push or PR to `dev` or `main`

Runs static analysis, tests, and build verification before any code is merged or deployed. Does **not** produce release artifacts — build jobs here are compile checks only.

| Job | What it does |
|-----|-------------|
| `analyze` | `flutter analyze --fatal-warnings` |
| `test` | `flutter test --coverage` |
| `build_android_dev` | Debug APK, `dev` flavor — all branches |
| `build_android_prod` | Release APK, `prod` flavor — `main` only |

This workflow must pass before a deploy workflow is meaningful. Set it as a required status check on both `dev` and `main` branches.

> See [`docs/ci-cd-ci-yml.md`](./ci-cd-ci-yml.md) for full job config and key decisions.

---

### `deploy-dev-functions.yml` — Functions Deploy (Dev)

**Triggers:** push to `dev` (path-filtered to `functions/`), or manual `workflow_dispatch`

Deploys TypeScript Cloud Functions to `coffix-app-dev`. TypeScript is type-checked before deployment. Runs in the `dev` GitHub Environment so secrets are isolated from prod.

> See [`docs/ci-cd-firebase-functions.md`](./ci-cd-firebase-functions.md) for setup, service account config, and manual deploy steps.

---

### `deploy-prod-functions.yml` — Functions Deploy (Prod)

**Triggers:** push to `main` (path-filtered to `functions/`), or manual `workflow_dispatch`

Deploys TypeScript Cloud Functions to `coffix-app-prod`. Concurrency is set to `cancel-in-progress: false` to protect in-flight production deployments. Runs in the `prod` GitHub Environment.

> See [`docs/ci-cd-firebase-functions.md`](./ci-cd-firebase-functions.md) for setup, service account config, and manual deploy steps.

---

### `deploy-dev.yml` — App Distribution (Dev) _(planned)_

**Triggers:** push to `dev` (after CI passes)

Will build and distribute the `dev` flavor APK/IPA to internal testers. Intended distribution targets:
- **Android:** Firebase App Distribution
- **iOS:** TestFlight

> See [`docs/ci-cd-fastlane.md`](./ci-cd-fastlane.md) for the Fastlane lanes (`beta_dev`) and GitHub Actions job config.

---

### `deploy-prod.yml` — App Distribution (Prod) _(planned)_

**Triggers:** push to `main` (after CI passes)

Will build and release the `prod` flavor to app stores. Intended targets:
- **Android:** Google Play internal track (AAB via Fastlane)
- **iOS:** App Store via `upload_to_app_store`

> See [`docs/ci-cd-fastlane.md`](./ci-cd-fastlane.md) for the Fastlane lanes (`release_prod`) and GitHub Actions job config.

---

## Full Pipeline Flow

```
PR / push to dev or main
        │
        ▼
   ci.yml  ──── analyze ── test ── build-check
        │              (must pass)
        │
        ├── push to dev ──► deploy-dev-functions.yml   → coffix-app-dev (if functions/ changed)
        │                ──► deploy-dev.yml (planned)  → TestFlight / Firebase App Dist
        │
        └── push to main ──► deploy-prod-functions.yml  → coffix-app-prod (if functions/ changed)
                          ──► deploy-prod.yml (planned)  → App Store / Google Play
```

---

## Secrets Reference

### `ci.yml`

| Secret | Used by |
|--------|---------|
| `ENV_DEV` | Build jobs — writes `.env.dev` |
| `ENV_PROD` | Build jobs — writes `.env` |
| `FIREBASE_OPTIONS_DEV` | Build jobs — writes `firebase_options_dev.dart` |
| `FIREBASE_OPTIONS_PROD` | Build jobs — writes `firebase_options_prod.dart` |
| `GOOGLE_SERVICES_JSON_DEV` | Android dev build — writes `google-services.json` |
| `GOOGLE_SERVICES_JSON_PROD` | Android prod build — writes `google-services.json` |

### `deploy-dev-functions.yml` (GitHub Environment: `dev`)

| Secret | Value |
|--------|-------|
| `FUNCTIONS_ENV_DEV` | `.env.development` file content |
| `FIREBASE_SERVICE_ACCOUNT_DEV` | GCP service account JSON for `coffix-app-dev` |

### `deploy-prod-functions.yml` (GitHub Environment: `prod`)

| Secret | Value |
|--------|-------|
| `FUNCTIONS_ENV_PROD` | `.env` file content |
| `FIREBASE_SERVICE_ACCOUNT_PROD` | GCP service account JSON for `coffix-app-prod` |

### `deploy-dev.yml` / `deploy-prod.yml` (planned)

| Secret | Platform | Description |
|--------|----------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Android | Base64-encoded release keystore |
| `ANDROID_STORE_PASSWORD` | Android | Keystore password |
| `ANDROID_KEY_ALIAS` | Android | Key alias |
| `ANDROID_KEY_PASSWORD` | Android | Key password |
| `FIREBASE_APP_ID_DEV` | Android (dev) | Firebase App ID for dev app |
| `FIREBASE_TOKEN` | Android (dev) | Firebase CLI token (`firebase login:ci`) |
| `GOOGLE_PLAY_JSON_KEY` | Android (prod) | Google Play service account JSON |
| `MATCH_PASSWORD` | iOS | Fastlane match encryption password |
| `MATCH_GIT_BASIC_AUTHORIZATION` | iOS | Base64 `username:token` for certs repo |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | iOS | ASC API key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | iOS | ASC issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | iOS | `.p8` key file content |

---

## Adding a New Step

To extend the pipeline:

1. Pick the workflow file that matches the responsibility (CI check → `ci.yml`, Functions dev → `deploy-dev-functions.yml`, Functions prod → `deploy-prod-functions.yml`, app distribution → `deploy-dev.yml` / `deploy-prod.yml`).
2. Add a new job or step.
3. Gate it on the correct branch with `if: github.ref == 'refs/heads/dev'` (or `main`), or add a `workflow_dispatch` input option.
4. Add any new secrets to the matching GitHub Environment (`dev` or `prod`), not at the repository level.
