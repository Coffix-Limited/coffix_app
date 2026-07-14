import { z } from "zod";

export const topupBodySchema = z.object({
  amount: z.number().positive(),
});

export const shareCoffixCreditSchema = z.object({
  recipientFirstName: z.string().min(1),
  recipientLastName: z.string().min(1),
  recipientEmail: z.string().email(),
  amount: z.number().positive(),
});

export const addCreditSchema = z.object({
  userIds: z.array(z.string().min(1)).min(1),
  amount: z.number().positive(),
});

export type TopupBodySchema = z.infer<typeof topupBodySchema>;
export type ShareCoffixCreditSchema = z.infer<typeof shareCoffixCreditSchema>;
export type AddCreditSchema = z.infer<typeof addCreditSchema>;
