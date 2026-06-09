# Redis & a shared rate-limit store (beginner guide)

> **TL;DR.** Our rate limiter currently counts requests **in memory**, separately on each running
> server instance — so the limit isn't perfectly global. Redis (a shared counter all instances read
> from) is the standard fix. **You don't need this urgently.** When you do, the cheapest path for us
> is a serverless Redis like **Upstash**, *not* Google's heavier **Memorystore**. This doc explains why,
> in plain terms, with the next steps.

---

## 1. What is Redis? (no prior knowledge needed)

Redis is a small, very fast database that keeps its data **in memory** (RAM). People use it as a
**shared scratchpad** that many servers can read from and write to at the same time. Typical uses:
rate-limit counters, caching, sessions, queues.

For us, the only job we care about right now is one thing: **a shared counter.**

**The whiteboard analogy**

- Today: each running copy of our backend has its **own private notepad** where it tallies
  "how many requests has this user made this minute?"
- With Redis: there's **one shared whiteboard**. Every copy writes its tallies there, so they all
  agree on the real total.

That's it. Redis = the shared whiteboard.

---

## 2. Why would *our* app want it?

Our API is **one Cloud Function (`v1`)** that Google can run as **many copies at once** (up to
`maxInstances: 10`). The rate limiter lives in `functions/src/middleware/rateLimiter.ts` and uses
`express-rate-limit`, which by default stores its counters **in memory on each copy**.

So with, say, a limit of "300 requests/minute":

- If 3 copies are running, the *effective* limit becomes roughly **300 × 3 = 900/minute**, because
  each copy counts independently and doesn't know about the others.
- The limit is **per-copy**, not truly **global**.

**Do we need to fix this right now? Probably not.** After the last change, our limits are generous
and keyed by **Firebase UID** (not shared IP), so the per-copy inaccuracy is a *correctness nicety*,
not something causing outages or the old 429 problem. Reach for Redis when:

- you need **accurate global** limits (e.g. strict abuse/fraud limits where the exact number matters), or
- you later want **shared caching or sessions** across instances (a separate, bigger benefit).

Until then, "do nothing" is a perfectly valid, zero-cost option.

---

## 3. Does GCP have a Redis? — Yes

Google's managed Redis is **Memorystore** (it comes in two flavours: *Memorystore for Redis* and the
newer open-source-compatible *Memorystore for Valkey*). Google runs the servers, patches, and backups
for you.

**But there's a catch that matters for us.** Memorystore lives on a **private network (VPC)** with a
private IP address. Our gen-2 functions (which run on Cloud Run) **cannot reach it directly** — you
must set up a **VPC connector / Direct VPC egress** to bridge them. On top of that:

- It bills **~24/7** (a Redis node is always on — no scale-to-zero), so it's a steady monthly cost
  even when idle.
- For low latency it should run in an **Australian region** to match our Firestore
  (`coffix-prod-australia`).

Memorystore is great when you have heavy, latency-sensitive caching. **For just a rate-limit counter,
it's overkill and the most expensive/complex option.**

---

## 4. The realistic options compared

| Option | What it is | Setup effort | Cost shape | Fit for our rate limiter |
|---|---|---|---|---|
| **Do nothing (in-memory)** | Keep today's setup | None | Free | Fine until accurate *global* limits matter |
| **Upstash Redis** (serverless) | Hosted Redis you reach over HTTPS | **Low** — sign up, copy a URL + token | Free tier; pay-per-request; scales toward zero | ✅ **Best cheap fit** — *no VPC connector needed* |
| **Firestore-backed store** | Use the Firestore we already have as the counter store | Low–medium (a community/custom store adapter) | Pay per read/write (we already pay Firestore) | Good — no new service, but adds Firestore ops/cost |
| **GCP Memorystore** (Redis/Valkey) | Google-managed Redis on a VPC | **High** — VPC connector + networking | ~24/7 node billing | Works, but heaviest & priciest for this use |

