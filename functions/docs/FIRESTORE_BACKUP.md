# Firestore Daily Backup

## The problem

> "We want a backup of all our data. Can the system export Firestore every day, zip it,
> and email a download link to IT@coffix.co.nz?"

There is no off-Firestore copy of the data today. If a collection is corrupted or deleted
(bad migration, bad cron, human error) there is nothing to restore from. The client wants
a **daily, self-serve backup** delivered to **IT@coffix.co.nz** as a downloadable link.

## The solution at a glance

A daily job (00:00 NZ time):

1. **Exports** all Firestore data with the managed export API into a dated folder in a
   Cloud Storage bucket.
2. **Zips** that exported folder into a single `<date>.zip` object in the same bucket.
3. Creates a **signed download URL** for the zip.
4. **Emails** that link to `IT@coffix.co.nz` via **Resend**.

We reuse the repo's existing cron pattern: HTTP endpoints guarded by an `x-cron-secret`
header, triggered by **Google Cloud Scheduler**. This is exactly how log cleanup and
credit expiry already work — see `POST /credit/expire`
(`functions/src/coffixCredit/router.ts:179`) and `functions/docs/LOG_DELETION.md`. We do
**not** introduce a new `onSchedule` function, to stay consistent with the codebase.

### Two important realities to design around

1. **The managed export is not a zip and is not instant.** The Firestore Admin
   `exportDocuments` API writes a *folder* of metadata + LevelDB files into a GCS bucket,
   and the operation is **long-running/async** — it can finish after the HTTP request has
   already returned. So "export" and "zip + email" are **two phases**, not one synchronous
   call. We kick off the export in phase 1 and zip/email in phase 2 a few minutes later.

