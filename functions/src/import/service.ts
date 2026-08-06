import { logger } from "firebase-functions";
import { firestore } from "../config/firebaseAdmin";
import { collectionToCsv, formatBytes } from "../utils/csv";
import { nextSequentialIds } from "../utils/generateId";
import { bucketName, signedDownloadUrl, storageClient } from "../utils/storage";
import {
  CollectionSchema,
  DOC_ID_PROPERTY,
  getImportSchema,
  ID_PREFIXES,
  systemIdField,
  unflattenRow,
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
  created: number;
  updated: number;
  skipped: number;
}

// One row prepared for writing: a target ref plus the payload to set.
interface PreparedWrite {
  ref: FirebaseFirestore.DocumentReference;
  data: Record<string, unknown>;
  merge: boolean;
}

// A validated/coerced row awaiting only its document id.
interface CoercedRow {
  rawId: string;
  merge: boolean;
  data: Record<string, unknown>;
}

// Result of coercing one row: either a coerced row, or an error reason for skipping.
// Kept as a single shape (not a discriminated union) because strictNullChecks is
// off in this project, which disables literal-boolean union narrowing.
interface CoerceRowResult {
  ok: boolean;
  row?: CoercedRow;
  error?: string;
}

export class ImportService {
  /**
   * Validate and coerce CSV rows against the collection's import schema, then
   * upsert the valid ones into Firestore. Rows that fail validation (missing
   * required field, bad type coercion) are skipped; the result reports how many
   * rows were created, updated and skipped, with skip reasons written to the log.
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
    const coercedRows: CoercedRow[] = [];

    for (let i = 0; i < rows.length; i++) {
      const built = this.coerceRow(schema, idField, rows[i]);
      if (built.ok) {
        coercedRows.push(built.row);
      } else {
        skipped.push({ rowIndex: i, reason: built.error });
      }
    }

    const prepared = await this.resolveRefs(collection, coercedRows);

    await this.commitInBatches(prepared);

    // A row carrying a document id upserts (counted as an update); a row without
    // one always inserts a freshly generated id (counted as a create).
    const updated = prepared.filter((p) => p.merge).length;
    const created = prepared.length - updated;

    const requestId = await this.recordRequest(
      collection,
      created,
      updated,
      skipped.length,
    );

    logger.info(
      `[import/import] ${collection}: received ${rows.length}, ` +
        `created ${created}, updated ${updated}, skipped ${skipped.length}`,
    );

    // The response reports counts only, so surface the per-row reasons here.
    if (skipped.length > 0) {
      logger.warn(
        `[import/import] ${collection} skipped rows: ` +
          skipped.map((s) => `row ${s.rowIndex}: ${s.reason}`).join("; "),
      );
    }

    return {
      requestId,
      collection,
      received: rows.length,
      created,
      updated,
      skipped: skipped.length,
    };
  }

  // Validate + coerce a single row's fields, or return an error describing why
  // the row was skipped. Document id resolution happens separately in
  // resolveRefs, since generating a sequential id requires a transaction.
  private coerceRow(
    schema: CollectionSchema,
    idField: string,
    row: Record<string, string>,
  ): CoerceRowResult {
    // Resolve the document id: present in CSV -> upsert; absent -> generate.
    // Falls back to `docId` (DOC_ID_PROPERTY) so CSVs exported/hand-built with
    // that header — rather than the schema's own id field name — still upsert.
    const rawId = (row[idField] || row[DOC_ID_PROPERTY] || "").trim();
    const merge = rawId !== "";

    const candidate = unflattenRow(row, idField);

    const result = schema.shape.safeParse(candidate);
    if (!result.success) {
      const issue = result.error.issues[0];
      const path = issue.path.join(".") || "(row)";
      return { ok: false, error: `${path}: ${issue.message}` };
    }

    const data = result.data as Record<string, unknown>;

    // On upsert, don't re-stamp createdAt — preserve the original.
    if (merge) {
      delete data.createdAt;
      data.updatedAt = new Date();
    }

    return { ok: true, row: { rawId, merge, data } };
  }

  // Resolve each coerced row's document ref: an upsert reuses the CSV-supplied
  // id; a new row gets a prefixed sequential id (see utils/generateId.ts).
  // All rows share one transaction across the whole import so concurrent
  // imports of the same collection don't collide. The counter doc is read
  // once up front and written once at the end (all reads before all writes)
  // rather than per row, since Firestore transactions disallow interleaving
  // reads after writes. Mirrors the resolved id into the body under `docId`.
  private async resolveRefs(
    collection: string,
    rows: CoercedRow[],
  ): Promise<PreparedWrite[]> {
    const prefix = ID_PREFIXES[collection as keyof typeof ID_PREFIXES];
    const numGenerated = rows.filter((r) => !r.merge).length;

    return firestore.runTransaction(async (tx) => {
      let ids: string[] = [];
      let nextCount: number | undefined;
      const counterRef = firestore.collection("counters").doc(collection);

      if (prefix && numGenerated > 0) {
        const snap = await tx.get(counterRef);
        const startCount = (snap.data()?.nextNumber as number | undefined) ?? 1;
        const reserved = nextSequentialIds(startCount, numGenerated, prefix);
        ids = reserved.ids;
        nextCount = reserved.nextCount;
      }

      const prepared: PreparedWrite[] = [];
      let idIndex = 0;
      for (const { rawId, merge, data } of rows) {
        let ref: FirebaseFirestore.DocumentReference;
        if (merge) {
          ref = firestore.collection(collection).doc(rawId);
        } else if (prefix) {
          ref = firestore.collection(collection).doc(ids[idIndex++]);
        } else {
          ref = firestore.collection(collection).doc();
        }
        data[DOC_ID_PROPERTY] = ref.id;
        prepared.push({ ref, data, merge });
      }

      if (nextCount !== undefined) {
        tx.set(counterRef, { nextNumber: nextCount }, { merge: true });
      }

      return prepared;
    });
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
    created: number,
    updated: number,
    skipped: number,
  ): Promise<string> {
    const ref = await firestore.collection("requests").add({
      type: "import",
      status: "completed",
      createdAt: new Date(),
      collection,
      created,
      updated,
      skipped,
    });
    return ref.id;
  }
}
