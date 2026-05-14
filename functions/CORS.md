# CORS Configuration — Firebase Functions (Express 5)

## How it works

CORS is configured globally in `src/api.ts` using the `cors` npm package:

```typescript
const allowedOrigins = [
  "https://dev.appmgr.coffix.co.nz",
  "https://appmgr.coffix.co.nz",
  "http://localhost:3000",
];

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(null, false); // reject cleanly — do NOT throw an Error here
    }
  },
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: true,
};

api.use(cors(corsOptions));
```

`api.use(cors(corsOptions))` handles **both regular requests and OPTIONS preflight** automatically. No `api.options(...)` route is needed.

## Lessons learned / pitfalls

### 1. Do NOT use `callback(new Error(...))` to reject origins

```typescript
// WRONG — breaks CORS for real requests
callback(new Error(`CORS: origin ${origin} not allowed`));

// CORRECT — rejects cleanly without dropping headers
callback(null, false);
```

When you pass an `Error` to the callback, `cors` forwards it to Express's error pipeline via `next(err)`. Express's default error handler sends a response **without** any CORS headers, which the browser reads as an opaque CORS failure — even though the actual problem was just a rejected origin.

### 2. Do NOT add trailing slashes to origins

Browsers send the `Origin` header without a trailing slash:
- Browser sends: `https://dev.appmgr.coffix.co.nz`
- Wrong list entry: `"https://dev.appmgr.coffix.co.nz/"` ← won't match

### 3. Do NOT use `api.options("*", ...)` or `api.options("/{*path}", ...)`

- Express 4: `"*"` worked as a wildcard
- Express 5 (path-to-regexp v8): bare `"*"` throws `PathError: Missing parameter name`
- `"/{*path}"` compiles but may not match in all environments (Cloud Run, emulator)

**The correct approach**: `api.use(cors(corsOptions))` already intercepts OPTIONS preflight requests before any route handler runs — no explicit `api.options(...)` route is needed.

### 4. Preflight passes but actual request fails

If OPTIONS returns 200 but the actual fetch gets a CORS error, check:
1. Is the origin in `allowedOrigins` exactly matching what the browser sends (no trailing slash, correct protocol)?
2. Is any downstream middleware (auth, rate limiter) responding before CORS headers are written? — This shouldn't happen since `cors()` runs first via `api.use()`.
3. Is the route actually registered? A 404 from Express won't have CORS headers.

## Troubleshooting checklist

- [ ] Origin in `allowedOrigins` matches browser `Origin` header exactly (check DevTools → Request Headers)
- [ ] No trailing slashes in `allowedOrigins`
- [ ] `callback(null, false)` used for rejected origins, not `callback(new Error(...))`
- [ ] No `api.options(...)` wildcard route conflicting with `api.use(cors(...))`
- [ ] Route is actually registered in `api.ts`
- [ ] Latest code is deployed (build + deploy after every change)
