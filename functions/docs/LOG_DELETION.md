# Log Deletion (Cleanup)

## The problem

> "How can I delete old log entries? There might be thousands and thousands of log
> entries a day and it will make the log huge."

The `logs` Firestore collection is **write-only** today. `LogService`
(`functions/src/log/service.ts`) only ever appends documents — nothing removes them.
With thousands of entries per day the collection grows unbounded, which increases
Firestore storage cost and slows any future log query.

## The solution at a glance

A daily scheduled job (00:00 NZ time) deletes log entries once they are older than a
**configurable retention window**. Retention is **age + severity** based:

- Low-severity logs (logins, OTP — `severityLevel` 1–3) are short-lived.
- High-severity logs (financial transactions — `severityLevel` 9) are kept much longer
  for audit/compliance.

We reuse the repo's existing cron pattern: an HTTP endpoint guarded by an
`x-cron-secret` header, triggered by **Google Cloud Scheduler**. This is exactly how
credit expiry already works — see `POST /credit/expire`
(`functions/src/coffixCredit/router.ts:173`). We do **not** introduce a new
`onSchedule` function, to stay consistent with the rest of the codebase.

---

## 1. Retention config — three fields in the `global` doc

These are the properties you asked about. They live on the existing global config
document (collection `global`, doc id `GLOBAL_COLLECTION_ID` from
`functions/src/constant/constant.ts`) — the same doc `expireCredits` already reads.

Add them to `AppGlobal` in `functions/src/global/interface.ts`:

```ts
export interface AppGlobal {
  // ...existing fields...
  logRetentionDays?: number;             // normal/low-severity log lifetime (days)
  logHighSeverityRetentionDays?: number; // high-severity log lifetime (days)
  logHighSeverityThreshold?: number;     // severityLevel >= this == "high severity"
}
```

| Field | Type | Meaning | Suggested default |
|---|---|---|---|
| `logRetentionDays` | number | Delete logs **below** the threshold older than this | `90` |
| `logHighSeverityRetentionDays` | number | Delete logs **at/above** the threshold older than this | `730` |
| `logHighSeverityThreshold` | number | `severityLevel` ≥ this counts as high severity | `9` |

Defaults are applied in code with the `?? defaultValue` pattern already used in
`functions/src/coffixCredit/service.ts`, so the job still works even if the fields are
not set in Firestore yet.

> The `severityLevel` scale used today (see `functions/src/log/service.ts`):
> `1` = low (login, OTP), `3` = errors, `5` = mid (payment, transaction),
> `9` = high (financial). With a threshold of `9`, only the financial logs get the
> longer retention.

---

## 2. The cleanup logic — `LogService.cleanupOldLogs()`

Add a new method to `functions/src/log/service.ts`.

Key facts that make this work:

- The `Log.time` field is set server-side to `new Date()`
  (`functions/src/log/service.ts:11`) and stored as a Firestore Timestamp, so it is
  **range-queryable**.
- Firestore range queries cannot express "(severity < X AND old) OR (severity >= X AND
  very old)" in a single query, so we run **two passes**.
- "Thousands a day" means a single run may delete tens of thousands of docs. A single
  batch (max 500 ops) or an unpaginated `.get()` would fail or time out, so we
  **page in chunks of 500**.

```ts
import { firestore } from "../config/firebaseAdmin";
import { GLOBAL_COLLECTION_ID } from "../constant/constant";
import { Log } from "./interface";

export class LogService {
  // ...existing log() and domain methods...

  async cleanupOldLogs(): Promise<{ deletedCount: number }> {
    // 1. Read retention config from the global doc (with safe defaults)
    const globalSnap = await firestore
      .collection("global")
      .doc(GLOBAL_COLLECTION_ID)
      .get();
    const g = globalSnap.data() ?? {};

    const retentionDays = (g.logRetentionDays ?? 90) as number;
    const highRetentionDays = (g.logHighSeverityRetentionDays ?? 730) as number;
    const highThreshold = (g.logHighSeverityThreshold ?? 9) as number;

    // 2. Compute cutoffs
    const now = Date.now();
    const normalCutoff = new Date(now - retentionDays * 24 * 60 * 60 * 1000);
    const highCutoff = new Date(now - highRetentionDays * 24 * 60 * 60 * 1000);

    const logs = firestore.collection("logs");

    // 3. Two passes: low/normal severity, then high severity
    let deletedCount = 0;
    deletedCount += await this.deleteInBatches(
      logs.where("severityLevel", "<", highThreshold).where("time", "<", normalCutoff)
    );
    deletedCount += await this.deleteInBatches(
      logs.where("severityLevel", ">=", highThreshold).where("time", "<", highCutoff)
    );

    return { deletedCount };
  }

  // Delete a query's results in pages of 500 (Firestore batch limit).
  private async deleteInBatches(
    query: FirebaseFirestore.Query
  ): Promise<number> {
    let total = 0;
    while (true) {
      const snap = await query.limit(500).get();
      if (snap.empty) break;

      const batch = firestore.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();

      total += snap.size;
      if (snap.size < 500) break; // last page
    }
    return total;
  }
}
```

