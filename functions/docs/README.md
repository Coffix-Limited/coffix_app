# Coffix Cloud Functions

The backend for the Coffix app: a single Firebase Cloud Function (`v1`) that
serves an Express API. All HTTP traffic goes through one `onRequest` handler
mounted in `src/index.ts`, which delegates to the Express app in `src/api.ts`.

## What you can do here

This is the place to work on server-side logic — anything the Flutter app or
the web app manager (`appmgr.coffix.co.nz`) calls over HTTP, plus integrations
with third-party services (Windcave payments, email, push notifications).

Typical tasks:

- **Add or change an API endpoint** — pick the right domain module under
  `src/<domain>/` (or create a new one) and mount its router in `src/api.ts`.
- **Adjust business logic** — edit the `service.ts` for the relevant domain.
- **Change request/response validation** — edit the `schema.ts` (Zod schemas).
- **Touch payments** — `src/windcave/` (session creation) and `src/webhook/`
  (Windcave callbacks). See the sample payloads in those folders.
- **Manage Coffix Credit** — `src/coffixCredit/`.
- **Email / notifications / OTP / referrals** — their respective modules.

## Layout

Each domain follows the same shape:

```
src/<domain>/
├── router.ts      # Express routes, mounted in src/api.ts
├── service.ts     # business logic + Firestore access
├── schema.ts      # Zod request/response validation
└── interface.ts   # shared TypeScript types
```

Cross-cutting code:

| Path                 | Purpose                                            |
| -------------------- | -------------------------------------------------- |
| `src/index.ts`       | Function entry point; loads env, exports `v1`.     |
| `src/api.ts`         | Express app, CORS, rate limiting, router mounting. |
| `src/middleware/`    | `auth`, `method`, `rateLimiter`.                   |
| `src/config/`        | Firebase Admin init (`firebaseAdmin.ts`).          |
| `src/utils/`         | Time, email templating, order numbers, serialize.  |
| `src/constant/`      | Shared constants.                                  |
| `src/script/`        | One-off scripts (e.g. product seeding).            |

## Mounted routes (`src/api.ts`)

| Prefix           | Module             |
| ---------------- | ------------------ |
| `/health`        | health check       |
| `/otp`           | `otp/`             |
| `/payment`       | `windcave/`        |
| `/firebase`      | `firebase/`        |
| `/webhook`       | `webhook/`         |
| `/credit`        | `coffixCredit/`    |
| `/auth`          | `auth/`            |
| `/order`         | `order/`           |
| `/notification`  | `notification/`    |
| `/referrals`     | `referrals/`       |
| `/email`         | `email/`           |
| `/transaction`   | `transaction/`     |
| `/log`           | `log/`             |

## Environment

`src/index.ts` picks the env file from `GCLOUD_PROJECT`: a project name
containing `dev` loads `.env.development`, otherwise `.env.production`.
Secrets live in those files — never in source. `env.example` shows the keys.

CORS allows `appmgr.coffix.co.nz`, its dev subdomain, and `localhost:3000`.

## Commands

```bash
npm run build          # compile TypeScript (tsc → lib/)
npm run build:watch    # recompile on change

npm run serve:dev      # build + emulators with the dev service account
npm run serve:prod     # build + emulators with the prod service account
npm run shell          # firebase functions:shell

npm run deploy:dev     # deploy to coffix-app-dev
npm run deploy:prod    # deploy to coffix-app-prod
npm run logs           # tail function logs

npm run seed:products  # seed product data
```

## Adding a new endpoint (checklist)

1. Create `src/<domain>/` with `router.ts`, `service.ts`, `schema.ts`.
2. Validate input with a Zod schema in `schema.ts`.
3. Put Firestore / external calls in `service.ts`; keep the router thin.
4. Apply `auth` / `method` middleware as needed.
5. Import and `api.use("/<prefix>", <domain>Router)` in `src/api.ts`.
6. `npm run build` to type-check, then `npm run serve:dev` to test locally.

## Related docs

- `CORS.md` — CORS configuration details.
- `docs/LOG_DELETION.md` — log retention / deletion.
- `src/config/MULTI_FIREBASE_APPS.md` — multi-project Firebase setup.
- `src/windcave/WINDCAVE_SESSION_PAYMENT.md`, `src/webhook/*_SAMPLE.md` —
  payment integration payload samples.
```
