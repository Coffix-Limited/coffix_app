# CI/CD: Firebase Cloud Functions

## Overview

This document describes the CI/CD setup for deploying the Coffix backend (Firebase Cloud Functions) via **GitHub Actions**.

### Branch Strategy

| Branch | Firebase Project | Trigger |
|--------|-----------------|---------|
| `dev`  | `coffix-app-dev`  | Push to `dev` / manual dispatch |
| `main` | `coffix-app-prod` | Push to `main` / manual dispatch |

The workflow only runs when relevant files change:

```
functions/**
firebase.json
.firebaserc
.github/workflows/deploy-functions.yml
```

### Workflow File

`.github/workflows/deploy-functions.yml`

Two jobs: `deploy_dev` and `deploy_prod`. Both follow the same step sequence but target different Firebase projects and use separate GitHub Environments for secret isolation.

A concurrency guard (`cancel-in-progress: false`) prevents a second push from cancelling an in-flight deployment, which could leave functions in a partially-updated state.

---

## How It Works

Each job runs these steps in order:

1. **Checkout** — `actions/checkout@v4`
2. **Node 24 setup** — `actions/setup-node@v4` with npm cache keyed on `functions/package-lock.json`
3. **Install dependencies** — `npm ci --prefix functions` (reproducible, fails on lockfile mismatch)
4. **Type-check** — `npx --prefix functions tsc --noEmit` — fails fast on type errors before touching secrets or Firebase
5. **Install Firebase CLI** — `npm i -g firebase-tools`
6. **Write `.env` file** — secret written to `functions/.env.development` (dev) or `functions/.env` (prod)
7. **Write service account key** — JSON written to `$RUNNER_TEMP/firebase-sa.json`, path set in `GOOGLE_APPLICATION_CREDENTIALS`
8. **Deploy** — `firebase deploy --only functions --project <project> --non-interactive`
   - The `predeploy` hook in `firebase.json` runs `tsc` automatically, compiling TypeScript to `lib/` before upload

---

## Generating the Service Account JSON

Do this once for each Firebase project (`coffix-app-dev` and `coffix-app-prod`).

1. Go to [console.cloud.google.com](https://console.cloud.google.com) and select the project
2. Navigate to **IAM & Admin → Service Accounts**
3. Click **Create Service Account**
   - Name: `github-actions-deploy`
   - Description: "Used by GitHub Actions to deploy Firebase Functions"
4. Assign these roles:
   - `Cloud Functions Developer`
   - `Firebase Admin`
   - `Service Account User`
   - `Cloud Build Editor` (required for Cloud Functions v2, which deploys via Cloud Build)
5. Click **Done**
6. Click the new service account → **Keys** tab → **Add Key → Create new key → JSON**
7. A `.json` file downloads — copy its full raw contents into the corresponding GitHub secret (do not base64-encode it)

---

## GitHub Secrets Reference

Add secrets under **Settings → Environments → dev (or prod) → Add secret**, not at the repository level. This keeps dev and prod credentials isolated.

| Secret | Environment | Value |
|--------|-------------|-------|
| `FUNCTIONS_ENV_DEV` | dev | Full `.env.development` file content for dev (see `functions/env.example`) |
| `FUNCTIONS_ENV_PROD` | prod | Full `.env` file content for prod (see `functions/env.example`) |
| `FIREBASE_SERVICE_ACCOUNT_DEV` | dev | Raw service account JSON for `coffix-app-dev` |
| `FIREBASE_SERVICE_ACCOUNT_PROD` | prod | Raw service account JSON for `coffix-app-prod` |

To create the environments first: **Settings → Environments → New environment** → name it `dev`, then repeat for `prod`.

---

## Environment File Notes

`functions/src/index.ts` loads the env file based on the `GCLOUD_PROJECT` environment variable set by Firebase at runtime:

```typescript
const envFile = project.includes("dev") ? ".env.development" : ".env";
dotenv.config({ path: path.join(__dirname, "..", envFile), override: true });
```

This means:

| Deployed to | File loaded at runtime |
|-------------|----------------------|
| `coffix-app-dev` | `functions/.env.development` |
| `coffix-app-prod` | `functions/.env` |

The workflow matches this: the `deploy_dev` job writes `FUNCTIONS_ENV_DEV` to `functions/.env.development`, and the `deploy_prod` job writes `FUNCTIONS_ENV_PROD` to `functions/.env`. Both files are included in the deployment package uploaded to Cloud Functions.

Use `functions/env.example` as the template for populating both secrets. The secret value should be a plain multi-line `.env` file:

```
RESEND_API_KEY=re_xxxx
WINDCAVE_API_USERNAME=xxxx
WINDCAVE_API_KEY=xxxx
...
```

---

## Manual Deployment

To trigger a deploy without pushing code:

1. Go to **Actions** tab in GitHub
2. Select **Deploy API (Firebase Functions)**
3. Click **Run workflow**
4. Choose `dev` or `prod` from the dropdown
5. Click **Run workflow**

---

## Local Deployment

```bash
# Install dependencies
npm --prefix functions ci

# Deploy to dev
npm --prefix functions run deploy:dev

# Deploy to prod
npm --prefix functions run deploy:prod
```

---

## Checklist Before First Run

- [ ] Create GitHub Environment `dev` (Settings → Environments → New environment)
- [ ] Create GitHub Environment `prod` (Settings → Environments → New environment)
- [ ] Generate service account for `coffix-app-dev`, assign required roles, download JSON key
- [ ] Add raw JSON key as `FIREBASE_SERVICE_ACCOUNT_DEV` in the `dev` environment
- [ ] Generate service account for `coffix-app-prod`, assign required roles, download JSON key
- [ ] Add raw JSON key as `FIREBASE_SERVICE_ACCOUNT_PROD` in the `prod` environment
- [ ] Fill in `FUNCTIONS_ENV_DEV` using `functions/env.example` as the template (dev values)
- [ ] Fill in `FUNCTIONS_ENV_PROD` using `functions/env.example` as the template (prod values)
- [ ] Confirm `functions/package-lock.json` is committed (it is)
- [ ] Confirm Cloud Functions API is enabled on both GCP projects
- [ ] Confirm Cloud Build API is enabled on both GCP projects (required for v2 functions)
- [ ] Test with a manual `workflow_dispatch` targeting `dev` before relying on push-triggered deploys
- [ ] Verify the deployed function responds at the `/hello-world` health check endpoint