2. **Signed URLs are valid for 7 days, not 30.** GCS **V4 signed URLs are capped at 7 days
   (604800s)**. The client originally asked for 30 days; we ship a **7-day** link. Because
   the job runs **daily**, IT always has a fresh 7-day link in their inbox — so there is
   always a current, downloadable backup. (A true 30-day link would require a V2
   service-account-signed URL; see [Caveats](#caveats). Not implemented.)

---

## 1. One-time setup

### 1a. Dependencies

`@google-cloud/storage` is already present transitively via `firebase-admin`, but add it
(and `archiver`) as **explicit** dependencies of `functions/package.json`:

```bash
npm --prefix functions install @google-cloud/storage archiver
npm --prefix functions install -D @types/archiver
```

The Firestore export itself is triggered via the Admin REST endpoint, authenticated with
`google-auth-library` (already pulled in transitively by `firebase-admin`, see §2a), so no
extra dependency is needed for the export call.

### 1b. Constants

Add to `functions/src/constant/constant.ts` (next to the existing
`RESEND_FROM_EMAIL` / `RESEND_BCC_EMAIL`):

```ts
export const BACKUP_RECIPIENT_EMAIL = "IT@coffix.co.nz";
```

The backup bucket name is environment-specific, so read it from a new env var rather than
hardcoding (see §1c).

### 1c. Environment variable — the backup bucket

Add `BACKUP_BUCKET` to `functions/.env.development`, `functions/.env.production`,
`functions/.env.local`, and `functions/env.example`, e.g.:

```
BACKUP_BUCKET=coffix-app-dev-firestore-backups       # in .env.development
BACKUP_BUCKET=coffix-app-prod-firestore-backups      # in .env.production
```

Create those buckets once (same region as the database is cheapest):

```bash
gcloud storage buckets create gs://coffix-app-dev-firestore-backups  --project coffix-app-dev  --location=australia-southeast1
gcloud storage buckets create gs://coffix-app-prod-firestore-backups --project coffix-app-prod --location=australia-southeast1
```

`RESEND_API_KEY` and `CRON_SECRET` already exist in all env files — reuse them.

### 1d. IAM

The Cloud Functions service account (the one whose creds are in `FB_*`) needs:

- **`roles/datastore.importExportAdmin`** — to call `exportDocuments`.
- **`roles/storage.objectAdmin`** on the backup bucket — to write the export, read it
  back for zipping, write the `.zip`, and sign URLs.

```bash
gcloud projects add-iam-policy-binding coffix-app-prod \
  --member="serviceAccount:<FB_CLIENT_EMAIL>" \
  --role="roles/datastore.importExportAdmin"

gcloud storage buckets add-iam-policy-binding gs://coffix-app-prod-firestore-backups \
  --member="serviceAccount:<FB_CLIENT_EMAIL>" \
  --role="roles/storage.objectAdmin"
```

> Signing a V4 URL also requires the **`iam.serviceAccounts.signBlob`** permission
> (role `roles/iam.serviceAccountTokenCreator`) on that service account, unless you sign
> with a downloaded private key. Since the project already loads `FB_PRIVATE_KEY` /
> `FB_CLIENT_EMAIL`, the simplest path is to construct a `Storage` client with those
> credentials so signing happens locally with the key (see §2c).

---

## 2. `BackupService` — `functions/src/backup/service.ts`

Create a plain class following the `LogService` / `EmailService` pattern. Three methods,
one per stage.

### 2a. `startExport()` — kick off the managed export

The database name differs by environment, exactly like
`functions/src/config/firebaseAdmin.ts:16-19`:
dev → `(default)`, prod → `coffix-prod-australia`. Copy that logic.

The export is the Firestore Admin REST call
`POST https://firestore.googleapis.com/v1/projects/{project}/databases/{db}/documents:exportDocuments`.
We authenticate with the same service-account credentials the app already uses, via
`google-auth-library` (a transitive dep of `firebase-admin`).

```ts
import { GoogleAuth } from "google-auth-library";

export class BackupService {
  private readonly project = process.env.FB_PROJECT_ID ?? "";
  private readonly bucket = process.env.BACKUP_BUCKET ?? "";

  // dev -> "(default)", prod -> "coffix-prod-australia" (mirror firebaseAdmin.ts)
  private databaseName(): string {
    const gcloudProject = process.env.GCLOUD_PROJECT ?? "";
    return gcloudProject.includes("dev") ? "(default)" : "coffix-prod-australia";
  }

  // yyyy-MM-dd in NZ time — reuse functions/src/utils/nz_time.ts if it exposes a helper
  private dateStamp(): string {
    return new Date().toLocaleDateString("en-CA", { timeZone: "Pacific/Auckland" });
  }

  // Kicks off the managed export. Returns immediately with the operation name + prefix;
  // does NOT wait for completion (the operation can outlast the request).
  async startExport(): Promise<{ operationName: string; prefix: string; date: string }> {
    const date = this.dateStamp();
    const prefix = `firestore-exports/${date}`;
    const outputUriPrefix = `gs://${this.bucket}/${prefix}`;

    const db = encodeURIComponent(this.databaseName());
    const url =
      `https://firestore.googleapis.com/v1/projects/${this.project}` +
      `/databases/${db}/documents:exportDocuments`;

    const auth = new GoogleAuth({
      credentials: {
        client_email: process.env.FB_CLIENT_EMAIL,
        private_key: process.env.FB_PRIVATE_KEY?.replace(/\\n/g, "\n"),
      },
      scopes: ["https://www.googleapis.com/auth/datastore"],
    });
    const client = await auth.getClient();
    const { data } = await client.request<{ name: string }>({
      url,
      method: "POST",
      data: { outputUriPrefix }, // omit collectionIds => export ALL collections
    });

    return { operationName: data.name, prefix, date };
  }
}
```

> The export writes to `gs://<bucket>/firestore-exports/<date>/...` — a folder of
> `*.export_metadata` + `all_namespaces/.../output-*` files. There is no single file yet;
> that's what phase 2 produces.

### 2b. `zipExport(prefix)` — stream the export folder into one `.zip`

List every object under the export prefix and stream them through `archiver` into an
upload stream pointed at `<prefix>.zip` in the same bucket. Streaming keeps memory flat
even for large exports.

```ts
import { Storage } from "@google-cloud/storage";
import * as archiver from "archiver";

private storageClient(): Storage {
  // Credentials => signBlob happens locally with the key (no extra IAM needed for signing)
  return new Storage({
    projectId: process.env.FB_PROJECT_ID,
    credentials: {
      client_email: process.env.FB_CLIENT_EMAIL,
      private_key: process.env.FB_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    },
  });
}

async zipExport(prefix: string): Promise<string> {
  const storage = this.storageClient();
  const bucket = storage.bucket(this.bucket);

  const [files] = await bucket.getFiles({ prefix: `${prefix}/` });
  const zipPath = `${prefix}.zip`;
  const zipStream = bucket.file(zipPath).createWriteStream({
    metadata: { contentType: "application/zip" },
  });

  const archive = archiver("zip", { zlib: { level: 9 } });
  archive.pipe(zipStream);

  for (const file of files) {
    const name = file.name.substring(`${prefix}/`.length); // path inside the zip
    archive.append(file.createReadStream(), { name });
  }

  await archive.finalize();
  await new Promise<void>((resolve, reject) => {
    zipStream.on("finish", resolve);
    zipStream.on("error", reject);
  });

  return zipPath; // e.g. "firestore-exports/2026-06-23.zip"
}
```

