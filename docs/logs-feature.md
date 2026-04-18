# Logs Feature

## Overview

The logs feature records customer activity across the app for auditing, debugging, and support purposes. Logs are stored in Firestore under a `logs` collection and are categorized by **severity level** and **category**.

---

## Log Model

```dart
class Log {
  final String? docId;
  final String? page;
  final String? customerId;
  final String? category;      // refund, purchase, referral, info update, bonus
  final String? severityLevel; // major, minor, info
  final String? action;
  final String? notes;
  final DateTime? time;
}
```

---

## Severity Levels

### `major`

High-impact events that affect the customer's balance, order state, or account integrity. These should always be logged and may trigger alerts or manual review.

**Use for:**
- Successful or failed payments / top-ups
- Order placements and cancellations
- Refunds issued
- Account suspension or flagging
- Referral bonus awarded

**Example:**
```dart
Log(
  customerId: uid,
  page: 'checkout',
  category: 'purchase',
  severityLevel: 'major',
  action: 'order_placed',
  notes: 'Order #1234 placed for \$12.50',
  time: DateTime.now(),
)
```

---

### `minor`

Mid-impact events that change app state but are not financially critical. Useful for tracing user journeys and diagnosing unexpected behaviour.

**Use for:**
- Cart modifications (item added/removed)
- Modifier selections
- Coupon or voucher applied
- Referral code submitted
- Store selection changed

**Example:**
```dart
Log(
  customerId: uid,
  page: 'cart',
  category: 'purchase',
  severityLevel: 'minor',
  action: 'item_added',
  notes: 'Flat White x1 added to cart',
  time: DateTime.now(),
)
```

---

### `info`

Low-impact informational events. Used for general activity tracking, profile changes, and non-critical user interactions.

**Use for:**
- Profile updates (name, email, phone)
- Login / logout events
- Notification preferences changed
- App navigation milestones (e.g. onboarding completed)
- Referral link viewed

**Example:**
```dart
Log(
  customerId: uid,
  page: 'profile',
  category: 'info update',
  severityLevel: 'info',
  action: 'profile_updated',
  notes: 'Customer updated display name',
  time: DateTime.now(),
)
```

---

## Categories

| Category      | Description                                      |
|---------------|--------------------------------------------------|
| `purchase`    | Order placements, cart events                    |
| `refund`      | Refund requests and completions                  |
| `referral`    | Referral code use, Coffee on Us rewards          |
| `bonus`       | Loyalty points, promotional credits              |
| `info update` | Profile or account setting changes               |
| `top_up`      | Coffix Credit top-up events                      |

---

## Firestore Structure

```
logs/
  {docId}/
    customerId: string
    page: string
    category: string
    severityLevel: "major" | "minor" | "info"
    action: string
    notes: string
    time: timestamp
```

---

## Guidelines

- Always include `customerId`, `severityLevel`, `category`, and `action` — `notes` should add human-readable context.
- Use `major` sparingly; every `major` log should represent a point-of-no-return action.
- `page` should match the GoRouter route name or widget name where the action occurred.
- Logs are append-only — never update or delete existing log documents.

---

## Implementation Checklist

Track which events have been wired up to the log repository. Check off each item once the `Log` write is in place.

### Auth

- [ ] **major** — Account created (email/password, Google, Apple)
- [ ] **major** — Login successful (email/password, Google, Apple)
- [ ] **major** — Login failed (invalid credential, disabled account)
- [ ] **info** — OTP / email verification sent
- [ ] **info** — Email verified successfully
- [ ] **major** — Password reset email requested
- [ ] **major** — Account deleted
- [ ] **info** — Logout

---

### App Start & Session

- [ ] **info** — App opened (cold start)
- [ ] **info** — FCM token refreshed / updated
- [ ] **info** — User session restored on app resume

---

### Home

- [ ] **info** — Home page viewed
- [ ] **info** — Store selected / changed

---

### Menu & Products

- [ ] **info** — Menu page viewed
- [ ] **info** — Product detail opened
- [ ] **minor** — Modifier customisation started (`customize_product_page`)
- [ ] **minor** — Modifier option selected / changed

---

### Cart

- [ ] **minor** — Item added to cart
- [ ] **minor** — Item removed from cart
- [ ] **minor** — Item quantity changed
- [ ] **minor** — Cart cleared
- [ ] **info** — Cart page viewed

---

### Drafts

- [ ] **minor** — Draft saved from cart
- [ ] **minor** — Draft loaded into cart
- [ ] **minor** — Draft deleted

---

### Order & Scheduling

- [ ] **major** — Order placed (scheduled or ASAP)
- [ ] **major** — Order cancelled
- [ ] **info** — Schedule order page viewed
- [ ] **info** — Order receipt email sent

---

### Payment

- [ ] **major** — Payment initiated (Windcave / Coffix Credit)
- [ ] **major** — Payment successful
- [ ] **major** — Payment failed
- [ ] **major** — Payment webhook received (server-side)
- [ ] **info** — Payment options page viewed

---

### Coffix Credit (Top-Up)

- [ ] **major** — Top-up initiated
- [ ] **major** — Top-up successful
- [ ] **major** — Top-up failed
- [ ] **info** — Credit page viewed
- [ ] **info** — Credit history viewed

---

### Share Credit (Gift)

- [ ] **major** — Gift credit sent successfully
- [ ] **major** — Gift credit send failed (insufficient balance, invalid recipient)
- [ ] **info** — Share your balance page viewed

---

### Referral / Coffee on Us

- [ ] **major** — Referral code submitted
- [ ] **major** — Referral bonus awarded to referrer
- [ ] **major** — Coffee on Us reward redeemed
- [ ] **info** — Referral page viewed
- [ ] **info** — Coffee on Us page viewed

---

### Profile

- [ ] **info** — Profile page viewed
- [ ] **info** — Personal info updated (name, phone)
- [ ] **info** — QR ID page viewed
- [ ] **info** — About page viewed
- [ ] **info** — Special URL page viewed / actioned
- [ ] **info** — Coffee for home page viewed

---

### Stores

- [ ] **info** — Stores page viewed
- [ ] **info** — Store selected

---

### Transactions

- [ ] **info** — Transaction history page viewed
- [ ] **info** — Transaction detail expanded
