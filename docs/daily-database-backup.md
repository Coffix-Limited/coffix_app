# Daily Database Backup Plan

## Overview

Automate daily backups of our Firestore database using a scheduled Cloud Function (cron job via Cloud Scheduler) and store the exports in a Google Cloud Storage bucket.

---

## Architecture

```
Cloud Scheduler (daily cron)
        │
        ▼
Firebase Cloud Function (HTTP trigger)
        │
        ▼
Firestore Export API
        │
        ▼
Google Cloud Storage Bucket (coffix-db-backups)
```

---

## Storage Bucket

- **Bucket name:** `coffix-db-backups`
- **Location:** Same region as Firestore (e.g., `australia-southeast1`)
- **Storage class:** `NEARLINE` (cost-effective for infrequent access)
- **Retention policy:** 30 days (auto-delete old backups)
- **Folder structure:**
  ```
  gs://coffix-db-backups/
  └── firestore/
      └── YYYY-MM-DD/
          └── <export files>
  ```

---

## Cloud Scheduler Job

- **Schedule:** `0 2 * * *` (daily at 2:00 AM NZST / UTC+12)
- **Target:** Pub/Sub topic or HTTP endpoint of the backup Cloud Function
- **Timezone:** `Pacific/Auckland`

---

## Cloud Function

**Location:** `functions/src/backup/`

### `triggerFirestoreExport.ts`

```typescript
import * as functions from "firebase-functions";
import { google } from "googleapis";

export const dailyFirestoreBackup = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("Pacific/Auckland")
  .onRun(async () => {
    const projectId = process.env.GCLOUD_PROJECT;
    const bucket = `gs://coffix-db-backups/firestore/${new Date().toISOString().split("T")[0]}`;

    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/datastore"],
    });

    const client = await auth.getClient();
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default):exportDocuments`;

    await client.request({
      url,
      method: "POST",
      data: { outputUriPrefix: bucket },
    });

    console.log(`Backup triggered → ${bucket}`);
  });
```

---

## IAM Permissions

The Firebase/Cloud Function service account needs:

| Role | Purpose |
|------|---------|
| `roles/datastore.importExportAdmin` | Trigger Firestore exports |
| `roles/storage.objectAdmin` | Write to the backup bucket |

Apply via gcloud:
```bash
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:<PROJECT_ID>@appspot.gserviceaccount.com" \
  --role="roles/datastore.importExportAdmin"

gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:<PROJECT_ID>@appspot.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

---

## Backup Retention

Configure a lifecycle rule on the bucket to auto-delete exports older than 30 days:

```json
{
  "rule": [
    {
      "action": { "type": "Delete" },
      "condition": { "age": 30 }
    }
  ]
}
```

Apply:
```bash
gsutil lifecycle set lifecycle.json gs://coffix-db-backups
```

---

## Restore Process

To restore from a backup:

```bash
gcloud firestore import gs://coffix-db-backups/firestore/YYYY-MM-DD/
```

> Restoring overwrites existing data. Always test restores in the `dev` project first.

---

## Monitoring & Alerts

- Enable **Cloud Logging** on the backup function to capture success/failure logs.
- Set up a **Cloud Monitoring alert** if the function errors or doesn't execute within a 25-hour window.
- Optionally send a Slack/email notification on failure using the existing email system (`functions/src/email`).

---

## Environments

| Environment | Project | Backup Bucket | Schedule |
|-------------|---------|---------------|----------|
| `prod` | `coffix-prod` | `coffix-db-backups-prod` | `0 2 * * *` |
| `dev` | `coffix-dev` | `coffix-db-backups-dev` | On-demand only |

Backups are **only automated for `prod`**. Dev backups can be triggered manually.

---

## Implementation Checklist

- [ ] Create GCS bucket `coffix-db-backups-prod`
- [ ] Apply 30-day lifecycle rule to bucket
- [ ] Grant IAM roles to the App Engine service account
- [ ] Implement `dailyFirestoreBackup` Cloud Function
- [ ] Deploy and verify first manual trigger
- [ ] Confirm export appears in bucket
- [ ] Enable Cloud Monitoring alert for function failures
