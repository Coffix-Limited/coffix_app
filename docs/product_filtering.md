# Product Filtering in ProductsPage

Products displayed on the menu are filtered in two sequential steps before being passed to `ProductList`.

## Step 1 — Filter by store availability (`productsByStore`)

**Source:** `lib/core/extensions/product_extensions.dart`

```dart
products.productsByStore(widget.storeId)
```

This calls the `productsByStore` extension on `List<ProductWithCategory>`. It keeps only products whose `availableToStores` list contains the `storeId` passed to `ProductsPage` (i.e. the store the user is currently browsing). If `availableToStores` is null, the product is excluded.

**Firestore field:** `Product.availableToStores: List<String>?`

## Step 2 — Exclude products disabled for the user's preferred store

**Source:** `lib/features/products/presentation/pages/products_page.dart`

```dart
.where(
  (p) => !(p.product.disabledStores?.contains(preferredStoreId) ?? false),
)
```

After the store-availability filter, any product whose `disabledStores` list contains the authenticated user's `preferredStoreId` is removed. If `disabledStores` is null the product is kept (the `?? false` default).

`preferredStoreId` is read from `AuthCubit` state:

```dart
final preferredStoreId = authState.maybeWhen(
  authenticated: (userWithStore) => userWithStore.user.preferredStoreId,
  orElse: () => null,
);
```

If the user is unauthenticated, `preferredStoreId` is `null` and `contains(null)` returns `false`, so no products are hidden by this filter.

**Firestore field:** `Product.disabledStores: List<String>?`

## Filter pipeline summary

```
All products (from ProductCubit)
  │
  ▼
productsByStore(storeId)        — keep only products listed in availableToStores
  │
  ▼
exclude disabledStores          — remove products that list preferredStoreId in disabledStores
  │
  ▼
ProductList (rendered)
```

## Key fields on `Product`

| Field | Type | Purpose |
|---|---|---|
| `availableToStores` | `List<String>?` | Stores where the product is offered |
| `disabledStores` | `List<String>?` | Stores where the product is temporarily hidden |

## Note on `storeId` vs `preferredStoreId`

- `storeId` (widget prop) — the store whose menu is being viewed; used for the availability check.
- `preferredStoreId` (from auth) — the user's saved preferred store; used for the disabled-stores check.

In normal usage both values refer to the same store, but they are sourced independently so either can differ if the user navigates to a store other than their preferred one.