**Recommendation (cheapest path, per your call):** if/when you want a shared store, use
**Upstash Redis**. It's managed, has a free tier, and — crucially — talks over **HTTPS**, so our
function can reach it **without** the VPC-connector headache that Memorystore requires. Keep
**Memorystore** on the shelf for *later*, only if we grow into heavy low-latency caching.

---

## 5. How would this affect our work?

**The code change is small.** `express-rate-limit` is designed to swap its storage: you build a
"store" object and pass it as `store:` into the existing `rateLimit({ ... })` calls in
`functions/src/middleware/rateLimiter.ts`. Nothing else about the limiters changes.

Roughly, before → after for one limiter:

```ts
// BEFORE — in-memory (per-instance counter)
export const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  keyGenerator: keyByUid,
  // ...
});

// AFTER — shared counter via Upstash Redis
import { RedisStore } from "rate-limit-redis";
import { Redis } from "@upstash/redis";

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_URL!,
  token: process.env.UPSTASH_REDIS_TOKEN!,
});

export const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  keyGenerator: keyByUid,
  store: new RedisStore({
    sendCommand: (...args: string[]) => redis.eval(...), // adapter wiring per docs
  }),
  // ...
});
```

> The exact `sendCommand` wiring depends on the client (`@upstash/redis` vs `ioredis`); follow the
> `rate-limit-redis` README for the precise adapter. The point is: **only the `store:` line is new.**

**Things to plan for:**

- **Secrets, not source.** The Redis URL/token go in `functions/.env.development` /
  `functions/.env.production` (per our CLAUDE.md rule), **never** committed in code.
- **A new dependency in the request path.** Every limited request now makes a network call to Redis.
  Upstash is fast, but it's one more external service that can be slow or down.
- **Decide the failure behaviour.** If Redis is unreachable, do we **fail-open** (allow the request)
  or **fail-closed** (block it)? For a rate limiter, **fail-open is the safer default** — a Redis
  outage should not take the whole API down. `express-rate-limit` supports this via the store's
  error handling.
- **One more thing to monitor.** Add it to whatever dashboards/alerts you keep.

---

## 6. Next steps (checklist — nothing committed yet)

1. **Decide if you even need it now.** Honestly, **likely not urgent** — current limits are generous
   and UID-keyed. Revisit when you need *exact* global limits or shared caching.
2. **If you proceed, go with Upstash:**
   - Create a free Upstash Redis database in an **Australian region** (closest to our Firestore).
   - Copy its **REST URL + token** into `functions/.env.development` and `.env.production`.
   - Install deps: `npm --prefix functions i rate-limit-redis @upstash/redis`
   - Wire `store:` into the limiters in `functions/src/middleware/rateLimiter.ts` (see §5).
   - Choose **fail-open** behaviour for Redis errors.
   - Deploy dev: `npm --prefix functions run deploy:dev`
   - **Verify it's shared:** generate enough load to run multiple instances and confirm the limit is
     now enforced as a single global number (not multiplying per instance).
3. **Memorystore = the "later, if we outgrow it" path.** If a future need justifies it, that's when
   you take on the VPC connector + always-on cost.

---

## 7. References

- `express-rate-limit` stores: https://express-rate-limit.mintlify.app/reference/stores
- `rate-limit-redis`: https://github.com/express-rate-limit/rate-limit-redis
- Upstash Redis: https://upstash.com/docs/redis/overall/getstarted
- GCP Memorystore for Redis: https://cloud.google.com/memorystore/docs/redis
- GCP Memorystore for Valkey: https://cloud.google.com/memorystore/docs/valkey
- Serverless VPC Access (why Memorystore needs a connector): https://cloud.google.com/vpc/docs/serverless-vpc-access

> Related: see `docs/cloud-run-no-available-instance.md` §3 (the 429 fix) for the in-memory caveat
> this doc addresses.
