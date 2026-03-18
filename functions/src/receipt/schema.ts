import z from "zod";

export const createPrintQueueBodySchema = z.object({
  printerId: z.string().trim(),
  status: z.enum(["pending", "printing", "completed", "failed"]),
  lines: z.array(z.string().trim()),
});

export const createReceiptBodySchema = z.object({
  storeName: z.string().trim(),
  storeAddress: z.string().trim(),
  orderNumber: z.string().trim(),
  orders: z.string().trim(),
  total: z.number().positive(),
  customer: z.string().trim(),
  baristaName: z.string().trim(),
  duration: z.number(),
});

export type CreateReceiptBodySchema = z.infer<typeof createReceiptBodySchema>;