### 2c. `createSignedUrlAndEmail(zipPath, date)` — 7-day link + Resend email

Sign a **7-day V4** URL and email it. The Resend call copies the exact `fetch` shape from
`functions/src/email/service.ts:63-98` (raw API, `RESEND_API_KEY` from env, `from`/`bcc`
from `constant.ts`).

```ts
import {
  BACKUP_RECIPIENT_EMAIL,
  RESEND_FROM_EMAIL,
  RESEND_BCC_EMAIL,
} from "../constant/constant";
import { logger } from "firebase-functions";

private readonly SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

async createSignedUrlAndEmail(zipPath: string, date: string): Promise<void> {
  const storage = this.storageClient();
  const [url] = await storage
    .bucket(this.bucket)
    .file(zipPath)
    .getSignedUrl({
      version: "v4",
      action: "read",
      expires: Date.now() + this.SEVEN_DAYS_MS, // V4 max is 7 days
    });

  const subject = `Coffix Firestore backup — ${date}`;
  const html = `
    <p>The Firestore backup for <strong>${date}</strong> is ready.</p>
    <p><a href="${url}">Download backup (.zip)</a></p>
    <p>This link expires in <strong>7 days</strong>. A fresh link is emailed every day.</p>
  `;

  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  if (!RESEND_API_KEY) throw new Error("RESEND_API_KEY not configured");

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: RESEND_FROM_EMAIL,
      to: [BACKUP_RECIPIENT_EMAIL],
      bcc: [RESEND_BCC_EMAIL],
      subject,
      html,
    }),
  });

  if (!res.ok) {
    const err = await res.json();
    logger.error("Resend API error (backup)", { resendStatus: res.status, resendError: err });
    throw new Error(`Resend ${res.status}: ${JSON.stringify(err)}`);
  }
}
```

---

## 3. The cron endpoints — `functions/src/backup/router.ts`

Two endpoints, because export and zip+email are two phases. Both reuse the
`x-cron-secret` guard copied verbatim from `functions/src/coffixCredit/router.ts:179`.

```ts
import * as express from "express";
import { Request, Response } from "express";
import { logger } from "firebase-functions";
import { BackupService } from "./service";

const router = express.Router();
const backupService = new BackupService();

function requireCronSecret(request: Request, response: Response): boolean {
  const secret = request.headers["x-cron-secret"];
  if (!secret || secret !== process.env.CRON_SECRET) {
    response.status(401).json({ success: false, message: "Unauthorized" });
    return false;
  }
  return true;
}

// Phase 1: start the managed export, return immediately.
router.post("/daily", async (request: Request, response: Response) => {
  if (!requireCronSecret(request, response)) return;
  try {
    const { operationName, prefix } = await backupService.startExport();
    logger.info(`Backup export started: ${operationName}`);
    return response.status(200).json({ success: true, data: { operationName, prefix } });
  } catch (error) {
    logger.error("Error starting backup export:", error);
    return response.status(500).json({ success: false, message: "Internal server error" });
  }
});

// Phase 2: zip the latest export folder and email the signed link.
// Scheduled to run a few minutes after /daily so the export has finished.
router.post("/zip-and-send", async (request: Request, response: Response) => {
  if (!requireCronSecret(request, response)) return;
  try {
    const date = new Date().toLocaleDateString("en-CA", { timeZone: "Pacific/Auckland" });
    const zipPath = await backupService.zipExport(`firestore-exports/${date}`);
    await backupService.createSignedUrlAndEmail(zipPath, date);
    logger.info(`Backup zipped and emailed: ${zipPath}`);
    return response.status(200).json({ success: true, data: { zipPath } });
  } catch (error) {
    logger.error("Error zipping/sending backup:", error);
    return response.status(500).json({ success: false, message: "Internal server error" });
  }
});

export default router;
```

Mount it in `functions/src/api.ts` (one line, next to the other `api.use(...)` calls):

```ts
import backupRouter from "./backup/router";
// ...
api.use("/backup", backupRouter);
```

