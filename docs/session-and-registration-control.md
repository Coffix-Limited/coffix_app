# Session & Registration Control

## Overview

This document describes three related behaviours that control how customers are identified, when they must re-authenticate, and which email addresses may create new accounts.

| Behaviour | Trigger | Outcome |
|---|---|---|
| **lastLogin tracking** | Every successful login | `customers.lastLogin` is updated in Firestore |
| **Forced re-login** | App open / auth state resolved | User is signed out if `now − lastLogin > maxDayBetweenLogin` |
| **Disabled-email block** | Registration attempt | Registration is rejected if `customers.disabled == true` for that email |

---

## Data Model

### `customers/{uid}` (Firestore)

| Field | Type | Description |
|---|---|---|
| `lastLogin` | Timestamp | Set on every successful login across all auth methods |
| `disabled` | bool | `true` when an account has been soft-deleted; also blocks re-registration |

### `global/{id}` (Firestore)

| Field | Type | Description |
|---|---|---|
| `maxDayBetweenLogin` | number | Days of inactivity before forced re-login. Absent or `null` means no enforcement. |

---

## 1. User Identity via Local Storage

Firebase Auth already persists the session token on-device; the user remains signed in across cold starts without extra work. However, if the product requires identifying the user (e.g. to pre-fill a login screen or track identity before the auth token resolves), store the Firebase UID locally:

```dart
// After successful login
await prefs.setString('uid', credential.user!.uid);

// On cold start — read before Firebase Auth resolves
final cachedUid = prefs.getString('uid');

// On sign-out — clear it
await prefs.remove('uid');
```

Use `SharedPreferences` for non-sensitive data or `FlutterSecureStorage` if the UID needs to be protected at rest.

---

## 2. lastLogin Update (already implemented)

Every successful authentication triggers `AuthCubit.getUserWithStore()`, which immediately calls `updateLastLogin()`:

```
AuthStateChange (Firebase Auth)
  └── AuthCubit.listenToUser()
        └── AuthCubit.getUserWithStore()
              └── AuthRepositoryImpl.updateLastLogin()   ← writes to Firestore
                    { lastLogin: now(), appVersion: "x.y.z+n" }
```

Relevant files:
- `lib/features/auth/logic/auth_cubit.dart:133–153`
- `lib/features/auth/data/auth_repository_impl.dart:317–328`

No changes are required for this behaviour — it already works for email/password, Google, and Apple sign-in.

---

## 3. Forced Re-Login after `maxDayBetweenLogin`

### Where to enforce

`AuthCubit.getUserWithStore()` — after the user and global config are loaded, before emitting `AuthState.authenticated`.

### Logic

```dart
// Inside getUserWithStore(), after receiving AppUserWithStore from the stream:

final lastLogin = user.user.lastLogin;
final maxDays = global.maxDayBetweenLogin; // from AppGlobal, already fetched

if (lastLogin != null && maxDays != null) {
  final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
  if (daysSinceLogin > maxDays) {
    await _authRepository.signOut();
    emit(AuthState.sessionExpired());
    return;
  }
}
```

### State change required

Add a `sessionExpired` variant to the `AuthState` freezed union (`lib/features/auth/logic/auth_state.dart`):

```dart
factory AuthState.sessionExpired() = _SessionExpired;
```

### Router handling

In `lib/core/routes/app_router.dart`, redirect `sessionExpired` to `/auth` and show a snackbar or banner: _"Your session has expired. Please log in again."_

### Sequence

```
App open → Firebase Auth resolves (user present)
  └── getUserWithStore()
        ├── updateLastLogin()              ← writes new lastLogin
        ├── load AppGlobal.maxDayBetweenLogin
        └── compare lastLogin (pre-update) vs now()
              ├── within limit → emit authenticated
              └── exceeded    → signOut() + emit sessionExpired
```

> Note: `updateLastLogin()` should be called **after** the staleness check so the stale timestamp is what gets compared, not the freshly written one.

---

## 4. Block Registration for Disabled Customers

### Rule

If a `customers` document exists for a given email and its `disabled` field is `true`, the backend must refuse the verification step — preventing re-registration through the app.

This is distinct from account deletion: the `customers` document and the Firebase Auth account are intentionally preserved. Only new signups using that email are blocked.

### Backend — `functions/src/auth/service.ts`

Add a new method to `AuthService`:

```typescript
async customerIsDisabled({ email }: { email: string }): Promise<boolean> {
  const snapshot = await firestore
    .collection("customers")
    .where("email", "==", email.toLowerCase())
    .limit(1)
    .get();
  return !snapshot.empty && snapshot.docs[0].data().disabled === true;
}
```

### Backend — `functions/src/auth/route.ts`

Call `customerIsDisabled` inside `POST /auth/verify`, before the `customerHasAccount` check:

```typescript
const isDisabled = await new AuthService().customerIsDisabled({ email });
if (isDisabled) {
  return response.status(400).json({
    success: false,
    message: "This account has been disabled. Please contact support.",
  });
}
```

### Flutter — `lib/features/auth/data/auth_repository_impl.dart`

`customerHasAccount()` already calls `POST /auth/verify` and throws on non-200 responses. The existing error propagation in `AuthCubit.createOrLoginAccount()` will surface the 400 message to the user — no additional Flutter changes are needed provided the error message from the response body is forwarded to the UI.

