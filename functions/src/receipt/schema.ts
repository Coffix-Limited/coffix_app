import z from "zod";

export const createPrintQueueBodySchema = z.object({
  printerId: z.string().trim(),
  status: z.enum(["pending", "printing", "completed", "failed"]),
  lines: z.array(z.string().trim()),
});

export const createReceiptBodySchema = z.object({
  printerId: z.string().trim(),
  storeName: z.string().trim(),
  storeAddress: z.string().trim(),
  transactionNumber: z.string().trim(),
  orders: z.string().trim(),
  total: z.number().positive(),
  customer: z.string().trim(),
  baristaName: z.string().trim(),
  paymentMethod: z.string().trim(),
  orderTime: z.string().trim(),
  serviceTime: z.string().trim(),
  duration: z.number(),
});

export type CreateReceiptBodySchema = z.infer<typeof createReceiptBodySchema>;

export const createGiftBodySchema = z.object({
  printerId: z.string().trim(),
  storeInvoiceText: z.string().trim(),
  transactionNumber: z.string().trim(),
  recipientFullName: z.string().trim(),
  amount: z.number().positive(),
  orderTime: z.string().trim(),
});

export type CreateGiftBodySchema = z.infer<typeof createGiftBodySchema>;