> **Composite index required.** Each pass filters on `severityLevel` **and** `time`,
> which needs a composite index. Either add it to `firestore.indexes.json` and
> `firebase deploy --only firestore:indexes`, or run the function once and follow the
> "create index" link Firestore prints in the error log. Suggested indexes on the
> `logs` collection:
> - `severityLevel` ASC, `time` ASC
> (one index covers both `<` and `>=` on `severityLevel` combined with `time`.)

---

## 3. The cron endpoint — `POST /log/cleanup`

Add to `functions/src/log/router.ts`. This copies the guard from
`functions/src/coffixCredit/router.ts:173-198` verbatim so it behaves identically to
the credit-expiry cron. `requirePost` and `logger` are already imported in this file.

```ts
router.post(
  "/cleanup",
  requirePost,
  async (request: Request, response: Response) => {
    const secret = request.headers["x-cron-secret"];
    if (!secret || secret !== process.env.CRON_SECRET) {
      return response
        .status(401)
        .json({ success: false, message: "Unauthorized" });
    }

    try {
      const { deletedCount } = await logService.cleanupOldLogs();
      logger.info(`Log cleanup run: ${deletedCount} logs deleted`);
      return response.status(200).json({ success: true, data: { deletedCount } });
    } catch (error) {
      logger.error("Error cleaning up logs:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  }
);
```

No wiring changes are needed:

- The `log` router is already mounted at `/log` in `functions/src/api.ts`.
- It is exposed through the single `v1` HTTPS function in `functions/src/index.ts`,
  which has a **540s timeout** — enough headroom for the paged deletes.
- `CRON_SECRET` already exists in `.env.development` / `.env.production` / `.env.local`.

The full path is therefore `POST v1/log/cleanup`.

---

## 4. The schedule (00:00 daily)

Create an external Google Cloud Scheduler job — the same mechanism that triggers
`/credit/expire`:

```bash
gcloud scheduler jobs create http log-cleanup \
  --schedule="0 0 * * *" \
  --time-zone="Pacific/Auckland" \
  --uri="https://<region>-<project>.cloudfunctions.net/v1/log/cleanup" \
  --http-method=POST \
  --headers="x-cron-secret=<CRON_SECRET value>" \
  --attempt-deadline=540s
```

- `--schedule="0 0 * * *"` is standard cron: **minute 0, hour 0, every day** → runs at
  midnight.
- `--time-zone="Pacific/Auckland"` matches the NZ timezone already used by
  `expireCredits` (`functions/src/firebase/service.ts:737`), so "midnight" means
  midnight NZ.
- Replace `<region>`, `<project>`, and `<CRON_SECRET value>` with your real values
  (find the deployed URL with `firebase functions:list` or in the Cloud console).

To update the schedule later use `gcloud scheduler jobs update http log-cleanup ...`.

---

## Verification

1. **Compiles:** `npm --prefix functions run build`.
2. **Local run:** Seed the `logs` collection with test docs spanning a range of `time`
   values (some older than 90 days, some older than 730) and `severityLevel` values
   (mix of `1`–`5` and `9`). Then:
   ```bash
   npm --prefix functions run serve
   curl -X POST http://localhost:5001/<project>/<region>/v1/log/cleanup \
     -H "x-cron-secret: <CRON_SECRET value>"
   ```
3. **Correctness:** Confirm only logs past their severity-appropriate cutoff are gone,
   recent and high-severity-but-not-old-enough logs remain, and the returned
   `deletedCount` matches what you deleted.
4. **Auth:** Repeat the curl with a missing/wrong `x-cron-secret` and confirm it returns
   `401`.
5. **Production:** After deploy, manually trigger the scheduler job
   (`gcloud scheduler jobs run log-cleanup`) and check the function logs for the
   `Log cleanup run: N logs deleted` line.
```
