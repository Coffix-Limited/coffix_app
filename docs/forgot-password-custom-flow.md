# Custom Forgot Password Flow (Link-Based)

Instead of using Firebase's built-in `sendPasswordResetEmail`, we generate a secure token server-side, email a reset link to the user, and handle the actual password update on a dedicated web page that calls our API.

---

## High-Level Flow

```
Flutter app
  └─ POST /auth/forgot-password/request
       │  generates token, emails link
       ▼
User clicks link in email
  └─ https://www.coffix.co.nz/reset-password?token=<token>
       │  (separate web app / static site)
       ▼
Web page: user enters new password
  └─ POST /auth/forgot-password/reset
       └─ updates password in Firebase Auth, invalidates token
```

---

## New API Endpoints

Both endpoints are mounted under the existing `api.ts`:

```ts
api.use("/auth", authRouter); // already exists
```

Add two routes to `src/auth/route.ts`:

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/auth/forgot-password/request` | Public | Look up email, generate token, send reset link |
| `POST` | `/auth/forgot-password/reset` | Public | Validate token, update password |

---

## Firestore: `passwordResetTokens` collection (new)

```ts
interface PasswordResetToken {
  docId: string;
  userId: string;
  token: string;      // crypto-random 32-byte hex
  expiresAt: Date;    // 1 hour from creation
  used: boolean;
  createdAt: Date;
}
```

No index needed — queries are by `token` field which can be a simple equality filter.

---

## Step 1 — Request reset link (`POST /auth/forgot-password/request`)

### Request body

```json
{ "email": "user@example.com" }
```

### Schema

```ts
// src/auth/schema.ts  (add to existing file)
export const forgotPasswordRequestSchema = z.object({
  email: z.email(),
});
```

### Handler

```ts
// src/auth/route.ts  (add to existing authRouter)
import crypto from "crypto";

authRouter.post("/forgot-password/request", requirePost, rateLimiter, async (req, res) => {
  const parsed = forgotPasswordRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ success: false, errors: parsed.error.issues });
  }

  const { email } = parsed.data;

  // 1. Look up Firebase Auth user — do NOT reveal whether email exists
  let uid: string;
  try {
    const user = await admin.auth().getUserByEmail(email);
    uid = user.uid;
  } catch {
    return res.status(200).json({ success: true });
  }

  // 2. Generate a secure token
  const token = crypto.randomBytes(32).toString("hex");

  // 3. Persist token in Firestore
  const ref = firestore.collection("passwordResetTokens").doc();
  await ref.set({
    docId: ref.id,
    userId: uid,
    token,
    expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
    used: false,
    createdAt: new Date(),
  });

  // 4. Build the reset URL pointing to your web app
  const resetUrl = `https://www.coffix.co.nz/reset-password?token=${token}`;

  // 5. Send email via EmailService
  //    Add a FORGOT_PASSWORD document in Firestore `emails` collection (see below)
  const emailService = new EmailService();
  await emailService.send({
    email,
    documentId: "FORGOT_PASSWORD",
    variables: { reset_url: resetUrl },
  });

  return res.status(200).json({ success: true });
});
```

### Email template (`emails/FORGOT_PASSWORD` Firestore doc)

| Field     | Value |
|-----------|-------|
| `subject` | `Reset your Coffix password` |
| `content` | `Hi {{first_name}},<br><br>Click the link below to reset your password. It expires in 1 hour.<br><br><a href="{{reset_url}}">Reset my password</a><br><br>If you didn't request this, you can ignore this email.` |

The `{{reset_url}}` variable is injected by the handler. `{{first_name}}` is filled automatically by `buildUserVariables` in `EmailService`.

---

## Step 2 — Web page handles the link

The page at `https://www.coffix.co.nz/reset-password` is a **separate web app** (e.g. a Next.js / React / plain HTML page hosted on your website).

On load it reads `?token=...` from the URL, then renders a form:

```
┌─────────────────────────────────┐
│  Reset your Coffix password     │
│                                 │
│  New password  [____________]   │
│  Confirm       [____________]   │
│                                 │
│           [ Reset Password ]    │
└─────────────────────────────────┘
```

On submit, the page calls:

```
POST /auth/forgot-password/reset
Body: { "token": "<from URL>", "newPassword": "..." }
```

---

## Step 3 — Reset password (`POST /auth/forgot-password/reset`)

### Request body

```json
{ "token": "abc123...", "newPassword": "newS3cur3Pass!" }
```

### Schema

```ts
export const forgotPasswordResetSchema = z.object({
  token: z.string().min(1),
  newPassword: z.string().min(8),
});
```

### Handler

```ts
authRouter.post("/forgot-password/reset", requirePost, async (req, res) => {
  const parsed = forgotPasswordResetSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ success: false, errors: parsed.error.issues });
  }

  const { token, newPassword } = parsed.data;

  // 1. Find the token document
  const snap = await firestore.collection("passwordResetTokens")
    .where("token", "==", token)
    .where("used", "==", false)
    .limit(1)
    .get();

  if (snap.empty) {
    return res.status(400).json({ success: false, message: "Invalid or expired token." });
  }

  const doc = snap.docs[0];
  const data = doc.data();

  // 2. Check expiry
  if (data.expiresAt.toDate() < new Date()) {
    return res.status(400).json({ success: false, message: "Token expired." });
  }

  // 3. Update password in Firebase Auth
  await admin.auth().updateUser(data.userId, { password: newPassword });

  // 4. Invalidate token — mark as used
  await doc.ref.set({ used: true, usedAt: new Date() }, { merge: true });

  return res.status(200).json({ success: true, message: "Password updated." });
});
```

After a successful response the web page shows a success message and links the user back to the app.

---

## Flutter integration

The Flutter app only needs **one call**:

```
ForgotPasswordPage
  └─ enters email → POST /auth/forgot-password/request
     └─ show "Check your email" screen
```

The rest happens in the browser / web page. No OTP input, no token handling in the app.

---

## Environment variable

Add to `functions/.env` / `functions/.env.development`:

```
RESET_PASSWORD_BASE_URL=https://www.coffix.co.nz/reset-password
# dev: http://localhost:3000/reset-password
```

Use it in the handler instead of hardcoding the URL:

```ts
const baseUrl = process.env.RESET_PASSWORD_BASE_URL;
const resetUrl = `${baseUrl}?token=${token}`;
```

---

## Security checklist

- [ ] Rate-limit `/auth/forgot-password/request` (reuse `otpSendLimiter`).
- [ ] Always return `{ success: true }` from the request endpoint regardless of whether the email exists.
- [ ] Token is a 32-byte crypto-random hex string — not guessable.
- [ ] Token expires after 1 hour and is single-use (`used: true` after first reset).
- [ ] Never log the raw `token` value.
- [ ] Enforce `min(8)` on `newPassword` in both schema and Firebase Auth.
- [ ] The web page should validate that both password fields match before submitting.
- [ ] Consider adding CORS restrictions on the reset endpoint to only allow your web domain.
