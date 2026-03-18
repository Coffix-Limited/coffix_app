import { z } from "zod";

export const createPaymentSessionBodySchema = z.object({
  storeId: z.string().trim(),
  // storeName: z.string().trim(),
  // storeAddress: z.string().trim(),
  duration: z.number(),
  items: z.array(
    z.object({
      productId: z.string().trim(),
      quantity: z.number().positive(),
      selectedModifiers: z.record(z.string(), z.string()),
    }),
  ),
  paymentMethod: z.enum(["coffixCredit", "card"]),
});

// {
//   storeId: "1345 ";
//   scheduledAt: Datetme.now()
//   items: {
//     productId: "1234567890";
//     quantity: 1;
//     selectedModifiers: {
//       "1234567890": "1234567890";
//     };
//   }[];
// }

export type CreatePaymentSessionBodySchema = z.infer<
  typeof createPaymentSessionBodySchema
>;

const linkSchema = z.object({
  href: z.string(),
  rel: z.string(),
  method: z.string(),
});

export const windcaveSessionSchema = z.object({
  id: z.string(),
  state: z.string(),
  links: z.array(linkSchema),
});

export type WindcaveSessionResponse = z.infer<typeof windcaveSessionSchema>;
