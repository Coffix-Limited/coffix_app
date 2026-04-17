# Rate Limiting Guide

## Should you apply it globally or per-route?

**Neither alone — use both layers together.**

- **Global limiter** — broad protection against volumetric abuse from any IP. Cheap to configure, catches everything.
- **Per-route limiters** — tighter caps on sensitive or expensive routes (OTP, payment, auth). These sit *in addition to* the global one, not instead of it.

The key insight for this codebase: because every protected route already passes through `requiredAuth`, you can key your per-route limiters off the verified Firebase `uid` instead of IP. That makes them much harder to bypass with proxies or rotating IPs.

---

## Installation

```bash
npm install express-rate-limit
```

No additional types needed — the package ships its own TypeScript definitions.

---

## Step 1 — Create `src/middleware/rateLimiter.ts`

```typescript
import rateLimit, { RateLimitRequestHandler, Options } from "express-rate-limit";
import { Request, Response } from "express";
import { AuthenticatedRequest } from "./auth";

// ─── Shared key generators ────────────────────────────────────────────────────

/**
 * Key by IP (used on public / pre-auth routes).
 * Falls back to a fixed string if the IP is somehow missing.
 */
const keyByIp = (req: Request): string =>
  (req.headers["x-forwarded-for"] as string)?.split(",")[0].trim() ??
  req.socket?.remoteAddress ??
  "unknown";

/**
 * Key by verified Firebase UID (used on protected routes that go through `requiredAuth`).
 * Falls back to IP so it still works if called before auth middleware by accident.
 */
const keyByUid = (req: Request): string => {
  const uid = (req as AuthenticatedRequest).user?.uid;
  return uid ? `uid:${uid}` : keyByIp(req);
};

// ─── Shared handler ───────────────────────────────────────────────────────────

const onLimitReached = (_req: Request, res: Response): void => {
  res.status(429).json({
    success: false,
    error: "Too many requests. Please slow down.",
  });
};

// ─── Helper ───────────────────────────────────────────────────────────────────

function make(opts: Partial<Options>): RateLimitRequestHandler {
  return rateLimit({
    standardHeaders: true,   // Return RateLimit-* headers
    legacyHeaders: false,
    handler: onLimitReached,
    ...opts,
  });
}

// ─── Global limiter (IP-based) ────────────────────────────────────────────────
// Applied to the entire Express app. Catches abusive clients before any route
// logic runs. Set deliberately loose — tighten per-route as needed.

export const globalLimiter = make({
  windowMs: 60_000,   // 1 minute
  limit: 120,         // 120 req/min per IP  (~2 req/sec)
  keyGenerator: keyByIp,
});

// ─── Per-route limiters (UID-based after auth) ────────────────────────────────

/**
 * OTP send — prevent OTP spam (each send triggers an email + Firestore write).
 * 5 sends per 10 minutes per user is generous for legitimate use.
 */
export const otpSendLimiter = make({
  windowMs: 10 * 60_000,  // 10 minutes
  limit: 5,
  keyGenerator: keyByUid,
  message: { success: false, error: "Too many OTP requests. Wait 10 minutes." },
});

/**
 * OTP verify — prevent brute-force guessing of a 6-digit code.
 * 10 attempts per 15 minutes per user. The existing `attempts` counter in
 * Firestore is a second layer, but this stops the Firestore writes from
 * accumulating at all.
 */
export const otpVerifyLimiter = make({
  windowMs: 15 * 60_000,  // 15 minutes
  limit: 10,
  keyGenerator: keyByUid,
});

/**
 * Payment initiation — each attempt hits the Windcave gateway.
 * 10 per hour per user is well above any real shopping session.
 */
export const paymentLimiter = make({
  windowMs: 60 * 60_000,  // 1 hour
  limit: 10,
  keyGenerator: keyByUid,
});

/**
 * Auth / account check endpoint.
 */
export const authLimiter = make({
  windowMs: 60_000,   // 1 minute
  limit: 20,
  keyGenerator: keyByUid,
});

/**
 * Credit actions (top-up, share) — financial operations.
 */
export const creditLimiter = make({
  windowMs: 60_000,   // 1 minute
  limit: 10,
  keyGenerator: keyByUid,
});

/**
 * Webhook — rate-limit by IP since no Firebase token is present.
 * Add signature verification alongside this.
 */
export const webhookLimiter = make({
  windowMs: 60_000,   // 1 minute
  limit: 60,
  keyGenerator: keyByIp,
});
```

