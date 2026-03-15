import { z } from "zod";

export const createTokenBodySchema = z
  .object({
    email: z.string().trim().email(),
    password: z.string().min(6),
  })
  .strict();

export const createOrderBodySchema = z
  .object({
    amount: z.number().positive(),
    customerId: z.string().trim(),
    storeId: z.string().trim(),
    items: z.array(
      z.object({
        productId: z.string().trim(),
        quantity: z.number().positive(),
        selectedModifiers: z.record(z.string(), z.string()),
      }),
    ),
    duration: z.number().min(0),
    paymentMethod: z.enum(["coffixCredit", "card"]),
  })
  .strict();

export type CreateOrderBodySchema = z.infer<typeof createOrderBodySchema>;
