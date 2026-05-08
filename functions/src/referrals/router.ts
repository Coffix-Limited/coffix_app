import express from "express";
import { z } from "zod";
import { requirePost } from "../middleware/method";
import { AuthenticatedRequest, requiredAuth } from "../middleware/auth";
import { firestore } from "../config/firebaseAdmin";
import { AuthService } from "../auth/service";
import { logger } from "firebase-functions/v1";
import { ReferralService } from "./service";
import { EmailService } from "../email/service";
import { sendReferralSchema } from "./schemas";

const referralsRouter = express.Router();
referralsRouter.use(express.json());



referralsRouter.post(
  "/send",
  requirePost,
  requiredAuth,
  async (request: AuthenticatedRequest, response) => {
    const emailService = new EmailService();
    const validation = sendReferralSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    const uid = request.user!.uid;
    const { recipients } = validation.data;

    try {
      // Check which emails are already registered
      const authService = new AuthService();
      const existenceChecks = await Promise.all(
        recipients.map(async (recipient) => ({
          ...recipient,
          exists: await authService.customerHasAccount({
            email: recipient.email,
          }),
        })),
      );

      const existingEmails = existenceChecks
        .filter((r) => r.exists)
        .map((r) => r.email);

      if (existingEmails.length > 0) {
        return response.status(400).json({
          success: false,
          // message: `The following emails are already registered: ${existingEmails.join(", ")}`,
          message: "Some of the referrals already exist and will not be invited",
        });
      }

      // Check for existing pending referrals for these emails
      const emails = recipients.map((r) => r.email);
      const pendingSnaps = await Promise.all(
        emails.map((email) =>
          firestore
            .collection("referrals")
            .where("referee", "==", email)
            .where("status", "in", ["pending", "active"])
            .limit(1)
            .get(),
        ),
      );

      const alreadyReferredEmails = emails.filter(
        (_, i) => !pendingSnaps[i].empty,
      );

      if (alreadyReferredEmails.length > 0) {
        return response.status(400).json({
          success: false,
          // message: `The following emails already have a pending referral: ${alreadyReferredEmails.join(", ")}`,
          message: "Some of the referrals already exist and will not be invited",
        });
      }

      // Create referral documents and send emails in parallel
      const referralService = new ReferralService();
      await Promise.all(
        existenceChecks.map(async ({ email, name }) => {
          await referralService.createReferral({
            referrerUid: uid,
            referee: { email, name },
          });
          await emailService.sendReferralEmail({
            to: email,
            userId: uid,
            referee_name: name,
          });
        }),
      );

      return response.status(200).json({
        success: true,
        message: "Referral sent",
      });
    } catch (e) {
      logger.error("Error sending referral:", e);
      return response.status(500).json({
        success: false,
        message: "Internal server error",
        error: e,
      });
    }
  },
);

export default referralsRouter;
