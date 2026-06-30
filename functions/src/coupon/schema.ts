import { z } from "zod";

export const createCouponSchema = z.object({
  type: z.string().min(1),
  amount: z.number().positive(),
  expiryDate: z.coerce.date(),
  storeId: z.string().min(1).optional(),
  customerEmail: z.array(z.email()).min(1),
  notes: z.string().optional(),
});

export type CreateCouponSchema = z.infer<typeof createCouponSchema>;
