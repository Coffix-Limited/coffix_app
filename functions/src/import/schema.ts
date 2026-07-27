import { z } from "zod";

// Body for POST /import/export — the single collection to export to CSV.
export const exportRequestSchema = z.object({
  collection: z.string().min(1),
});

export type ExportRequest = z.infer<typeof exportRequestSchema>;

// The `collection` text field of the multipart POST /import/import body. The CSV
// itself arrives as the uploaded file, not through zod.
export const importRequestSchema = z.object({
  collection: z.string().min(1),
});

export type ImportRequest = z.infer<typeof importRequestSchema>;
