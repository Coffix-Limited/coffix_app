import express from "express";
import { logger } from "firebase-functions";
import { WebhookService } from "./service";

const router = express.Router();

router.post("/", (request, response) => {
  console.log("[WEBHOOK POST]", new Date().toISOString(), request.body);
  logger.info("Webhook received:", request.body);
  return response.status(200).json({ success: true });
});

// Test route to verify the webhook is working
router.get("/", async (req, res) => {
  try {
    console.log("[WEBHOOK GET]", new Date().toISOString(), req.query);
    logger.info("Webhook received", { query: req.query });

    const sessionId = req.query.sessionId as string | undefined;
    if (!sessionId) {
      return res
        .status(400)
        .json({ success: false, message: "sessionId is required" });
    }

    // Keep webhook fast. Handle quickly + idempotently.
    await new WebhookService().handleWebhook(sessionId);

    return res.status(200).json({ success: true });
    // Optional: return { success:true, data } during testing only
  } catch (err) {
    logger.error("Webhook error:", err);
    // IMPORTANT: if you return non-200, Windcave may retry.
    return res
      .status(500)
      .json({ success: false, message: "Internal server error" });
  }
});

export default router;
