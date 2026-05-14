import express, { Request, Response } from "express";
import { requirePost } from "../middleware/method";
import { requiredAuth, type AuthenticatedRequest } from "../middleware/auth";
import { EmailService } from "./service";
import { sendGiftEmailSchema } from "./schema";
import { logger } from "firebase-functions";

const router = express.Router();
const emailService = new EmailService();

router.post("/gift", requirePost, async (req: Request, res: Response) => {
  const validation = sendGiftEmailSchema.safeParse(req.body);
  if (!validation.success) {
    const errors = validation.error.issues
      .map((i) => `${i.path.join(".")}: ${i.message}`)
      .join(", ");
    return res.status(400).json({ success: false, errors });
  }

  try {
    await emailService.sendGift(validation.data);
    return res.status(200).json({ success: true, message: "Gift email sent" });
  } catch (e: any) {
    return res.status(500).json({
      success: false,
      message: e.message ?? "Failed to send gift email",
    });
  }
});

router.get(
  "/credit-transactions",
  requiredAuth,
  async (request: AuthenticatedRequest, response: Response) => {
    try {
      const customerId = request.user?.uid;
      if (!customerId) {
        return response
          .status(401)
          .json({ success: false, message: "Unauthorized" });
      }

      await emailService.sendCreditTransactions(customerId);

      return response
        .status(200)
        .json({ success: true, message: "Credit transactions email sent" });
    } catch (e: any) {
      logger.error(`Failed to send credit transactions email: ${e.message}`);
      return response.status(500).json({
        success: false,
        message: e.message ?? "Failed to send credit transactions email",
      });
    }
  },
);

export default router;
