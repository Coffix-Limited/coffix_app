import { z } from "zod";

export const sendReferralSchema = z.object({
  recipients: z
    .array(
      z.object({
        email: z.email(),
        name: z.string().min(1),
      }),
    )
    .min(1),
});

export type SendReferralSchema = z.infer<typeof sendReferralSchema>;
