# Runbook: Coffix backend errors (aborted requests, billing, 429)

The Coffix API runs as a **single** gen-2 Cloud Function `v1` (an Express `api` app) in
`functions/src/index.ts`. Because all traffic funnels through that one function, a problem in
one place tends to surface for the whole API. This runbook covers the three failures we have
actually hit in production.

Start here — match the symptom to the cause:

| Symptom | Likely cause | Jump to |
|---|---|---|
| Deploy: `403 ... check billing account` / runtime: `billing is disabled for this project` | Deployer account can't access an **open** billing account | [Billing](#1-billing-disabled--deploy-403) |
| `The request was aborted because there was no available instance` (503) | Cold start (scaled from 0) or saturation (instances at max) | [Capacity](#2-no-available-instance--503) |
| `429 Too many requests` (works, then fails after a while) | Our **own** `globalLimiter` rate limit — **not** Cloud Run | [Rate limit](#3-429-too-many-requests) |

---

## 1. Billing disabled / deploy 403

**Errors**

```
Upload Error: ... HTTP Error: 403, Write access to project '<project>' was denied:
please check billing account associated and retry
```
```
v1: The request failed because billing is disabled for this project.
```

**Cause.** Gen-2 functions need an **open** Cloud Billing account, and the **deployer** must have
permission on it. The Firebase console can still say "Blaze" while the underlying billing account
is closed/delinquent — or you may simply be signed in as the wrong Google account. Note that
`gcloud billing projects describe` showing `billingEnabled: true` only means the *link* exists, not
that the account is open or that you can use it.

**Diagnose**

```bash
# Which account are gcloud / firebase using?
gcloud auth list
firebase login:list

# Is the project linked to billing, and to which account?
gcloud billing projects describe <project>      # e.g. coffix-app-dev

# Can the active account actually see/use that billing account?
gcloud billing accounts list                     # 0 items => wrong account or no access
```

If `gcloud billing accounts list` returns **0 items**, the active account has no usable billing
account — that is the problem.

**Fix**

- Switch to the account that **owns** billing, then redeploy:
  ```bash
  gcloud config set account <owner@example.com>
  firebase login:use <owner@example.com>
  npm --prefix functions run deploy:dev   # or deploy:prod
  ```
- If no account can see the linked billing account as **OPEN**, reactivate it (or link a new one)
  in the [Billing console](https://console.cloud.google.com/billing).

---

## 2. "No available instance" / 503

**Error**

```
The request was aborted because there was no available instance.
```
Ref: https://cloud.google.com/run/docs/troubleshooting#abort-request

**Cause.** Cloud Run had no warm instance and couldn't start one in time. `maxInstances` is the
concurrency budget for the **whole** API (one function), so it's the first thing to exhaust.

**Diagnose**

```bash
firebase functions:log --only v1
```
Cloud Console → Cloud Run → service `v1` → **Metrics** (around the incident): Instance count,
Container utilization, Request count, `429`/`503` rate.

| Signal | Failure mode | Fix |
|---|---|---|
| Instances **flat at the max** | **Saturation** | Raise `maxInstances` (watch cost) |
| Low/zero traffic then a spike, scaling **from 0** | **Cold start** | Set `minInstances: 1` |
| Requests slow, instances pinned, request count low | **Slow requests** | Add timeouts to downstream calls |

**Fix** — edit `functions/src/index.ts`, then `npm --prefix functions run deploy:dev`:

```ts
// Current config keeps one warm instance (avoids cold-start aborts):
setGlobalOptions({ maxInstances: 10, minInstances: 1 });

// Out of capacity under load? Raise the ceiling:
setGlobalOptions({ maxInstances: 50, minInstances: 1 });
```

A slow downstream call (Firestore / Windcave) holds a container open and eats the budget — add
timeouts so a stuck request releases its instance instead of holding it for `timeoutSeconds: 540`.

---

## 3. 429 Too Many Requests

**Error**

```json
{ "success": false, "message": "Too many requests. Please try again later." }
```

**This is our own rate limiter, not Cloud Run.** Cloud Run capacity problems return 503 /
"no available instance" (section 2). A clean **429** with that JSON body comes from
`globalLimiter` in `functions/src/middleware/rateLimiter.ts`, applied to the whole API in
`functions/src/api.ts`.

**Why it bit us.** The limiter was `max: 60 / 60s` **keyed by IP**, using the default
**in-memory** store. Two compounding issues:

1. **`/log` dominates traffic.** The Flutter app fires a log on nearly every action, and
   `lib/core/routes/app_navigation_observer.dart` logs on **every screen navigation**. Those
   `/log/create` calls were counting against the same 60/min budget as real API calls.
2. **IP keying + shared wifi.** Several users behind one NAT (a café) shared a single 60/min bucket.

**Fixes applied** (in `functions/src/middleware/rateLimiter.ts` / `log/router.ts`):

- `globalLimiter` now **skips `/log` and `/health`**, is **keyed by Firebase UID** (falls back to
  IP), and has a higher `max`.
- `/log/create` is now **fire-and-forget** — it validates, responds `200` immediately, and writes to
  Firestore in the background, so logging no longer holds an instance or blocks real traffic.

**Caveat — in-memory store.** `express-rate-limit`'s default store is per-instance. With
`minInstances:1`/`maxInstances:10`, each instance has its own counter, so the limit isn't truly
global. For correct cross-instance limiting, back it with a shared store (Firestore/Redis) —
see `docs/redis-rate-limit-store.md` for a beginner walkthrough and the cheapest option.
**Follow-up (not yet done):** consider splitting `/log` into its own Cloud Function with its own
instance pool, routed via a Firebase Hosting rewrite so the client URL stays the same.

---

## Client-side note

These backend errors are **transient**. Retry-with-backoff on idempotent calls in the Flutter API
client (`lib/core/`) reduces user-facing failures while the backend recovers or scales.

## References

- Cloud Run abort-request troubleshooting: https://cloud.google.com/run/docs/troubleshooting#abort-request
- Firebase scaling / `setGlobalOptions`: https://firebase.google.com/docs/functions/manage-functions
- Cloud Billing: https://console.cloud.google.com/billing
