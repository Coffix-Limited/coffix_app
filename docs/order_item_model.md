# Order line items (`Item` / `ItemModifier`)

`Order.items` in `lib/features/order/data/model/order.dart` is a list of **`Item`** objects. Each row is one product line on an order (what was bought, how many, at what unit price, and optional modifier details).

JSON keys match the generated `order.g.dart` serializers (`productId`, `productName`, etc.).

---

## `Item` fields

| Field | Type | Meaning |
|--------|------|---------|
| `productId` | `String?` | Catalog / Firestore id of the product |
| `productName` | `String?` | Display name at time of order |
| `productImageUrl` | `String?` | Image URL for thumbnails in order UI |
| `price` | `double?` | Unit price for this line (before multiplying by quantity in totals logic elsewhere) |
| `quantity` | `int?` | How many of this product |
| `selectedModifiers` | `Map<String, String>?` | Modifier group id → chosen option id (or similar string labels). Handy for quick display without a full modifier list |
| `modifiers` | `List<ItemModifier>?` | Structured list of applied modifiers with optional extra price |

---

## `ItemModifier` fields

| Field | Type | Meaning |
|--------|------|---------|
| `modifierId` | `String?` | Id of the modifier option (or group-specific id, depending on backend) |
| `priceDelta` | `double?` | Extra amount added for that modifier (if stored) |

---

## Example: minimal line item

```json
{
  "productId": "prod_latte_001",
  "productName": "Latte",
  "productImageUrl": "https://example.com/images/latte.png",
  "price": 5.5,
  "quantity": 2
}
```

---

## Example: item with `selectedModifiers` only

Typical shape when the app stores “which option was picked per group” as string ids:

```json
{
  "productId": "prod_latte_001",
  "productName": "Latte",
  "productImageUrl": "https://example.com/images/latte.png",
  "price": 5.5,
  "quantity": 1,
  "selectedModifiers": {
    "size_group": "size_large",
    "milk_group": "oat"
  }
}
```

Keys and values are both strings; meaning of keys is defined by your menu/modifier model.

---

## Example: item with `modifiers` (structured)

```json
{
  "productId": "prod_latte_001",
  "productName": "Latte",
  "productImageUrl": "https://example.com/images/latte.png",
  "price": 5.5,
  "quantity": 1,
  "modifiers": [
    { "modifierId": "size_large", "priceDelta": 0.8 },
    { "modifierId": "oat_milk", "priceDelta": 0.5 }
  ]
}
```

---

## Example: full order snippet with two items

```json
{
  "docId": "order_abc123",
  "items": [
    {
      "productId": "prod_capp_002",
      "productName": "Cappuccino",
      "productImageUrl": "https://example.com/images/cappuccino.png",
      "price": 5.0,
      "quantity": 1,
      "selectedModifiers": { "size_group": "size_regular" },
      "modifiers": [
        { "modifierId": "size_regular", "priceDelta": 0.0 }
      ]
    },
    {
      "productId": "prod_croissant_010",
      "productName": "Butter Croissant",
      "productImageUrl": "https://example.com/images/croissant.png",
      "price": 4.5,
      "quantity": 2
    }
  ]
}
```

---

## Notes

- **`selectedModifiers` vs `modifiers`:** The model allows both. Backend or cart code may populate one or both; UI can prefer human-readable resolution from ids using your menu data.
- **Nullable fields:** Everything on `Item` and `ItemModifier` is optional in the type system; handle missing keys when reading from Firestore or APIs.
- **Source of truth:** Serialization is defined in `order.dart` + generated `order.g.dart`; use `Item.fromJson` / `toJson` for round-trips.
