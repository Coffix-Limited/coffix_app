import { z } from "zod";

export const topupBodySchema = z.object({
  amount: z.number().positive(),
});

// export const shareCoffixCreditSchema = z.object({
//   name,
// });

export type TopupBodySchema = z.infer<typeof topupBodySchema>;
