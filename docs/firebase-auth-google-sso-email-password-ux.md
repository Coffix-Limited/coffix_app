# Firebase Auth: Google SSO and Email/Password Same Email UX

## Overview

When a user signs in with Google SSO and later tries to use email/password with the same email address, Firebase Auth behavior depends on whether the login providers are linked to the same Firebase user account.

The recommended product behavior is:

> One email address should map to one user account.  
> Multiple login methods should be linked to the same Firebase UID.

This prevents duplicate accounts, duplicated Firestore records, lost subscriptions, and confusing “where did my data go?” experiences.

---

## Recommended UX Rule

If a user attempts to authenticate with the same email using a different provider, the app should not silently create a separate account.

Instead, the app should:

1. Detect that the email already belongs to an existing account.
2. Ask the user to sign in using their existing method.
3. After successful sign-in, link the new provider to the same Firebase user.
4. Allow the user to sign in using either method going forward.

---

## Case 1: User Signs Up With Google First

Firebase creates a user like:

```txt
email: user@gmail.com
provider: google.com
uid: abc123
```

If the same user later tries to create an email/password account with the same email, Firebase may block duplicate account creation when “one account per email address” is enabled.

Common Firebase error:

```txt
auth/email-already-in-use
```

### Recommended UX Message

```txt
An account already exists with this email. Please continue with Google, then add a password in your account settings.
```

Alternative shorter copy:

```txt
This email is already registered. Please continue with Google.
```

### Recommended Product Behavior

After the user signs in with Google, the app may offer an “Add password” flow from account settings.

Once email/password is linked, both login methods should open the same account using the same Firebase UID.

---

## Case 2: User Signs Up With Email/Password First

Firebase creates a user like:

```txt
email: user@gmail.com
provider: password
uid: abc123
```

If the user later clicks “Continue with Google” using the same email, Firebase may return:

```txt
auth/account-exists-with-different-credential
```

### Recommended UX Message

```txt
You already have an account with this email. Please sign in with your email and password first, then connect Google from your account settings.
```

Alternative shorter copy:

```txt
This email is already registered with email/password. Sign in first to connect Google.
```

### Recommended Product Behavior

The app should ask the user to authenticate with the existing provider first.

After successful sign-in, link the Google credential to the existing Firebase user.

Once linked, both Google SSO and email/password should log the user into the same account.

---

## Expected Final UX After Linking

After provider linking, the user should have one Firebase user account:

```txt
email: user@gmail.com
providers:
  - google.com
  - password
uid: abc123
```

At this point:

- Login with Google should work.
- Login with email/password should work.
- Both methods should return the same Firebase UID.
- User profile, Firestore data, subscriptions, and app state should remain consistent.

---

## UX Anti-Pattern to Avoid

Avoid allowing this state:

```txt
Google account UID: abc123
Password account UID: xyz789
same email: user@gmail.com
```

This creates duplicate user accounts and can cause:

- Duplicate profiles
- Split Firestore data
- Lost or duplicated subscriptions
- Confusing support issues
- Users thinking their data disappeared

---

## Implementation Notes

### Recommended Firebase Setting

Enable:

```txt
One account per email address
```

This setting helps prevent duplicate accounts with the same email.

### Common Errors to Handle

#### `auth/email-already-in-use`

Usually occurs when creating an email/password account for an email that already exists.

Recommended handling:

1. Show the user that the email already exists.
2. Ask them to sign in with the existing provider.
3. Offer account linking after sign-in.

#### `auth/account-exists-with-different-credential`

Usually occurs when signing in with a provider whose email already exists under another provider.

Recommended handling:

1. Store the pending credential temporarily.
2. Ask the user to sign in using the existing provider.
3. Link the pending credential after successful authentication.

---

## Suggested App Flow

### Sign In / Sign Up Flow

```txt
User enters email or clicks Google
        ↓
Firebase checks whether email already exists
        ↓
If same provider:
    Continue normal sign-in
        ↓
If different provider:
    Show account-exists message
        ↓
User signs in with existing provider
        ↓
App links the new provider
        ↓
User can now sign in using either method
```

---

## Product Copy Examples

### Existing Google Account

```txt
This email is already registered with Google. Continue with Google to access your account.
```

### Existing Email/Password Account

```txt
This email is already registered with email and password. Sign in first, then connect Google from your account settings.
```

### Provider Linked Successfully

```txt
Google has been connected to your account. You can now sign in using Google or your email and password.
```

### Add Password After Google Signup

```txt
Add a password to your account so you can also sign in with your email and password.
```

---

## Recommendation

Use one Firebase UID per email address.

Provider linking should be the default behavior whenever a user tries to use another login method with an email that already exists.

This gives users the most predictable experience:

```txt
Same email + different login method = same account after linking
```
