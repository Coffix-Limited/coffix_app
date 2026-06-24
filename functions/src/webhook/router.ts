import express from "express";
import { logger } from "firebase-functions";
import { WebhookService } from "./service";

const router = express.Router();

router.post("/", (request, response) => {
  console.log("[WEBHOOK POST]", new Date().toISOString(), request.body);
  logger.info("Webhook received:", request.body);
  return response.status(200).json({ success: true });
});

router.get("/", async (req, res) => {
  console.log("[WEBHOOK GET]", new Date().toISOString(), req.query);
  logger.info("Webhook received", { query: req.query });

  // Always return 200 — a non-200 response causes Windcave to retry the notification.
  try {
    const sessionId = req.query.sessionId as string | undefined;
    if (!sessionId) {
      logger.warn("Webhook GET called without sessionId");
      return res
        .status(200)
        .json({ success: false, message: "sessionId is required" });
    }

    await new WebhookService().handleWebhook(sessionId);

    return res.status(200).json({ success: true });
  } catch (err) {
    logger.error("Webhook error:", err);
    // Return 200 even on error to prevent Windcave from retrying.
    return res
      .status(200)
      .json({ success: false, message: "Internal server error" });
  }
});

export default router;
