import express, { Request, Response } from "express";
import { z } from "zod";
import { requirePost } from "../middleware/method";
import createLogSchema from "./schema";
import { LogService } from "./service";
import { logger } from "firebase-functions";

const router = express.Router();
const logService = new LogService();

router.post(
  "/create",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = createLogSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    // Fire-and-forget: respond immediately and write to Firestore in the
    // background. Logging is high-volume and non-critical, so we don't hold the
    // instance (or block the caller) waiting on the write. Failures are logged.
    logService.log(validation.data).catch((e) => {
      logger.error("[log/create] error:", e);
    });

    return response.status(200).json({ success: true });
  },
);

router.post(
  "/settings/cleanup",
  requirePost,
  async (request: Request, response: Response) => {
    const secret = request.headers["x-cron-secret"];
    if (!secret || secret !== process.env.CRON_SECRET) {
      return response
        .status(401)
        .json({ success: false, message: "Unauthorized" });
    }
    try {
      const result = await logService.cleanupLogs();
      logger.info("[log/cleanup] run:", result);
      return response.status(200).json({ success: true, data: result });
    } catch (e) {
      logger.error("[log/cleanup] error:", e);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

export default router;
