# Invoice Email

## Overview

When a customer requests their order receipt, the `/order/invoice` endpoint builds a self-contained HTML email from the order data and sends it via Resend. Unlike other email types, the invoice does **not** pull its body from the Firestore `emails` collection — the HTML is fully rendered server-side and passed directly to the email sender.

---

## Flow

```
POST /order/invoice  { transactionNumber }
  │
  ├─ 1. Validate transactionNumber (invoiceSchema)
  │
  ├─ 2. Fetch order from Firestore (orders collection, by transactionNumber)
  │
  ├─ 3. Fetch customer from Firestore (customers collection, by uid)
  │
  ├─ 4. Build items HTML  →  buildItemsHtml(order.items)
  │       Each item: productName, price, modifiers[].name
  │
  ├─ 5. Render full HTML  →  orderEmailTemplate
  │       Replace: {{orderNumber}}, {{customerName}}, {{items}},
  │                {{total}}, {{paymentMethod}}, {{createdAt}}, {{serviceTimeLine}}
  │
  └─ 6. emailService.sendInvoice({ invoiceHtml, ... })
          │
          └─ emailService.send({ htmlContent: invoiceHtml, ... })
                │
                └─ POST to Resend API  →  Email delivered
```

The `htmlContent` path in `EmailService.send()` skips the Firestore template lookup entirely and sends the pre-built HTML as-is.

---

## Template

`functions/src/utils/templates/order_email_template.ts`

Receipt-style docket layout. Variables replaced with `.replace()` (not `renderTemplate`) to avoid double-escaping HTML:

| Variable | Value |
|---|---|
| `{{orderNumber}}` | Last 6 chars of `order.orderNumber` |
| `{{customerName}}` | `firstName lastName` or `"Guest"` |
| `{{items}}` | HTML from `buildItemsHtml()` |
| `{{total}}` | `$XX.XX` formatted amount |
| `{{paymentMethod}}` | `"coffixCredit"` or `"card"` |
| `{{createdAt}}` | NZ-formatted order creation time |
| `{{serviceTimeLine}}` | `<p>` tag with scheduled or creation time + store name |

---

## Order Item Schema

Items in Firestore `orders.items` have this shape:

```ts
{
  productId: string;
  productName: string;   // display name shown in the email
  price: number;         // total price for this line (after modifiers)
  quantity: number;
  modifiers: Array<{
    modifierId: string;
    name: string;        // modifier label shown in the email
    priceDelta: number;
  }>;
}
```

`buildItemsHtml` accesses `item.productName` and `modifier.name`.

---

## Key Files

| File | Role |
|---|---|
| `functions/src/order/router.ts` | Endpoint handler, `buildItemsHtml`, template substitution |
| `functions/src/utils/templates/order_email_template.ts` | HTML template string |
| `functions/src/email/service.ts` | `sendInvoice()` + `send()` with `htmlContent` bypass |
| `functions/src/email/schema.ts` | `SendEmailParams` interface (includes `htmlContent?`) |

---

## Testing Locally

```bash
# 1. Start emulator
npm --prefix functions run serve

# 2. Get a Firebase ID token for a test user, then:
curl -X POST http://localhost:5001/<project>/us-central1/api/order/invoice \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"transactionNumber": "<TXN>"}'

# 3. Check the Resend dashboard or your inbox
```

Confirm the email shows item names, modifier labels, and the correct total — not `undefined`.
