# ☕ Coffix App

Mobile coffee ordering and credit-based loyalty application for New Zealand.

---

## 📌 Overview

Coffix App is a Flutter-based mobile application (iOS & Android) that allows customers to:

- Order coffee and food for pickup
- Manage prepaid **Coffix Credit**
- Earn loyalty bonuses
- Send and receive credit (Coffix Gift)
- Refer friends and receive rewards

The backend is powered by **Firebase** and payments are handled via **Windcave (Hosted Payment Page)**.

---

## 🌏 Market & Compliance

- Target Market: New Zealand (English only)
- Currency: NZD ($)
- All prices displayed with **2 decimal places**
- Prices are **GST-inclusive**
- NZ timezone (NZST) enforced
- Compliant with NZ Privacy Act 2020
- No credit card data stored in Firestore

---

# 🏗 Tech Stack

## Frontend

- Flutter (iOS & Android)
- Clean Architecture
- Feature-based modular structure
- Cached Network Images

## Backend

- Firebase Authentication
- Firestore
- Cloud Functions
- Firebase Storage
- Firebase Cloud Messaging (FCM)

## Payments

- Windcave REST API (Hosted Payment Page)
- Server-side session creation via Cloud Functions
- FPRN (Fail Proof Result Notification)
- Optional future support for tokenization

---

# 🚀 Features

---

## 🔐 Authentication & Profile

- Email/password registration
- Email verification (code or link)
- Social login (Google, Apple, Facebook)
- Biometric unlock (FaceID / Fingerprint)
- Password reset
- Re-login required after `maxDayBetweenLogin`

### Account Management

- Update profile (email cannot be changed)
- View Coffix QR ID
- View order history
- View credit & coupons
- Logout (clears local storage)

---

## 🏪 Store & Product Discovery

### Store Locator

- List active stores
- Search by name/address
- Sort by distance
- Display real-time open/closed status (NZ time)

### Product System

- Categories: Coffee, Pastry, Smoothie, Food
- Store-based product filtering
- Product search
- Modifier groups:
  - Size
  - Milk
  - Strength
  - Syrup
  - Temperature
- Real-time price updates
- GST-inclusive pricing

---

## 🛒 Ordering System

### Order Flow

Home → Store → Product → Customization → Cart → Payment → Pickup Time → Confirmation

### Cart Features

- Add/remove items
- Edit items
- Save as Draft (manual only)
- Draft ≠ abandoned cart
- Abandoned carts auto-cleared

### Pickup Scheduling

- Now
- +15 minutes
- +30 minutes
- NZ timezone enforced
- Pickup time printed on docket

---

## 💳 Payment System

### Payment Methods

- Coffix Credit (primary)
- Credit Card (Windcave)
- Apple Pay
- Google Pay

### Payment Flow

1. Cloud Function creates Windcave session
2. Redirect to Hosted Payment Page
3. Windcave redirects back
4. FPRN confirms payment server-side
5. Server recalculates totals
6. Transaction marked as **Paid**

If recalculation differs:

- Client must refresh
- Server values are authoritative

---

## 💰 Coffix Credit & Loyalty

### Credit System

- View credit balance
- View transaction history
- Credit stored in `creditAvailable`
- All calculations server-side only

### Top-Up Bonus (Global Configurable)

- $50+ → 10% bonus
- $250+ → 15% bonus
- $500+ → 20% bonus

Bonus is added as **credit**, not discount per order.

---

### 🎁 Coffix Gift

- Send credit to registered users
- Minimum transfer defined in `Global.nimCreditToShare`
- If recipient registers within 30 days, gift is applied

---

### ☕ Referral (Coffee On Us)

- Send referral email
- Free coffee granted after first purchase
- Reward logic handled server-side

---

## 🔔 Notifications

Managed via separate Web Admin App.

Supports:

- Forced update popup
- Maintenance notices
- Feature announcements
- Targeted push notifications
- Birthday rewards
- Store-based targeting

Geofencing must be framed as a utility feature (e.g., “Notify store I arrived”).

---

## 📦 App Version Control

Two update types:

1. **Minimum Version** – forced update (blocks usage)
2. **Soft Update** – recommended only

Version stored in `Global.appVersion`.

---

# 🗄 Firestore Structure

Main Collections:

- `Global`
- `Stores`
- `ProductCategory`
- `Products`
- `ModifierGroups`
- `Modifiers`
- `Customers`
- `Transactions`
- `Coupons`
- `Emails`
- `Logs`

### Security Rules

- Users can only read/write their own data
- Public collections are read-only
- No client-side credit trust
- All totals recalculated server-side

---

# 🖨 Printing Integration

After successful payment:

- Order written to Firestore
- Printer service listens for new transactions
- Pickup time included
- 15-line formatted docket
- GST breakdown displayed after total

---

# 🔐 Security Model

- Strict Firestore rules
- Financial logic only in Cloud Functions
- No card data stored
- API keys restricted to app SHA-1
- Input sanitization
- Logging based on `debugLevel`
- Backup & recovery enabled

---

# HOW TO BUILD

Android: flutter build apk --flavor dev --target=lib/main_dev.dart
IOS: flutter build ipa --flavor dev --target=lib/main_dev.dart

Android: flutter build appbundle --flavor prod --target=lib/main_prod.dart
IOS: flutter build ipa --flavor prod --target=lib/main_prod.dart

# CHOOSE FIREBASE PROJECTS

firebase projects:list

firebase use dev
firebase use prod

gcloud auth list
