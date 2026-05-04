import express from "express";
import { requirePost } from "../middleware/method";
import {
  customerHasAccountSchema,
  forgotPasswordSchema,
  verifyResetTokenSchema,
  resetPasswordSchema,
} from "./schema";
import { AuthService } from "./service";
import { authLimiter, forgotPasswordLimiter } from "../middleware/rateLimiter";
import { EmailService } from "../email/service";
import { requiredAuth, AuthenticatedRequest } from "../middleware/auth";
import { logger } from "firebase-functions/v1";

const router = express.Router();

router.post("/verify", requirePost, authLimiter, async (request, response) => {
  try {
    const validation = customerHasAccountSchema.safeParse(request.body);

    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    const { email } = validation.data;
    const isBlacklisted = await new AuthService().blackListCustomer({ email });
    if (isBlacklisted) {
      return response.status(400).json({
        success: false,
        message: "Email is blocked. Please contact support.",
      });
    }
    const hasAccount = await new AuthService().customerHasAccount({ email });
    return response.status(200).json({
      success: true,
      data: {
        hasAccount,
      },
    });
  } catch (error) {
    console.error("Error checking if customer has account:", error);
    return response
      .status(500)
      .json({ success: false, message: "Internal server error" });
  }
});

router.post(
  "/forgot-password",
  requirePost,
  forgotPasswordLimiter,
  async (request, response) => {
    try {
      const validation = forgotPasswordSchema.safeParse(request.body);
      if (!validation.success) {
        const errors = validation.error.issues
          .map((i) => `${i.path.join(".")}: ${i.message}`)
          .join(", ");
        return response.status(400).json({ success: false, errors });
      }

      const { email } = validation.data;
      const authService = new AuthService();
      const token = await authService.generateResetToken({ email });

      if (token) {
        const resetUrl = `${process.env.WEB_DASHBOARD_URL}/reset-password?token=${token}`;
        await new EmailService().send({
          email,
          documentId: "FORGOT_PASSWORD",
          variables: { reset_url: resetUrl, email: email },
        });
      }

      return response.status(200).json({
        success: true,
        message: "If that email is registered, a reset link has been sent.",
      });
    } catch (error) {
      console.error("Error in forgot-password:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

router.post(
  "/verify-reset-token",
  requirePost,
  authLimiter,
  async (request, response) => {
    try {
      const validation = verifyResetTokenSchema.safeParse(request.body);
      if (!validation.success) {
        const errors = validation.error.issues
          .map((i) => `${i.path.join(".")}: ${i.message}`)
          .join(", ");
        return response.status(400).json({ success: false, errors });
      }

      const result = await new AuthService().verifyResetToken(
        validation.data.token,
      );

      if (result.valid === false) {
        return response.status(200).json({
          success: true,
          data: { valid: false, reason: result.reason },
        });
      }
      return response
        .status(200)
        .json({ success: true, data: { valid: true } });
    } catch (error) {
      console.error("Error in verify-reset-token:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

router.post(
  "/reset-password",
  requirePost,
  authLimiter,
  async (request, response) => {
    try {
      const validation = resetPasswordSchema.safeParse(request.body);
      if (!validation.success) {
        const errors = validation.error.issues
          .map((i) => `${i.path.join(".")}: ${i.message}`)
          .join(", ");
        const isPasswordError = validation.error.issues.some((i) =>
          i.path.includes("password"),
        );
        return response
          .status(isPasswordError ? 422 : 400)
          .json({ success: false, errors });
      }

      const { token, password } = validation.data;
      const authService = new AuthService();
      const tokenResult = await authService.verifyResetToken(token);

      if (tokenResult.valid === false) {
        const reason = tokenResult.reason;
        const message =
          reason === "expired"
            ? "Reset link has expired. Please request a new one."
            : reason === "used"
              ? "Reset link has already been used."
              : "Invalid reset link.";
        return response.status(400).json({ success: false, message });
      }

      await authService.updatePassword(tokenResult.uid, password);
      await authService.consumeResetToken(tokenResult.docId);

      return response.status(200).json({
        success: true,
        message: "Password updated successfully.",
      });
    } catch (error) {
      console.error("Error in reset-password:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

router.delete(
  "/account",
  requiredAuth,
  async (request: AuthenticatedRequest, response) => {
    try {
      const uid = request.user!.uid;
      await new AuthService().deleteAccount(uid);
      return response
        .status(200)
        .json({ message: "Account deleted successfully." });
    } catch (error) {
      logger.error("Error deleting account:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

export default router;
