import z from "zod";

export const invoiceSchema = z.object({
  transactionNumber: z.string().trim(),
});

export type InvoiceSchema = z.infer<typeof invoiceSchema>;
