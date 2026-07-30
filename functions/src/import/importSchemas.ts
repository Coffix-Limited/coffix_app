// Per-collection field contracts for the CSV import API. The client validates
// columns before uploading; the server re-validates and coerces each row
// defensively.
//
// Each field declares whether it's `required`, its `type` (for coercion), an
// optional `default` (a static value or a factory function invoked at write
// time), and whether it's a `system` field. The single `system` field is the
// Firestore document id: when present in the CSV the row upserts into that
// document; when absent a new id is generated. The id is also mirrored into the
// document body under `docId`.
//
// Any CSV column not declared in `fields` is dropped (not imported).
export type FieldType =
  | "string"
  | "number"
  | "boolean"
  | "email"
  | "timestamp"
  | "array"
  | "map";

export interface FieldDef {
  required?: boolean;
  type?: FieldType; // defaults to "string"
  default?: unknown | (() => unknown); // static value or factory
  system?: boolean; // true = the document id field
}

export interface CollectionSchema {
  fields: Record<string, FieldDef>;
}

// The document-id field name (system) and the body property it's mirrored to.
export const SYSTEM_ID_FIELD = "id";
export const DOC_ID_PROPERTY = "docId";

export const importSchemas: Record<string, CollectionSchema> = {
  campaigns: {
    fields: {
      channels: { required: true },
      createdBy: { required: true, type: "string" },
      name: { required: true, type: "string" },
      "schedule.mode": { required: true, type: "string" },
      status: { required: true, type: "string" },
      "template.body": { required: true, type: "string" },
      "template.title": { required: true, type: "string" },
      "audience.storeIds": { required: false },
      audience: { required: false },
      id: { required: false, system: true },
      createdAt: { default: () => new Date() },
    },
  },
  customers: {
    fields: {
      id: { required: false, system: true },
      allowCoffeeForHome: { required: false, type: "boolean", default: false },
      allowNotifications: { required: false, type: "boolean", default: false },
      allowWinACoffee: { required: false, type: "boolean", default: false },
      allowWithdrawBalance: {
        required: false,
        type: "boolean",
        default: false,
      },
      appVersion: { required: false, type: "string" },
      birthday: { required: false, type: "timestamp" },
      country: { required: false, type: "string" },
      coffixCreditAvailable: { required: false, type: "boolean" },
      createdAt: { default: () => new Date() },
      creditAvailable: { required: false, type: "number", default: 0 },
      creditExpiry: { required: false, type: "timestamp" },
      disabled: { required: false, type: "boolean", default: false },
      email: { required: true, type: "email" },
      emailVerified: { required: false, type: "boolean", default: false },
      fcmToken: { required: false, type: "string" },
      finishedOnboarding: { required: false, type: "boolean", default: false },
      firstName: { required: false, type: "string" },
      getPromotions: { required: false, type: "boolean", default: false },
      getPurchaseInfoByMail: {
        required: false,
        type: "boolean",
        default: false,
      },
      invitedBy: { required: false, type: "timestamp" },
      lastLoginAt: { required: false, type: "timestamp" },
      lastName: { required: false, type: "string" },
      mobileNumber: { required: false, type: "string" },
      name: { required: false, type: "string" },
      nickName: { required: false, type: "string" },
      preferredStore: { required: false, type: "string" },
      qrCode: { required: false, type: "string" },
      referrerUid: { required: false, type: "string" },
      scheduleOrder: { required: false, type: "boolean", default: false },
      shareCredit: { required: false, type: "boolean", default: false },
      status: { required: false, type: "string" },
      suburb: { required: false, type: "string" },
      updatedAt: { default: () => new Date() },
      withdrawBalance: { required: false, type: "boolean", default: false },
    },
  },
  coupons: {
    fields: {
      amount: { required: true, type: "number" },
      customerEmail: { required: true, type: "email" },
      expiryDate: { required: true, type: "timestamp" },
      isUsed: { required: false, type: "boolean", default: false },
      type: { required: true, type: "string" },
      userId: { required: true, type: "string" },
      notes: { required: false, default: "" },
      referralId: { required: false, default: null },
      source: { required: false, default: "manual_import" },
      storeId: { required: false },
      id: { required: false, system: true },
      createdAt: { default: () => new Date() },
    },
  },
  drafts: {
    fields: {
      id: { required: false, system: true },
      "cart.items": { required: true, type: "array" },
      "cart.storeId": { required: true, type: "string" },
      createdAt: { default: () => new Date() },
      updatedAt: { default: () => new Date() },
      userId: { required: true, type: "string" },
    },
  },
  emails: {
    fields: {
      id: { required: false, system: true },
      content: { required: true, type: "string" },
      name: { required: true, type: "string" },
      notes: { required: false, default: "" },
      subject: { required: true, type: "string" },
      updatedAt: { default: () => new Date() },
      variables: { required: false, type: "array" },
    },
  },
  // global: {
  //   fields: {
  //     id: { required: false, system: true },
  //     gst: { required: false, type: "number" },
  //   }
  // },
  modifierGroups: {
    fields: {
      id: { required: false, system: true },
      modifier: { required: false, type: "string" },
      modifierCount: { required: false, type: "array" },
      modifierIds: { required: false, type: "array" },
      name: { required: true, type: "string" },
      required: { required: false, type: "boolean", default: false },
      selectionType: { required: false, type: "string" },
    },
  },
  modifiers: {
    fields: {
      id: { required: false, system: true },
      cost: { required: false, type: "number" },
      groupId: { required: true, type: "string" },
      isDefault: { required: false, type: "boolean", default: false },
      label: { required: true, type: "string" },
      modifierCode: { required: false, type: "string" },
      priceDelta: { required: false, type: "number" },
    },
  },
  orders: {
    fields: {
      id: { required: false, system: true },
      amount: { required: true, type: "number" },
      createdAt: { default: () => new Date() },
      customerEmail: { required: true, type: "email" },
      duration: { required: false, type: "number" },
      items: { required: true, type: "array" },
      orderNumber: { required: true, type: "string" },
      paidAt: { required: false, type: "timestamp" },
      paymentMethod: { required: true, type: "string" },
      scheduleId: { required: false, type: "string" },
      status: { required: true, type: "string" },
      storeAddress: { required: true, type: "string" },
      storeGst: { required: true, type: "number" },
      storeInvoiceText: { required: true, type: "string" },
      storeName: { required: true, type: "string" },
      transactionNumber: { required: false, type: "string" },
      updatedAt: { default: () => new Date() },
    },
  },
  productCategories: {
    fields: {
      id: { required: false, system: true },
      docId: { required: false, type: "string" },
      imageUrl: { required: false, type: "string" },
      name: { required: true, type: "string" },
      order: { required: false, type: "number" },
    },
  },
  products: {
    fields: {
      id: { required: false, system: true },
      availableToStores: { required: false, type: "array" },
      categoryId: { required: true, type: "string" },
      cost: { required: false, type: "number", default: 0 },
      createdAt: { default: () => new Date() },
      disabled: { required: false, type: "boolean", default: false },
      disabledPermanently: { required: false, type: "boolean", default: false },
      disabledStores: { required: false, type: "array" },
      imageUrl: { required: false, type: "string" },
      modifierGroupIds: { required: false, type: "array" },
      name: { required: true, type: "string" },
      order: { required: false, type: "number" },
      price: { required: true, type: "number" },
      updatedAt: { default: () => new Date() },
    },
  },
  stores: {
    fields: {
      id: { required: false, system: true },
      address: { required: true, type: "string" },
      city: { required: true, type: "string" },
      contactName: { required: false, type: "string" },
      disable: { required: false, type: "boolean", default: false },
      email: { required: false, type: "email" },
      gstNumber: { required: false, type: "string" },
      holidayHours: { required: false, type: "array" },
      imageUrl: { required: false, type: "string" },
      invoiceText: { required: false, type: "string" },
      location: { required: false, type: "string" },
      name: { required: true, type: "string" },
      "openingHours.monday.close": { required: false, type: "string" },
      "openingHours.monday.isOpen": {
        required: false,
        type: "boolean",
        default: true,
      },
      "openingHours.monday.open": { required: false, type: "string" },
      "openingHours.tuesday.close": { required: false, type: "string" },
      "openingHours.tuesday.isOpen": {
        required: false,
        type: "boolean",
        default: true,
      },
      "openingHours.tuesday.open": { required: false, type: "string" },
      "openingHours.wednesday.close": { required: false, type: "string" },
      "openingHours.wednesday.isOpen": {
        required: false,
        type: "boolean",
        default: true,
      },
      "openingHours.wednesday.open": { required: false, type: "string" },
      "openingHours.thursday.close": { required: false, type: "string" },
      "openingHours.thursday.isOpen": {
        required: false,
        type: "boolean",
        default: true,
      },
      "openingHours.thursday.open": { required: false, type: "string" },
      "openingHours.friday.close": { required: false, type: "string" },
      "openingHours.friday.isOpen": {
        required: false,
        type: "boolean",
        default: true,
      },
      "openingHours.friday.open": { required: false, type: "string" },
      "openingHours.saturday.close": { required: false, type: "string" },
      "openingHours.saturday.isOpen": {
        required: false,
        type: "boolean",
        default: true,
      },
      "openingHours.saturday.open": { required: false, type: "string" },
      "openingHours.sunday.close": { required: false, type: "string" },
      "openingHours.sunday.isOpen": {
        required: false,
        type: "boolean",
        default: true,
      },
      "openingHours.sunday.open": { required: false, type: "string" },
      printerId: { required: false, type: "string" },
      storeCode: { required: false, type: "string" },
      updatedAt: { default: () => new Date() },
    },
  },
  transactions: {
    fields: {
      id: { required: false, system: true },
      amount: { required: true, type: "number" },
      "card.cardHolderName": { required: false, type: "string" },
      "card.cardNumber": { required: false, type: "string" },
      "card.dateExpiryMonth": { required: false, type: "string" },
      "card.dateExpiryYear": { required: false, type: "string" },
      "card.type": { required: false, type: "string" },
      couponDiscount: { required: false, type: "number" },
      couponIds: { required: false, type: "array" },
      createdAt: { default: () => new Date() },
      customerId: { required: true, type: "string" },
      expiresAt: { required: false, type: "timestamp" },
      gst: { required: false, type: "number", default: 0 },
      gstAmount: { required: false, type: "number", default: 0 },
      gstLabel: { required: false, type: "string" },
      gstNumber: { required: false, type: "string" },
      isManual: { required: false, type: "boolean", default: false },
      notes: { required: false, type: "string", default: "" },
      orderId: { required: false, type: "string" },
      orderNumber: { required: false, type: "string" },
      originalTransactionNumber: { required: false, type: "string" },
      paymentId: { required: false, type: "string" },
      paymentMethod: { required: true, type: "string" },
      paymentTime: { required: false, type: "timestamp" },
      printerId: { required: false, type: "string" },
      recipientCustomerId: { required: false, type: "string" },
      recipientEmail: { required: false, type: "email" },
      recipientFirstName: { required: false, type: "string" },
      recipientLastName: { required: false, type: "string" },
      responseText: { required: false, type: "string" },
      role: { required: false, type: "string" },
      senderEmail: { required: false, type: "email" },
      senderFirstName: { required: false, type: "string" },
      senderFullName: { required: false, type: "string" },
      senderId: { required: false, type: "string" },
      senderLastName: { required: false, type: "string" },
      sessionId: { required: false, type: "string" },
      status: { required: true, type: "string" },
      storeId: { required: false, type: "string" },
      storeInvoiceText: { required: false, type: "string" },
      totalAmount: { required: false, type: "number", default: 0 },
      transactionNumber: { required: true, type: "string" },
      type: { required: false, type: "string" },
      updatedAt: { default: () => new Date() },
    },
  },
};

// Return the schema for a collection, or throw for an unknown/unsupported one so
// arbitrary collections can't be written through the import endpoint.
export function getImportSchema(collection: string): CollectionSchema {
  const schema = importSchemas[collection];
  if (!schema) {
    throw new Error(`Unsupported import collection: ${collection}`);
  }
  return schema;
}

// True if the collection is importable.
export function isImportableCollection(collection: string): boolean {
  return Object.prototype.hasOwnProperty.call(importSchemas, collection);
}

// The name of the system (document id) field for a schema, defaulting to "id".
export function systemIdField(schema: CollectionSchema): string {
  for (const [name, def] of Object.entries(schema.fields)) {
    if (def.system) return name;
  }
  return SYSTEM_ID_FIELD;
}
