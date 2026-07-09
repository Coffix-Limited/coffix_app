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

export const createTransactionSchema = z
  .object({
    userId: z.string().min(1),
    transactionType: z.enum(["order", "gift", "refund"]),
    paymentMethod: z.enum(["coffixCredit", "cash"]),
    amount: z.number().positive(),
    notes: z.string().optional(),
  })
  .refine(
    (d) => !(d.paymentMethod === "cash" && d.transactionType === "gift"),
    {
      message: "cash is not supported for gift",
      path: ["paymentMethod"],
    },
  );

export type CreateTransactionSchema = z.infer<typeof createTransactionSchema>;
