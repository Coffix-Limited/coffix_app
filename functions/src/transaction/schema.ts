import { z } from "zod";

export const invoiceTransactionSchema = z.object({
  transactionId: z.string().min(1),
});

export type InvoiceTransactionSchema = z.infer<typeof invoiceTransactionSchema>;

export const reprintTransactionSchema = z.object({
  printerId: z.string().trim().min(1),
  transactionNumber: z.string().trim().min(1),
});

export type ReprintTransactionSchema = z.infer<typeof reprintTransactionSchema>;

export const refundTransactionSchema = z.object({
  transactionNumber: z.string().min(1),
});

export type RefundTransactionSchema = z.infer<typeof refundTransactionSchema>;
