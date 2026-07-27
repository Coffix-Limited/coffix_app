import { logger } from "firebase-functions";
import { firestore } from "../config/firebaseAdmin";
import { collectionToCsv, formatBytes } from "../utils/csv";
import { bucketName, signedDownloadUrl, storageClient } from "../utils/storage";
import {
  CollectionSchema,
  DOC_ID_PROPERTY,
  FieldType,
  getImportSchema,
  systemIdField,
} from "./importSchemas";

const FIRESTORE_BATCH_LIMIT = 500;

const EXPORT_FOLDER = "exports";

export interface ExportResult {
  requestId: string;
  storagePath: string;
  link: string;
  sizeBytes: number;
}

export class ExportService {
  // Current NZ date as yyyy-MM-dd (en-CA yields ISO date formatting).
  private nzDateStamp(): string {
    return new Date().toLocaleDateString("en-CA", {
      timeZone: "Pacific/Auckland",
    });
  }

  // Current NZ time as HHmmss (en-GB, 24h) with colons stripped, e.g. "142233".
  // Gives each export its own sub-folder so same-minute runs don't collide.
  private nzTimeStamp(): string {
    return new Date()
      .toLocaleTimeString("en-GB", {
        timeZone: "Pacific/Auckland",
        hour12: false,
      })
      .replace(/:/g, "");
  }

  /**
   * Query one collection, render it to a single CSV, store it in Storage, record
   * the operation in the `requests` collection, and return a 7-day download link.
   */
  async exportCollection(collection: string): Promise<ExportResult> {
    const date = this.nzDateStamp();
    const time = this.nzTimeStamp();

    const snap = await firestore.collection(collection).get();
    if (snap.empty) {
      throw new Error(`Collection ${collection} is empty`);
    }
    const csv = collectionToCsv(snap);

    const storagePath = `${EXPORT_FOLDER}/${date}/${time}/${collection}.csv`;
    const bucket = storageClient().bucket(bucketName());
    await bucket
      .file(storagePath)
      .save(csv, { metadata: { contentType: "text/csv" }, resumable: false });

    const [meta] = await bucket.file(storagePath).getMetadata();
    const sizeBytes = Number(meta.size ?? 0);

    const link = await signedDownloadUrl(storagePath, `${collection}.csv`);

    const requestId = await this.recordRequest(link);

    logger.info(
      `[import/export] ${collection}: ${snap.size} docs -> ${storagePath} (${formatBytes(
        sizeBytes,
      )})`,
    );

    return { requestId, storagePath, link, sizeBytes };
  }

  // Record the completed export in the `requests` collection. Returns the doc id.
  private async recordRequest(link: string): Promise<string> {
    const ref = await firestore.collection("requests").add({
      type: "export",
      status: "completed",
      createdAt: new Date(),
      link,
    });
    return ref.id;
  }
}

export interface SkippedRow {
  rowIndex: number; // 0-based index into the data rows (excludes the header).
  reason: string;
}

export interface ImportResult {
  requestId: string;
  collection: string;
  received: number;
  written: number;
  skipped: SkippedRow[];
}

// One row prepared for writing: a target ref plus the payload to set.
interface PreparedWrite {
  ref: FirebaseFirestore.DocumentReference;
  data: Record<string, unknown>;
  merge: boolean;
}

// Result of preparing one row: either a write, or an error reason for skipping.
// Kept as a single shape (not a discriminated union) because strictNullChecks is
// off in this project, which disables literal-boolean union narrowing.
interface BuildResult {
  ok: boolean;
  write?: PreparedWrite;
  error?: string;
}

export class ImportService {
  /**
   * Validate and coerce CSV rows against the collection's import schema, then
   * upsert the valid ones into Firestore. Rows that fail validation (missing
   * required field, bad type coercion) are skipped and returned with a reason.
   * A row with a non-empty system id (`id`) upserts into that document (merging,
   * preserving the original `createdAt`, stamping `updatedAt`); a row without one
   * inserts a new document with a generated id and schema-defined `createdAt`.
   * The document id is mirrored into the body under `docId`.
   */
  async importRows(
    collection: string,
    rows: Record<string, string>[],
  ): Promise<ImportResult> {
    const schema = getImportSchema(collection);
    const idField = systemIdField(schema);

    const skipped: SkippedRow[] = [];
    const prepared: PreparedWrite[] = [];

    for (let i = 0; i < rows.length; i++) {
      const built = this.buildDoc(collection, schema, idField, rows[i]);
      if (built.ok) {
        prepared.push(built.write);
      } else {
        skipped.push({ rowIndex: i, reason: built.error });
      }
    }

    await this.commitInBatches(prepared);

    const requestId = await this.recordRequest(
      collection,
      prepared.length,
      skipped.length,
    );

    logger.info(
      `[import/import] ${collection}: received ${rows.length}, ` +
        `written ${prepared.length}, skipped ${skipped.length}`,
    );

    return {
      requestId,
      collection,
      received: rows.length,
      written: prepared.length,
      skipped,
    };
  }

