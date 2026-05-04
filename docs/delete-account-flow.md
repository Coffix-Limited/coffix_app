# Delete Account – Flow

## Gist

When a user requests account deletion, the account is **soft-deleted**: it is disabled and the email is obfuscated with a deletion timestamp. The customer's data is **retained** in Firestore. The user is logged out and all local data is cleared.

---

## Flow

1. **User taps "Delete"**
   - Confirmation prompt shown (optional but recommended).
   - On confirm, call the `DELETE /auth/account` API endpoint.

2. **Backend – disable account**
   - Set `disabled = true` on the Firebase Auth user (via Admin SDK).

3. **Backend – obfuscate email**
   - Prepend a deletion timestamp (`YYYYMMDDHHmmss-`) to the email local-part.
   - Format: `{YYYYMMDDHHmmss}-{originalEmail}`
   - Example: `xx@yyy.com` → `20261203143321-xx@yyy.com`
   - Update the email in Firebase Auth and in Firestore.

4. **Client – logout & clear local data**
   - Sign out from Firebase Auth.
   - Clear all locally stored data (tokens, preferences, cached user info).
   - Redirect to the auth/login screen.

---

## API

### `DELETE /auth/account`

**Auth:** Bearer token (authenticated user only)

**Request body:** none

**Success response:** `200 OK`
```json
{ "message": "Account deleted successfully." }
```

**Error responses:**

| Status | Reason |
| ------ | ------ |
| 401 | Unauthenticated |
| 500 | Internal server error |

---

## Email Obfuscation Format

```
{YYYYMMDDHHmmss}-{original_email}
```

| Original email | Deletion time | Result |
| -------------- | ------------- | ------ |
| `xx@yyy.com` | 2026-12-03 14:33:21 | `20261203143321-xx@yyy.com` |
| `john@coffee.app` | 2026-05-05 10:00:00 | `20260505100000-john@coffee.app` |

> The timestamp uses the server's UTC time at the moment of deletion.

---

## Data Retention

- Customer data in Firestore is **not deleted**.
- The account is identifiable as deleted via `disabled = true` and the obfuscated email prefix.
- Future re-registration with the same original email is allowed since the old record no longer holds that email address.

---

## Technical Notes

### Backend (`functions/src/auth/`)

- Add a `deleteAccount` handler in `route.ts`.
- Steps:
  1. Verify the caller's Firebase ID token.
  2. Look up the user in Firebase Auth.
  3. Build the obfuscated email: `{timestamp}-{email}`.
  4. Call `admin.auth().updateUser(uid, { disabled: true, email: obfuscatedEmail })`.
  5. Update the Firestore user document with the new email.
  6. Return `200`.

### Flutter client (`features/auth/`)

- After a successful API response:
  1. Call `FirebaseAuth.instance.signOut()`.
  2. Clear all local storage (e.g. `SharedPreferences`, `FlutterSecureStorage`).
  3. Navigate to `/auth` (login screen), clearing the navigation stack.
- Handle errors gracefully — show an error message if the API call fails.

---

## Summary

| Step | Actor | Action |
| ---- | ----- | ------ |
| 1 | Client | User taps "Delete" and confirms |
| 2 | Backend | Disable Firebase Auth account (`disabled = true`) |
| 3 | Backend | Obfuscate email with deletion timestamp |
| 4 | Backend | Update Firestore user document |
| 5 | Client | Sign out, clear local data, redirect to login |
