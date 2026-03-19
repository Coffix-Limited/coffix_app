import z from "zod";

export const sendReceiptBodySchema = z.object({
  orderId: z.string().trim(),
  email: z.email(),
});

export type SendReceiptBodySchema = z.infer<typeof sendReceiptBodySchema>;
