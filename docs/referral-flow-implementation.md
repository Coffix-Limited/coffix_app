# Referral Flow — Implementation Reference

How the referral system works end-to-end, from sending an invite to issuing coupons, including the placeholder customer pattern introduced to track invited-but-not-yet-signed-up users.

---

## Collections Involved

| Collection    | Role                                                        |
| ------------- | ----------------------------------------------------------- |
| `referrals`   | One document per referral invite                            |
| `customers`   | One document per user — real accounts and `"invited"` placeholders |
| `coupons`     | Reward coupons created when the referee completes a top-up  |
| `transactions`| Top-up records used to detect the referee's first purchase  |
| `global`      | Config values: `referralExpiryDays`, `couponDefaultAmount`, `couponExpiryDays` |

---

## Phase 1 — Sending the Invite

**Endpoint:** `POST /referrals/send`
**File:** `functions/src/referrals/router.ts`

### Validation (in order)

1. Zod schema check on the request body (`sendReferralSchema`).
2. For each recipient email — `AuthService.customerHasAccount()` checks **Firebase Auth** (not Firestore). If the email already has a Firebase Auth account → reject the entire request.
3. Query `referrals` for any document where `referee == email` and `status in ["pending", "active"]` → if found, reject (prevents duplicate invites).

### On Success

`ReferralService.createReferral()` is called for each recipient. It performs a **single Firestore batch** that writes two documents atomically:

**`referrals/{autoId}`**

```
docId          auto-generated
referrer       uid of the authenticated referrer
referee        referee email (lowercased)
refereeUid     null
signupTime     null
referralTime   now
validTime      now + referralExpiryDays (default 7 days)
couponId       null
refereeCouponId null
status         "pending"
```

**`customers/{autoId}`** ← placeholder doc

```
docId          auto-generated (NOT a Firebase Auth UID)
email          referee email (lowercased)
name           name entered by referrer
status         "invited"
invitedAt      now
referrerUid    uid of the referrer
createdAt      now
creditAvailable 0
```

The `status: "invited"` field distinguishes placeholder docs from real customer accounts. All existing queries in the app use `customerId` (Firebase Auth UID) as the doc ID, so placeholder docs are invisible to them.

A referral email is then sent to the referee via `EmailService.sendReferralEmail()`.

---

## Phase 2 — Referee Signs Up

The referee downloads the app and creates an account (email/password, Google, or Apple).

**File:** `lib/features/auth/data/auth_repository_impl.dart`

1. Firebase Auth creates the user and returns a UID.
2. `createUserDoc(uid, email)` is called — writes `customers/{uid}` with `{ docId, email, createdAt, qrId }` if it does not already exist.
   - The placeholder doc lives at `customers/{randomId}`, so `customers/{uid}` will never exist before this point.
3. Writing `customers/{uid}` fires the Firestore trigger `onCustomerCreated`.

**File:** `functions/src/triggers/onCustomerCreated.ts`

The trigger receives the new document's data. It first checks `data.status === "invited"` — if true, it returns immediately. This guard prevents the placeholder doc's own creation from triggering referral activation with a random non-UID doc ID.

For a real sign-up (`status` is not `"invited"`), it calls `ReferralService.activateReferral(uid, email)`.

---

## Phase 3 — Activating the Referral + Migrating the Placeholder

**File:** `functions/src/referrals/service.ts` — `activateReferral()`

1. Query `referrals` for `referee == email` and `status == "pending"`.
2. If not found → return (no referral for this user, nothing to do).
3. Check `signupTime > validTime` — if expired:
   - Update referral to `status: "expired"`.
   - Still call `migratePlaceholderCustomer()` to clean up the placeholder doc.
   - Return.
4. If valid — build a **Firestore batch** that:
   - Updates the referral: `{ refereeUid, signupTime, status: "active" }`.
   - Calls `migratePlaceholderCustomer(uid, email, batch)` to merge and delete the placeholder within the same batch.
   - Commits the batch atomically.

### `migratePlaceholderCustomer(uid, email, batch?)`

1. Query `customers` where `email == email` and `status == "invited"`.
2. If not found → return (user signed up without a referral, nothing to migrate).
3. Strip `status` and `docId` from the placeholder's fields.
4. `batch.set(customers/{uid}, { ...remainingFields, docId: uid }, { merge: true })` — merges placeholder data (e.g. `name`, `invitedAt`, `referrerUid`) into the real customer doc without overwriting fields Dart already wrote (`createdAt`, `qrId`, etc.).
5. `batch.delete(placeholder doc)` — removes the placeholder.

After this phase the `customers` collection has no placeholder for this email. The referral doc has `status: "active"` and `refereeUid` set to the real Firebase Auth UID.

---

## Phase 4 — First Top-Up → Coupon Reward

