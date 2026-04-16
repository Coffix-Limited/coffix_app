# Firestore Rules & Indexes — Fetch and Deploy

Projects:
- **dev** → `coffix-app-dev`
- **prod** → `coffix-app-prod` (database: `coffix-prod-australia`)

Local files managed by this repo:
- `firestore.rules`
- `firestore.indexes.json`

---

## 1. Pull latest indexes from Firebase

The Firebase CLI supports pulling **indexes** but not rules via CLI.

```bash
# Dev
firebase firestore:indexes --project coffix-app-dev > firestore.indexes.json

# Prod (named database)
firebase firestore:indexes --project coffix-app-prod --database coffix-prod-australia > firestore.indexes.json
```

## 2. Pull latest rules from Firebase

There is no `firebase` CLI command to download deployed rules. Use one of these approaches:

**Option A — Firebase Console (easiest)**
1. Open [Firebase Console](https://console.firebase.google.com) → select project → Firestore → **Rules** tab.
2. Copy the rule content and paste it into `firestore.rules`.

**Option B — Security Rules REST API**

```bash
PROJECT=coffix-app-prod
TOKEN=$(gcloud auth print-access-token)

curl -s \
  "https://firebaserules.googleapis.com/v1/projects/${PROJECT}/rulesets" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.rulesets[0].name'

# Then fetch the latest ruleset by name
RULESET=<name from above>
curl -s \
  "https://firebaserules.googleapis.com/v1/${RULESET}" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.source.files[0].content' > firestore.rules
```

---

## 3. Deploy rules and indexes to prod

After editing locally (or after pulling to sync), deploy to prod:

```bash
firebase use coffix-app-prod

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only Firestore indexes
firebase deploy --only firestore:indexes

# Deploy both at once
firebase deploy --only firestore
```

The `firebase.json` already points to the correct files and database:

```json
"firestore": {
  "database": "coffix-prod-australia",
  "rules": "firestore.rules",
  "indexes": "firestore.indexes.json"
}
```

---

## 4. Typical workflow

1. Pull the latest indexes (`firestore:indexes`) and rules (Console or REST API).
2. Make local edits to `firestore.rules` or `firestore.indexes.json`.
3. Deploy to prod with `firebase deploy --only firestore`.
4. Commit the updated files so the repo stays in sync.

---

## Tips

- Switch between projects with `firebase use <project-id>` or use `--project` flag inline.
- `firebase projects:list` shows all projects you have access to.
- Index builds run asynchronously; check status in the Firebase Console → Firestore → Indexes.
