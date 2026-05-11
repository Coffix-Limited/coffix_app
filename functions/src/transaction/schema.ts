import { z } from "zod";

export const invoiceTransactionSchema = z.object({
  transactionId: z.string().min(1),
});

export type InvoiceTransactionSchema = z.infer<typeof invoiceTransactionSchema>;
