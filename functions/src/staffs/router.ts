import express from "express";
import { UserRecord } from "firebase-admin/auth";
import { logger } from "firebase-functions/v1";
import { requirePost } from "../middleware/method";
import { createStaffSchema } from "./schema";
import { StaffService } from "./service";
import { AuthService } from "../auth/service";
import { EmailService } from "../email/service";

const staffsRouter = express.Router();
staffsRouter.use(express.json());

staffsRouter.post("/", requirePost, async (request, response) => {
  const validation = createStaffSchema.safeParse(request.body);
  if (!validation.success) {
    const errors = validation.error.issues
      .map((i) => `${i.path.join(".")}: ${i.message}`)
      .join(", ");
    return response.status(400).json({ success: false, errors });
  }

  const data = validation.data;
  const { email } = data;
  const staffService = new StaffService();

  try {
    // 1. Reject if the email already belongs to an app user (customers).
    if (await staffService.customerExists(email)) {
      return response.status(409).json({
        success: false,
        message: "A user with this email is already registered.",
      });
    }

    // 2. Create the Firebase Auth user (rejects duplicate staff emails too).
    let userRecord: UserRecord;
    try {
      userRecord = await staffService.createStaffAuthUser(email);
    } catch (error: any) {
      if (error.code === "auth/email-already-exists") {
        return response.status(409).json({
          success: false,
          message: "A user with this email is already registered.",
        });
      }
      throw error;
    }

    // 3. Write the staff doc keyed by the Auth UID. Roll back the Auth user if
    // the write fails so we don't leave an orphaned account behind.
    try {
      await staffService.createStaffDoc(userRecord.uid, data);
    } catch (error) {
      await staffService.deleteStaffAuthUser(userRecord.uid);
      throw error;
    }

    // 4. Send a password-setup email, reusing the forgot-password flow: a reset
    // token + link to the web dashboard where the staff sets their password.
    const token = await new AuthService().generateResetToken({ email });
    if (token) {
      const resetUrl = `${process.env.WEB_DASHBOARD_URL}/reset-password?token=${token}`;
      await new EmailService().send({
        email,
        documentId: "FORGOT_PASSWORD",
        variables: { reset_url: resetUrl, email },
      });
    }

    return response
      .status(201)
      .json({ success: true, data: { uid: userRecord.uid } });
  } catch (error) {
    logger.error("Error creating staff:", error);
    return response
      .status(500)
      .json({ success: false, message: "Internal server error" });
  }
});

export default staffsRouter;