### Sequence

```
User enters email on registration screen
  └── AuthCubit.createOrLoginAccount()
        └── AuthRepositoryImpl.customerHasAccount()
              └── POST /auth/verify
                    ├── blackListCustomer()       ← existing check
                    ├── customerIsDisabled()      ← NEW check
                    │     disabled == true → 400 "account disabled"
                    └── customerHasAccount()      ← existing check
```

---

## 5. Admin: Disabling an Email Address

There are two distinct cases depending on whether the person has ever signed up:

| Scenario | Mechanism |
|---|---|
| Email belongs to an existing customer | Set `customers/{uid}.disabled = true` |
| Email has never signed up (pre-emptive block) | Add the email to the `blacklistedEmails` collection |

Both checks already run inside `POST /auth/verify` — no new backend logic is needed for either case.

---

### Case A — Existing customer (has a `customers` document)

#### Firestore Console
1. Open **Firestore Database** → `customers` collection
2. Find the document (filter by `email` field, or open `customers/{uid}` directly)
3. Set `disabled` → `true` (boolean). Add the field if it doesn't exist.

#### Admin SDK script
```typescript
async function disableCustomerByEmail(email: string): Promise<void> {
  const snapshot = await firestore
    .collection("customers")
    .where("email", "==", email.toLowerCase())
    .limit(1)
    .get();

  if (snapshot.empty) {
    console.log(`No customer found for ${email}`);
    return;
  }

  await snapshot.docs[0].ref.update({ disabled: true });
}
```

---

### Case B — Email has never signed up (pre-emptive block)

Use the existing `blacklistedEmails` collection. It is already checked on every `/auth/verify` call in `AuthService.blackListCustomer()` (`functions/src/auth/service.ts:19`), so adding an entry here is enough to block both login and registration attempts.

#### Firestore Console
1. Open **Firestore Database** → `blacklistedEmails` collection
2. Click **Add document** (auto-ID is fine)
3. Add a field: `email` → string → the email address to block (lowercase)
4. Save — the block is active immediately

#### Admin SDK script
```typescript
async function blockEmail(email: string): Promise<void> {
  await firestore.collection("blacklistedEmails").add({
    email: email.toLowerCase(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
```

#### To unblock
Delete the document from `blacklistedEmails`. The email can sign up again on their next attempt.

---

### Option C — Protected HTTP endpoint (recommended for an admin panel)

If you want a UI-driven, auditable admin action, expose a Cloud Function that handles both cases:

```typescript
// functions/src/admin/route.ts
router.post("/block-email", requireAdminAuth, async (req, res) => {
  const { email } = req.body;
  const lower = email.toLowerCase();

  // Check if a customers doc exists — disable it there
  const customerSnap = await firestore
    .collection("customers")
    .where("email", "==", lower)
    .limit(1)
    .get();

  if (!customerSnap.empty) {
    await customerSnap.docs[0].ref.update({ disabled: true });
  }

  // Always add to blacklistedEmails so pre-signup block is also in place
  await firestore.collection("blacklistedEmails").add({
    email: lower,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return res.status(200).json({ success: true });
});
```

Protect this with a `requireAdminAuth` middleware that verifies a custom claim (`admin: true`) on the Firebase ID token.

---

### What each mechanism does and does not do

| Effect | `customers.disabled` | `blacklistedEmails` |
|---|---|---|
| Blocks registration for existing email | Yes | Yes |
| Blocks registration for never-signed-up email | No (no doc exists) | **Yes** |
| Blocks login for existing customer | Yes (checked at sign-in) | Yes (checked at `/auth/verify`) |
| Revokes active sessions | No | No |
| Reversible | Set `disabled: false` | Delete the document |

To also immediately invalidate an active session, revoke the Firebase Auth refresh token:

```typescript
await admin.auth().revokeRefreshTokens(uid);
```

---

## 6. Firestore Configuration

Set `maxDayBetweenLogin` directly in the Firestore console on the `global` document:

```
Collection: global
Document:   <GLOBAL_COLLECTION_ID>
Field:      maxDayBetweenLogin  (Number)
Value:      30   ← days
```

- Set to `30` to force re-login after 30 days of inactivity.
- Remove the field or set it to `null` to disable enforcement entirely.
- Changes take effect immediately on the next app open (the global document is streamed in real-time).

---

## 6. Testing Checklist

### lastLogin
- [ ] Log in with email/password → confirm `customers/{uid}.lastLogin` is updated in Firestore
- [ ] Log in with Google → same check
- [ ] Log in with Apple → same check

### Forced re-login
- [ ] Set `global.maxDayBetweenLogin = 0` in dev Firestore
- [ ] Open the app while already authenticated → user should be signed out immediately with a session-expired message
- [ ] Restore `maxDayBetweenLogin` to a normal value → verify user stays authenticated on next open

### Disabled-email registration block
- [ ] Create (or update) a `customers` doc with `disabled: true` and a known email
- [ ] Attempt to register a new account with that email → expect error "This account has been disabled. Please contact support."
- [ ] Attempt with a non-disabled email → registration proceeds normally
- [ ] Attempt with a blacklisted email → still blocked by the existing blacklist check