---

## Step 2 — Apply the global limiter in `src/api.ts`

```typescript
import express from "express";
import { globalLimiter } from "./middleware/rateLimiter";
// ... existing router imports ...

export const api = express();

// Global middleware — order matters: JSON parser first, then global rate limit
api.use(express.json());
api.use(globalLimiter);   // ← add this line

api.use("/hello-world", (request, response) => { ... });
// ... existing router mounts unchanged ...
```

---

## Step 3 — Apply per-route limiters

### `src/otp/router.ts`

```typescript
import { otpSendLimiter, otpVerifyLimiter } from "../middleware/rateLimiter";

// OTP send: limit BEFORE auth so the rate limit is checked even on invalid tokens
otpRouter.post("/send",   otpSendLimiter,   requirePost, requiredAuth, handler);
otpRouter.post("/verify", otpVerifyLimiter, requirePost, requiredAuth, handler);
```

> **Why before `requiredAuth` here?** The OTP send endpoint is called during onboarding flows where token state may be fresh. Placing the limiter first means you block spam before doing the Firebase token round-trip.

### `src/windcave/router.ts`

```typescript
import { paymentLimiter } from "../middleware/rateLimiter";

router.post("/initiate", paymentLimiter, requirePost, requiredAuth, handler);
```

### `src/auth/route.ts`

```typescript
import { authLimiter } from "../middleware/rateLimiter";

router.post("/check", authLimiter, requirePost, requiredAuth, handler);
```

### `src/coffixCredit/router.ts`

```typescript
import { creditLimiter } from "../middleware/rateLimiter";

router.post("/top-up", creditLimiter, requirePost, requiredAuth, handler);
router.post("/share",  creditLimiter, requirePost, requiredAuth, handler);
```

### `src/webhook/router.ts`

```typescript
import { webhookLimiter } from "../middleware/rateLimiter";

router.post("/", webhookLimiter, handler);
```

---

## Why UID-based keying beats IP-based on protected routes

| Approach | Bypass vector | Suitable for |
|---|---|---|
| IP-based | VPN / rotating proxies | Public/pre-auth routes |
| UID-based | Needs a valid Firebase token — much harder | Any route behind `requiredAuth` |

Firebase tokens are short-lived JWTs signed by Google. An attacker would need to compromise a real user account to bypass a UID-based limiter, which is a much higher bar.

For the global limiter (applied before any auth runs), IP is the only option — it is still valuable as a first-pass volumetric guard.

---

## In-memory vs. distributed storage

`express-rate-limit` defaults to an in-memory store. On Firebase Cloud Functions this is fine for most workloads because:

- Functions are stateless and can be cold-started, so in-memory state is ephemeral anyway
- The global limiter + per-route caps already stop realistic abuse patterns
- Firestore-backed persistence adds latency and cost

If you later need cross-instance consistency (e.g. high-traffic multi-region deployment), drop in a Redis store:

```bash
npm install rate-limit-redis ioredis
```

```typescript
import { RedisStore } from "rate-limit-redis";
import Redis from "ioredis";

const redis = new Redis(process.env.REDIS_URL!);

export const otpSendLimiter = make({
  windowMs: 10 * 60_000,
  limit: 5,
  keyGenerator: keyByUid,
  store: new RedisStore({ sendCommand: (...args) => redis.call(...args) }),
});
```

---

## Recommended limits at a glance

| Route | Window | Limit | Key |
|---|---|---|---|
| All routes (global) | 1 min | 120 | IP |
| `POST /otp/send` | 10 min | 5 | UID |
| `POST /otp/verify` | 15 min | 10 | UID |
| `POST /payment/*` | 1 hr | 10 | UID |
| `POST /auth/*` | 1 min | 20 | UID |
| `POST /credit/*` | 1 min | 10 | UID |
| `POST /webhook` | 1 min | 60 | IP |

Adjust these numbers based on your analytics — `RateLimit-Remaining` headers (added automatically by `standardHeaders: true`) make it easy to observe real usage patterns before tightening.

---

## Suggested follow-ups

- **OTP brute-force**: the existing `attempts` counter in Firestore should also lock the OTP document after (e.g.) 5 failed attempts — that's a second defense layer independent of the HTTP rate limiter.
- **Webhook security**: add Windcave signature verification (HMAC check on the raw body) in addition to the IP-based rate limit.
- **`helmet`**: add `npm install helmet` and `api.use(helmet())` in `api.ts` to set standard security headers in one line.
