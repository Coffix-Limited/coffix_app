# Guest Access – Apple Guideline Compliance

## Issue

Apple App Store guideline **3.1.3(b)** (and general review policy) requires that apps not gate features behind registration when those features are not account-dependent. Currently, unauthenticated users are immediately shown `LoginForm` on `HomePage`, blocking access to menu browsing.

---

## Feature Classification

| Feature | Account Required? | Notes |
| --- | --- | --- |
| Browse menu (`MenuPage`) | No | Product catalog is public |
| New Order (place to cart) | No | Cart can exist locally for guests |
| ReOrder | Yes | Requires order history |
| My Drafts | Yes | Drafts are tied to a user record |
| Credit / Coffix Credit | Yes | Financial feature |
| Payment / Checkout | Yes | Requires identity and billing |
| Profile / Settings | Yes | User-specific data |

---

## Proposed Approach

### No new screen — use `MenuPage`

`MenuPage` already handles product browsing. The fix is entirely in how `HomePage` renders for an unauthenticated (guest) user.

### Guest landing state on `HomePage`

Instead of showing `LoginForm` when `AuthState` is `unauthenticated`, show a **guest home view** that:

- Displays the Coffix logo at full opacity (not dimmed)
- Shows a **"Browse Menu"** (or "New Order") button that is **enabled** and navigates to `MenuPage`
- Shows **"Sign In"** and **"Create Account"** CTAs below, so authentication is discoverable but not forced
- Keeps **"ReOrder"** and **"My Drafts"** visible but shows a **login prompt** (bottom sheet or dialog) when a guest taps them, instead of silently disabling them

---

## Changes Required

### 1. `home_page.dart` – `BlocConsumer<AuthCubit>` builder

```dart
// Before
unauthenticated: () => LoginForm(formKey: formKey),

// After
unauthenticated: () => GuestHomeContent(),
```

The `unauthenticated` listener branch that calls `context.goNamed(HomePage.route)` can stay as-is (it handles post-logout redirect).

### 2. New widget – `GuestHomeContent`

Create `lib/features/home/presentation/widgets/guest_home_content.dart`:

- "Browse Menu" button → enabled, calls `context.goNamed(MenuPage.route)`
- "ReOrder" / "My Drafts" buttons → enabled, on tap show a bottom sheet: _"Sign in to access your orders / drafts"_ with Sign In and Create Account actions
- "Sign In" text button and "Create Account" text button → navigate to auth flow (set `AuthState` to trigger `LoginForm`)

### 3. `MenuPage` – guest-safe data loading

Verify `ProductCubit.getProducts()` and `StoreCubit.getStores()` do not require an authenticated Firebase user. If they do, either:

- Allow anonymous Firestore reads (update Firestore rules), or
- Load products/stores without auth when the user is a guest (call in `MenuPage.initState` when unauthenticated, separate from the `authenticated` listener in `HomePage`)

### 4. Cart / checkout gate

When a guest adds an item to the cart and taps **Checkout**, prompt sign-in at that point. Do not block browsing or cart-building.

---

## Routing

No new routes are needed. The existing `MenuPage.route` handles browsing. The existing auth flow handles sign-in.

The `GoRouter` redirect for unauthenticated users **must not** redirect away from `MenuPage`, `CartPage` (read-only browse), or any other guest-accessible route.

Check `lib/core/routes/app_router.dart` and ensure the auth redirect guard only fires for explicitly account-gated routes (e.g. `OrderPage`, `DraftsPage`, `ProfilePage`, `CreditPage`).

---

## UX Summary

| State | Home screen shows |
| --- | --- |
| Guest (unauthenticated) | Logo + "Browse Menu" (enabled) + "ReOrder" / "My Drafts" (tap to prompt sign-in) + Sign In / Create Account CTAs |
| Authenticated, email not verified | `EmailVerificationForm` (unchanged) |
| Authenticated, not onboarded | Redirect to `PersonalInfoPage` (unchanged) |
| Authenticated, fully onboarded | `_HomeContent` welcome + all buttons enabled (unchanged) |

---

## Why Not a New Screen?

`MenuPage` is already the canonical product browser. Creating a separate "guest browse" screen would duplicate UI and split maintenance. The only missing piece is making `MenuPage` reachable without authentication, which is a routing and Firestore rules change — not a new screen.
