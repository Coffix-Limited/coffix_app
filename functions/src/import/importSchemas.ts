// Per-collection field contracts for the CSV import API. The client validates
// columns before uploading; the server re-validates and coerces each row
// defensively using Zod.
//
// Each collection is a Zod object schema built from small "csv*" primitives
// below, each of which trims a raw CSV cell string and coerces/validates it to
// the target type. Fields are `.optional()` and/or `.default(...)` to express
// the old required/default semantics. Nested/dotted CSV columns (e.g.
// "openingHours.monday.close") are unflattened into real nested objects by
// `unflattenRow` before validation, so they get a proper shape instead of a
// generic untyped map.
//
// The single system field is the Firestore document id: when present in the
// CSV the row upserts into that document; when absent a new id is generated.
// The id is also mirrored into the document body under `docId`.
//
// Any CSV column not declared in a collection's schema is dropped (not
// imported).
import { z, ZodObject, ZodRawShape } from "zod";

// ---- CSV cell primitives ---------------------------------------------------
// Each accepts a raw (already-trimmed) CSV cell string and coerces/validates
// it, mirroring the previous coerceValue() behavior.


export const csvNumber = z.string().trim().pipe(
  z.coerce.number({ error: "expected a number" }),
);

export const csvBoolean = z
  .string()
  .trim()
  .transform((v, ctx) => {
    const lower = v.toLowerCase();
    if (["true", "1", "yes"].includes(lower)) return true;
    if (["false", "0", "no"].includes(lower)) return false;
    ctx.addIssue({ code: "custom", message: `expected boolean, got "${v}"` });
    return z.NEVER;
  });

export const csvEmail = z.email().trim();

export const csvTimestamp = z
  .string()
  .trim()
  .transform((v, ctx) => {
    const d = new Date(v);
    if (Number.isNaN(d.getTime())) {
      ctx.addIssue({ code: "custom", message: `invalid timestamp "${v}"` });
      return z.NEVER;
    }
    return d;
  });

// Arrays are exported as JSON (see flatten() in utils/csv.ts), so parse them
// back strictly — a cell that isn't well-formed JSON of the right shape fails
// validation rather than writing a wrong-typed value.
export const csvJsonArray = z
  .string()
  .trim()
  .transform((v, ctx) => {
    let parsed: unknown;
    try {
      parsed = JSON.parse(v);
    } catch {
      ctx.addIssue({ code: "custom", message: `expected JSON array, got "${v}"` });
      return z.NEVER;
    }
    if (!Array.isArray(parsed)) {
      ctx.addIssue({ code: "custom", message: `expected JSON array, got "${v}"` });
      return z.NEVER;
    }
    return parsed;
  });

// ---- Schema plumbing --------------------------------------------------------

export interface CollectionSchema {
  // The Zod object schema the unflattened row body is validated/coerced against
  // (excludes the system id field, which is handled out-of-band).
  shape: ZodObject<ZodRawShape>;
  // Name of the system (document id) field, e.g. "id".
  systemIdField: string;
}

// The document-id field name (system) and the body property it's mirrored to.
export const SYSTEM_ID_FIELD = "id";
export const DOC_ID_PROPERTY = "docId";

// Prefixes for human-readable sequential document IDs (see utils/generateId.ts).
// Extend as other collections adopt the helper.
export const ID_PREFIXES = {
  products: "PRD",
  productCategories: "CAT",
  modifierGroups: "MODGRP",
  modifiers: "MOD",
  stores: "STR",
} as const;

// A day's opening-hours block, e.g. "openingHours.monday.{open,close,isOpen}".
const openingHoursDay = z.object({
  open: z.optional(z.string().trim()),
  close: z.optional(z.string().trim()),
  isOpen: z.optional(csvBoolean).default(true),
});

const openingHours = z.object({
  monday: z.optional(openingHoursDay),
  tuesday: z.optional(openingHoursDay),
  wednesday: z.optional(openingHoursDay),
  thursday: z.optional(openingHoursDay),
  friday: z.optional(openingHoursDay),
  saturday: z.optional(openingHoursDay),
  sunday: z.optional(openingHoursDay),
});

