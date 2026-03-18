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
    storeName: z.string().trim(),
    storeAddress: z.string().trim(),
    items: z.array(
      z.object({
        productId: z.string().trim(),
        productName: z.string().trim(),
        price: z.number().nonnegative(),
        quantity: z.number().positive(),
        selectedModifiers: z.record(z.string(), z.string()),
        modifiers: z.array(z.object({
          modifierId: z.string(),
          name: z.string(),
          priceDelta: z.number(),
        })),
      }),
    ),
    duration: z.number().min(0),
    paymentMethod: z.enum(["coffixCredit", "card"]),
  })
  .strict();

export type CreateOrderBodySchema = z.infer<typeof createOrderBodySchema>;