  // Validate + coerce a single row into a prepared write, or return an error
  // describing why the row was skipped.
  private buildDoc(
    collection: string,
    schema: CollectionSchema,
    idField: string,
    row: Record<string, string>,
  ): BuildResult {
    // Resolve the document id: present in CSV -> upsert; absent -> generate.
    const rawId = (row[idField] ?? "").trim();
    const merge = rawId !== "";
    const ref = merge
      ? firestore.collection(collection).doc(rawId)
      : firestore.collection(collection).doc();
    const docId = ref.id;

    const data: Record<string, unknown> = {};

    for (const [name, def] of Object.entries(schema.fields)) {
      // The system id field is handled via the ref + docId mirror, not the body.
      if (def.system) continue;
      // On upsert, don't re-stamp createdAt — preserve the original.
      if (name === "createdAt" && merge) continue;

      const raw = row[name];
      const present = raw !== undefined && raw.trim() !== "";

      if (!present) {
        if (def.required) {
          return { ok: false, error: `Missing required field: ${name}` };
        }
        if ("default" in def) {
          setNested(data, name, resolveDefault(def.default));
        }
        // optional + no default -> omit
        continue;
      }

      const coerced = coerceValue(def.type ?? "string", raw);
      if (coerced.ok) {
        setNested(data, name, coerced.value);
      } else {
        return { ok: false, error: `${name}: ${coerced.error}` };
      }
    }

    // Mirror the document id into the body and stamp write metadata.
    data[DOC_ID_PROPERTY] = docId;
    if (merge) {
      data.updatedAt = new Date();
    }

    return { ok: true, write: { ref, data, merge } };
  }

  // Commit prepared writes in chunks that respect the 500-op batch limit.
  private async commitInBatches(prepared: PreparedWrite[]): Promise<void> {
    for (let i = 0; i < prepared.length; i += FIRESTORE_BATCH_LIMIT) {
      const chunk = prepared.slice(i, i + FIRESTORE_BATCH_LIMIT);
      const batch = firestore.batch();
      for (const { ref, data, merge } of chunk) {
        batch.set(ref, data, { merge });
      }
      await batch.commit();
    }
  }

  // Record the completed import in the `requests` collection. Returns the doc id.
  private async recordRequest(
    collection: string,
    written: number,
    skipped: number,
  ): Promise<string> {
    const ref = await firestore.collection("requests").add({
      type: "import",
      status: "completed",
      createdAt: new Date(),
      collection,
      written,
      skipped,
    });
    return ref.id;
  }
}

// Resolve a field default: call it if it's a factory function, else use it as-is
// (null is a valid default and is written).
function resolveDefault(def: unknown): unknown {
  return typeof def === "function" ? (def as () => unknown)() : def;
}

interface CoerceResult {
  ok: boolean;
  value?: unknown;
  error?: string;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Coerce a raw CSV string cell to the target type, or return an error message.
function coerceValue(type: FieldType, raw: string): CoerceResult {
  const value = raw.trim();

  switch (type) {
    case "number": {
      const n = Number(value);
      if (Number.isNaN(n)) {
        return { ok: false, error: `expected number, got "${raw}"` };
      }
      return { ok: true, value: n };
    }
    case "boolean": {
      const v = value.toLowerCase();
      if (["true", "1", "yes"].includes(v)) return { ok: true, value: true };
      if (["false", "0", "no"].includes(v)) return { ok: true, value: false };
      return { ok: false, error: `expected boolean, got "${raw}"` };
    }
    case "email": {
      if (!EMAIL_RE.test(value)) {
        return { ok: false, error: `invalid email "${raw}"` };
      }
      return { ok: true, value };
    }
    case "timestamp": {
      const d = new Date(value);
      if (Number.isNaN(d.getTime())) {
        return { ok: false, error: `invalid timestamp "${raw}"` };
      }
      return { ok: true, value: d };
    }
    // Arrays and maps are exported as JSON (see flatten() in utils/csv.ts), so
    // parse them back strictly — a cell that isn't well-formed JSON of the right
    // shape skips the row rather than writing a wrong-typed value.
    case "array": {
      let parsed: unknown;
      try {
        parsed = JSON.parse(value);
      } catch {
        return { ok: false, error: `expected JSON array, got "${raw}"` };
      }
      if (!Array.isArray(parsed)) {
        return { ok: false, error: `expected JSON array, got "${raw}"` };
      }
      return { ok: true, value: parsed };
    }
    case "map": {
      let parsed: unknown;
      try {
        parsed = JSON.parse(value);
      } catch {
        return { ok: false, error: `expected JSON object, got "${raw}"` };
      }
      if (
        typeof parsed !== "object" ||
        parsed === null ||
        Array.isArray(parsed)
      ) {
        return { ok: false, error: `expected JSON object, got "${raw}"` };
      }
      return { ok: true, value: parsed };
    }
    case "string":
    default:
      return { ok: true, value };
  }
}

// Assign `value` into `target` at a dotted `path`, creating intermediate maps so
// e.g. "template.body" becomes { template: { body: value } }. Reverses the CSV
// export flatten().
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
