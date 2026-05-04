import z from "zod";

export const customerHasAccountSchema = z.object({
  email: z.email(),
});

export type CustomerHasAccountSchema = z.infer<typeof customerHasAccountSchema>;

export const forgotPasswordSchema = z.object({
  email: z.email(),
});

export const verifyResetTokenSchema = z.object({
  token: z.string().min(1, "Token is required"),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1, "Token is required"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export type ForgotPasswordSchema = z.infer<typeof forgotPasswordSchema>;
export type VerifyResetTokenSchema = z.infer<typeof verifyResetTokenSchema>;
export type ResetPasswordSchema = z.infer<typeof resetPasswordSchema>;