// Only catalog-type collections are importable via CSV.
export const importSchemas: Record<string, CollectionSchema> = {
  modifierGroups: {
    systemIdField: SYSTEM_ID_FIELD,
    shape: z.object({
      modifier: z.optional(z.string().trim()),
      modifierCount: z.optional(csvJsonArray),
      modifierIds: z.optional(csvJsonArray),
      name: z.string().trim(),
      required: z.optional(csvBoolean).default(false),
      selectionType: z.optional(z.string().trim()),
    }),
  },
  modifiers: {
    systemIdField: SYSTEM_ID_FIELD,
    shape: z.object({
      cost: z.optional(csvNumber),
      groupId: z.string().trim(),
      isDefault: z.optional(csvBoolean).default(false),
      label: z.string().trim(),
      modifierCode: z.optional(z.string().trim()),
      priceDelta: z.optional(csvNumber),
    }),
  },
  productCategories: {
    systemIdField: SYSTEM_ID_FIELD,
    shape: z.object({
      imageUrl: z.optional(z.string().trim()),
      name: z.string().trim(),
      order: z.optional(csvNumber),
    }),
  },
  products: {
    systemIdField: SYSTEM_ID_FIELD,
    shape: z.object({
      availableToStores: z.optional(csvJsonArray),
      categoryId: z.string().trim(),
      cost: z.optional(csvNumber).default(0),
      createdAt: z.optional(csvTimestamp).default(() => new Date()),
      disabled: z.optional(csvBoolean).default(false),
      disabledPermanently: z.optional(csvBoolean).default(false),
      disabledStores: z.optional(csvJsonArray),
      imageUrl: z.optional(z.string().trim()),
      modifierGroupIds: z.optional(csvJsonArray),
      name: z.string().trim(),
      order: z.optional(csvNumber),
      price: csvNumber,
      updatedAt: z.optional(csvTimestamp).default(() => new Date()),
    }),
  },
  stores: {
    systemIdField: SYSTEM_ID_FIELD,
    shape: z.object({
      address: z.string().trim(),
      city: z.string().trim(),
      contactName: z.optional(z.string().trim()),
      disable: z.optional(csvBoolean).default(false),
      email: z.optional(csvEmail),
      gstNumber: z.optional(z.string().trim()),
      holidayHours: z.optional(csvJsonArray),
      imageUrl: z.optional(z.string().trim()),
      invoiceText: z.optional(z.string().trim()),
      location: z.optional(z.string().trim()),
      name: z.string().trim(),
      openingHours: z.optional(openingHours),
      printerId: z.optional(z.string().trim()),
      storeCode: z.optional(z.string().trim()),
      updatedAt: z.optional(csvTimestamp).default(() => new Date()),
    }),
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
  return schema.systemIdField || SYSTEM_ID_FIELD;
}

// Assign `value` into `target` at a dotted `path`, creating intermediate maps so
// e.g. "template.body" becomes { template: { body: value } }. Reverses the CSV
// export flatten() in utils/csv.ts.
function setNested(
  target: Record<string, unknown>,
  path: string,
  value: unknown,
): void {
  const parts = path.split(".");
  let node = target;
  for (let i = 0; i < parts.length - 1; i++) {
    const key = parts[i];
    if (
      typeof node[key] !== "object" ||
      node[key] === null ||
      Array.isArray(node[key])
    ) {
      node[key] = {};
    }
    node = node[key] as Record<string, unknown>;
  }
  node[parts[parts.length - 1]] = value;
}

// Turn a flat CSV row (dotted keys, string values, possibly the system id
// field) into a nested object ready for Zod validation. Empty-string cells are
// dropped entirely so `.optional()`/`.default()` treat them as absent, not as
// an empty-string value. The system id field and `docId` (its export alias,
// see DOC_ID_PROPERTY) are excluded — both are handled out-of-band via the
// document ref, not part of the body schema.
export function unflattenRow(
  row: Record<string, string>,
  idField: string,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, raw] of Object.entries(row)) {
    if (key === idField || key === DOC_ID_PROPERTY) continue;
    if (raw === undefined || raw.trim() === "") continue;
    setNested(out, key, raw);
  }
  return out;
}
