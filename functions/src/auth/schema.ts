import z from "zod";

export const customerHasAccountSchema = z.object({
  email: z.email(),
});

export type CustomerHasAccountSchema = z.infer<
  typeof customerHasAccountSchema
>;