No other wiring is needed — both routes are exposed through the single `v1` HTTPS function
in `functions/src/index.ts`, which already has a **540s timeout** (enough for the zip
stream of a typical export).

Full paths: `POST v1/backup/daily` and `POST v1/backup/zip-and-send`.

---

## 4. The schedule (you set this up)

> **You wire Cloud Scheduler yourself** — these are reference commands. Same mechanism as
> `/credit/expire` and the log cleanup job in `functions/docs/LOG_DELETION.md`.

Two jobs: export at 00:00, then zip+email at 00:15 (gives the export time to finish).

```bash
# Phase 1 — start export at midnight NZ
gcloud scheduler jobs create http firestore-backup-export \
  --schedule="0 0 * * *" \
  --time-zone="Pacific/Auckland" \
  --uri="https://<region>-<project>.cloudfunctions.net/v1/backup/daily" \
  --http-method=POST \
  --headers="x-cron-secret=<CRON_SECRET value>" \
  --attempt-deadline=540s

# Phase 2 — zip + email 15 minutes later
gcloud scheduler jobs create http firestore-backup-zip-send \
  --schedule="15 0 * * *" \
  --time-zone="Pacific/Auckland" \
  --uri="https://<region>-<project>.cloudfunctions.net/v1/backup/zip-and-send" \
  --http-method=POST \
  --headers="x-cron-secret=<CRON_SECRET value>" \
  --attempt-deadline=540s
```

If 15 minutes isn't enough for a large export, increase the gap. (Alternatively, phase 2
can be triggered by a GCS "object finalize" event on the export's
`*/all_namespaces/.../output-*` completion — but the two-scheduler approach is simpler and
matches the rest of the codebase.) Replace `<region>`, `<project>`, and `<CRON_SECRET
value>` with real values (`firebase functions:list` or the Cloud console).

---

## Verification

1. **Compiles:** `npm --prefix functions run build`.
2. **Phase 1:** with the emulator or a deployed dev function, trigger the export and
   confirm a dated folder appears in the bucket:
   ```bash
   curl -X POST https://<region>-coffix-app-dev.cloudfunctions.net/v1/backup/daily \
     -H "x-cron-secret: <CRON_SECRET value>"
   gcloud storage ls gs://coffix-app-dev-firestore-backups/firestore-exports/
   ```
3. **Phase 2:** once the export operation shows DONE
   (`gcloud firestore operations list`), trigger zip+send and confirm:
   ```bash
   curl -X POST https://<region>-coffix-app-dev.cloudfunctions.net/v1/backup/zip-and-send \
     -H "x-cron-secret: <CRON_SECRET value>"
   gcloud storage ls gs://coffix-app-dev-firestore-backups/firestore-exports/   # <date>.zip present
   ```
4. **Link works:** open the signed URL from the email and confirm the `.zip` downloads and
   unzips to the export files.
5. **Email arrives:** confirm `IT@coffix.co.nz` (and the `archive@` BCC) receive the
   message with the link.
6. **Auth:** repeat either curl with a missing/wrong `x-cron-secret` → expect `401`.

---

## Caveats

- **Signed URL is 7 days, not 30.** GCS V4 signed URLs are hard-capped at 7 days. We ship
  7 days; the daily job re-issues a fresh link every day. A genuine 30-day link would need
  a **V2 service-account-signed URL** (the project already loads `FB_PRIVATE_KEY` /
  `FB_CLIENT_EMAIL`, so it's feasible) — documented here as a future option, **not
  implemented**.
- **Export is async.** Never block the HTTP request waiting for `exportDocuments` to
  finish; the operation can outlast the 540s function. That's why zip+email is a separate,
  later-scheduled phase.
- **Correct database in prod.** The export must target `coffix-prod-australia` in prod and
  `(default)` in dev — derived from `GCLOUD_PROJECT` exactly like
  `functions/src/config/firebaseAdmin.ts`. Exporting the wrong db silently backs up
  nothing useful.
- **Cost.** Managed exports are billed as document reads, plus GCS storage for the export
  folder and the `.zip`. Add a retention cleanup (e.g. a third small endpoint, or a GCS
  lifecycle rule) to delete `firestore-exports/*` older than N days so the bucket doesn't
  grow unbounded.
- **Restore is a separate, manual operation** (`gcloud firestore import`). This doc only
  covers producing and delivering the backup, not restoring it.
