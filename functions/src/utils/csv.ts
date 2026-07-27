// Shared CSV rendering helpers for Firestore collections. Extracted from
// backup/service.ts so both the daily backup and the on-demand export API use a
// single implementation. Produces flattened, spreadsheet-friendly CSV text.

// Render a collection snapshot to a CSV string with a leading `id` column and
// the union of all flattened field keys (sorted) as the remaining columns.
export function collectionToCsv(snap: FirebaseFirestore.QuerySnapshot): string {
  const rows: Record<string, string>[] = [];
  const fieldKeys = new Set<string>();

  for (const doc of snap.docs) {
    const flat: Record<string, string> = {};
    flatten(doc.data(), "", flat);
    for (const k of Object.keys(flat)) fieldKeys.add(k);
    rows.push({ id: doc.id, ...flat });
  }

  const headers = ["id", ...[...fieldKeys].sort()];
  return toCsv(rows, headers);
}

// Flatten a Firestore value into `out` using dotted keys for nested maps.
// Arrays and unrecognized objects are JSON-stringified; Timestamps become ISO
// strings; GeoPoint/DocumentReference become their string form.
export function flatten(
  value: unknown,
  prefix: string,
  out: Record<string, string>,
): void {
  if (value === null || value === undefined) {
    if (prefix) out[prefix] = "";
    return;
  }

  // Firestore Timestamp
  if (
    typeof value === "object" &&
    value !== null &&
    typeof (value as { toDate?: unknown }).toDate === "function"
  ) {
    out[prefix] = (value as { toDate: () => Date }).toDate().toISOString();
    return;
  }

  // GeoPoint
  if (
    typeof value === "object" &&
    value !== null &&
    "latitude" in value &&
    "longitude" in value
  ) {
    const gp = value as { latitude: number; longitude: number };
    out[prefix] = `${gp.latitude},${gp.longitude}`;
    return;
  }

  // DocumentReference
  if (
    typeof value === "object" &&
    value !== null &&
    typeof (value as { path?: unknown }).path === "string" &&
    typeof (value as { id?: unknown }).id === "string"
  ) {
    out[prefix] = (value as { path: string }).path;
    return;
  }

  if (Array.isArray(value)) {
    out[prefix] = JSON.stringify(value);
    return;
  }

  if (typeof value === "object") {
    // Plain map — recurse into dotted keys.
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length === 0) {
      out[prefix] = "{}";
      return;
    }
    for (const [k, v] of entries) {
      flatten(v, prefix ? `${prefix}.${k}` : k, out);
    }
    return;
  }

  // Scalar (string / number / boolean)
  out[prefix] = String(value);
}

// Turn rows into CSV text with the given header order, escaping each cell.
export function toCsv(
  rows: Record<string, string>[],
  headers: string[],
): string {
  const escape = (v: string): string => {
    if (v === "") return "";
    if (/[",\r\n]/.test(v)) return `"${v.replace(/"/g, '""')}"`;
    return v;
  };

  const lines = [headers.map(escape).join(",")];
  for (const row of rows) {
    lines.push(headers.map((h) => escape(row[h] ?? "")).join(","));
  }
  // Trailing newline so the file ends cleanly.
  return lines.join("\r\n") + "\r\n";
}

// Parse CSV text into headers and row objects. Reverses `toCsv`'s quoting
// rules: handles `\r\n` or `\n` line breaks, quoted fields containing commas or
// newlines, and `""` -> `"` un-escaping. All cells are returned as strings;
// type coercion is the caller's responsibility.
export function parseCsv(text: string): {
  headers: string[];
  rows: Record<string, string>[];
} {
  const records = parseCsvRecords(text);
  if (records.length === 0) {
    return { headers: [], rows: [] };
  }

  const headers = records[0];
  const rows: Record<string, string>[] = [];

  for (let i = 1; i < records.length; i++) {
    const cells = records[i];
    // Skip fully blank trailing lines.
    if (cells.length === 1 && cells[0] === "") continue;

    const row: Record<string, string> = {};
    for (let c = 0; c < headers.length; c++) {
      row[headers[c]] = cells[c] ?? "";
    }
    rows.push(row);
  }

  return { headers, rows };
}

// Split CSV text into an array of records, each a list of cell strings. A single
// pass over the characters tracks whether we're inside a quoted field so commas
// and newlines within quotes are preserved.
function parseCsvRecords(text: string): string[][] {
  const records: string[][] = [];
  let record: string[] = [];
  let field = "";
  let inQuotes = false;
  let i = 0;

  while (i < text.length) {
    const ch = text[i];

    if (inQuotes) {
      if (ch === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i += 1;
        continue;
      }
      field += ch;
      i += 1;
      continue;
    }

    if (ch === '"') {
      inQuotes = true;
      i += 1;
      continue;
    }
    if (ch === ",") {
      record.push(field);
      field = "";
      i += 1;
      continue;
    }
    if (ch === "\r") {
      // Handle CRLF and lone CR.
      record.push(field);
      records.push(record);
      record = [];
      field = "";
      i += text[i + 1] === "\n" ? 2 : 1;
      continue;
    }
    if (ch === "\n") {
      record.push(field);
      records.push(record);
      record = [];
      field = "";
      i += 1;
      continue;
    }

    field += ch;
    i += 1;
  }

  // Flush the final field/record if the text didn't end with a newline.
  if (field !== "" || record.length > 0) {
    record.push(field);
    records.push(record);
  }

  return records;
}

// Human-readable byte size, e.g. 48213 -> "47.1 KB".
export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  const units = ["KB", "MB", "GB", "TB"];
  let value = bytes / 1024;
  let i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i += 1;
  }
  return `${value.toFixed(1)} ${units[i]}`;
}