**File:** `functions/src/referrals/service.ts` — `handleFirstPurchase()`

Called from the Windcave webhook handler when a top-up transaction is approved.

1. Query `referrals` for `refereeUid == customerId` and `status == "active"`.
2. If not found → return.
3. Query `transactions` for `customerId == customerId`, `type == "topup"`, `status == "approved"`, limit 2. If more than 1 result → this is not the first top-up, return.
4. Read `couponDefaultAmount` (default `$5`) and `couponExpiryDays` (default 30) from `global`.
5. Generate two unique coupon codes via `generateUniqueCode()`.
6. **Single Firestore batch** that:
   - Creates `coupons/{referrerCouponId}` with `userIds: [referrerUid]`.
   - Creates `coupons/{refereeCouponId}` with `userIds: [refereeUid]`.
   - Updates referral: `{ status: "rewarded", couponId, refereeCouponId }`.

Both coupons are `type: "fixed"`, `amount: couponDefaultAmount`, `usageLimit: 1`, `source: "referral"`, and expire `couponExpiryDays` days from issuance.

---

## Full Sequence Diagram

```
Referrer                  Backend                          Referee
   │                         │                               │
   │── POST /referrals/send ─►│                               │
   │                         │ validate (Firebase Auth check) │
   │                         │ validate (no pending referral) │
   │                         │                               │
   │                         │── batch.set(referrals/{id}) ──►│ (Firestore)
   │                         │── batch.set(customers/{id},    │
   │                         │            status:"invited") ──►│ (Firestore)
   │                         │── sendReferralEmail() ─────────►│ (email)
   │◄── 200 Referral sent ───│                               │
   │                         │                               │
   │                         │                    signs up ──►│
   │                         │                               │── createUserDoc(uid) ──► customers/{uid} (Firestore)
   │                         │◄── onCustomerCreated trigger ──────────────────────────┘
   │                         │ (status != "invited" → proceed)│
   │                         │── activateReferral(uid, email) │
   │                         │   query referrals by email     │
   │                         │   batch: update referral       │
   │                         │   batch: migrate placeholder   │
   │                         │         → set customers/{uid}  │
   │                         │         → delete customers/{old}│
   │                         │   batch.commit()               │
   │                         │                               │
   │                         │              (referee tops up)─►│
   │                         │◄── webhook: topup approved ─────┘
   │                         │── handleFirstPurchase()        │
   │                         │   batch: coupons/{referrer}    │
   │                         │   batch: coupons/{referee}     │
   │                         │   batch: referral → "rewarded" │
   │                         │   batch.commit()               │
```

---

## Referral Status Lifecycle

| Status      | Set when                                                         |
| ----------- | ---------------------------------------------------------------- |
| `"pending"` | Referral created; referee has not signed up yet                  |
| `"active"`  | Referee signed up within the validity window                     |
| `"expired"` | Referee signed up after `validTime`, or never signed up          |
| `"rewarded"`| Referee completed their first top-up; coupons issued to both    |
| `"invalid"` | Reserved for fraud/self-referral detection (not yet automated)  |

---

## Customer Document — `"invited"` Placeholder

Placeholder docs co-exist in the `customers` collection with real accounts. They are distinguishable by `status: "invited"`.

**When created:** at referral send time, batched with the referral doc.

**When deleted:** when the referee signs up and `migratePlaceholderCustomer` runs. Fields (`name`, `invitedAt`, `referrerUid`, `creditAvailable`) are merged into the real `customers/{uid}` doc before deletion.

**If the referee never signs up:** the placeholder persists indefinitely. Admin UIs should filter by `status != "invited"` to exclude placeholders from customer counts. A cleanup cron (not yet implemented) could delete placeholders older than `referralExpiryDays`.

---

## Firestore Index Required

`migratePlaceholderCustomer` queries `customers` by `email + status`. The composite index is declared in `firestore.indexes.json`:

```json
{
  "collectionGroup": "customers",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "email", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" }
  ]
}
```

---

## Key Files

| File | Role |
| ---- | ---- |
| `functions/src/referrals/router.ts` | `/referrals/send` endpoint — validation + orchestration |
| `functions/src/referrals/service.ts` | `createReferral`, `activateReferral`, `migratePlaceholderCustomer`, `handleFirstPurchase` |
| `functions/src/triggers/onCustomerCreated.ts` | Firestore trigger — calls `activateReferral` on real sign-ups |
| `functions/src/auth/service.ts` | `customerHasAccount` — checks Firebase Auth for existing email |
| `lib/features/auth/data/auth_repository_impl.dart` | `createUserDoc` — writes `customers/{uid}` after Firebase Auth sign-up |
| `firestore.indexes.json` | Composite index for `customers(email, status)` |
